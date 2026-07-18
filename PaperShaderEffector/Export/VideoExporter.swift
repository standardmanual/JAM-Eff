import AVFoundation
import Combine
import Metal
import Photos
import UIKit

// MARK: - VideoExporter

@MainActor
final class VideoExporter: ObservableObject {

    @Published var progress: Double = 0
    @Published var isExporting: Bool = false

    private static let fps: Int32          = 30
    private static let durationSeconds: Int32 = 20
    private static let totalFrames: Int    = Int(fps * durationSeconds)

    // MARK: Errors

    enum ExportError: LocalizedError {
        case photoLibraryDenied
        case metalSetupFailed
        case writerSetupFailed
        case pixelBufferPoolUnavailable
        case pixelBufferCreationFailed
        case appendFailed(Int)
        case writerFailed(String)

        var errorDescription: String? {
            switch self {
            case .photoLibraryDenied:         return "사진 라이브러리 접근 권한이 필요합니다."
            case .metalSetupFailed:           return "Metal 초기화에 실패했습니다."
            case .writerSetupFailed:          return "동영상 인코더 설정에 실패했습니다."
            case .pixelBufferPoolUnavailable: return "픽셀 버퍼 풀을 생성하지 못했습니다."
            case .pixelBufferCreationFailed:  return "픽셀 버퍼 생성에 실패했습니다."
            case .appendFailed(let f):        return "프레임 \(f) 인코딩에 실패했습니다."
            case .writerFailed(let m):        return "동영상 저장에 실패했습니다: \(m)"
            }
        }
    }

    // MARK: - Public API

    func export(
        session: EditSession,
        device: MTLDevice,
        pipeline: ShaderPipeline
    ) async throws {
        guard !isExporting else { return }
        isExporting = true
        progress = 0
        defer { isExporting = false }

        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw ExportError.photoLibraryDenied
        }

        let size = session.exportSpec.ratio.pixelSize
        let activeLayers = session.shaderStack.filter { $0.isEnabled }

        // Pre-create canvas-fitted textures for all image layers (must run on main thread)
        var imageTextures: [UUID: MTLTexture] = [:]
        for layer in activeLayers {
            if case .image(let img) = layer.kind {
                if let tex = TextureUtils.canvasTexture(from: img, canvasSize: size, device: device) {
                    imageTextures[layer.id] = tex
                }
            }
        }

        let inputs = RenderInputs(
            layers: activeLayers,
            imageTextures: imageTextures,
            width: Int(size.width),
            height: Int(size.height)
        )

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("shader_export_\(UUID().uuidString).mp4")
        try? FileManager.default.removeItem(at: outputURL)

        try await Self.renderAndEncode(
            inputs: inputs,
            device: device,
            pipeline: pipeline,
            outputURL: outputURL,
            totalFrames: Self.totalFrames,
            fps: Self.fps,
            onProgress: { [weak self] p in self?.updateProgress(p) }
        )

        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputURL)
            }
        } catch {
            try? FileManager.default.removeItem(at: outputURL)
            throw ExportError.writerFailed(error.localizedDescription)
        }

        try? FileManager.default.removeItem(at: outputURL)
        progress = 1.0
    }

    private func updateProgress(_ value: Double) {
        progress = value
    }

    // MARK: - Render + Encode (백그라운드)

    private nonisolated static func renderAndEncode(
        inputs: RenderInputs,
        device: MTLDevice,
        pipeline: ShaderPipeline,
        outputURL: URL,
        totalFrames: Int,
        fps: Int32,
        onProgress: @escaping (Double) async -> Void
    ) async throws {
        let width  = inputs.width
        let height = inputs.height

        guard let commandQueue = device.makeCommandQueue() else {
            throw ExportError.metalSetupFailed
        }
        guard
            let pingTexture    = TextureUtils.makeRenderTarget(width: width, height: height, device: device),
            let pongTexture    = TextureUtils.makeRenderTarget(width: width, height: height, device: device),
            let scratchTexture = TextureUtils.makeRenderTarget(width: width, height: height, device: device),
            let outputTexture  = TextureUtils.makeRenderTarget(width: width, height: height, device: device)
        else {
            throw ExportError.metalSetupFailed
        }

        guard let writer = try? AVAssetWriter(outputURL: outputURL, fileType: .mp4) else {
            throw ExportError.writerSetupFailed
        }
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
        ]
        let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        writerInput.expectsMediaDataInRealTime = false

        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: writerInput,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                kCVPixelBufferWidthKey as String: width,
                kCVPixelBufferHeightKey as String: height,
            ]
        )

        guard writer.canAdd(writerInput) else { throw ExportError.writerSetupFailed }
        writer.add(writerInput)

        guard writer.startWriting() else {
            throw ExportError.writerFailed(writer.error?.localizedDescription ?? "startWriting 실패")
        }
        writer.startSession(atSourceTime: .zero)

        guard let pixelBufferPool = adaptor.pixelBufferPool else {
            writer.cancelWriting()
            throw ExportError.pixelBufferPoolUnavailable
        }

        for frameIndex in 0..<totalFrames {
            if Task.isCancelled {
                writer.cancelWriting()
                try? FileManager.default.removeItem(at: outputURL)
                throw CancellationError()
            }

            while !writerInput.isReadyForMoreMediaData {
                try await Task.sleep(nanoseconds: 5_000_000)
            }

            let time = Float(frameIndex) / Float(fps)

            renderFrame(
                inputs: inputs,
                pipeline: pipeline,
                commandQueue: commandQueue,
                pingTexture: pingTexture,
                pongTexture: pongTexture,
                scratchTexture: scratchTexture,
                outputTexture: outputTexture,
                time: time
            )

            var pixelBuffer: CVPixelBuffer?
            let poolStatus = CVPixelBufferPoolCreatePixelBuffer(nil, pixelBufferPool, &pixelBuffer)
            guard poolStatus == kCVReturnSuccess, let pb = pixelBuffer else {
                writer.cancelWriting()
                throw ExportError.pixelBufferCreationFailed
            }

            CVPixelBufferLockBaseAddress(pb, [])
            if let baseAddress = CVPixelBufferGetBaseAddress(pb) {
                let bytesPerRow = CVPixelBufferGetBytesPerRow(pb)
                outputTexture.getBytes(
                    baseAddress,
                    bytesPerRow: bytesPerRow,
                    from: MTLRegionMake2D(0, 0, width, height),
                    mipmapLevel: 0
                )
            }
            CVPixelBufferUnlockBaseAddress(pb, [])

            let presentationTime = CMTime(value: CMTimeValue(frameIndex), timescale: fps)
            guard adaptor.append(pb, withPresentationTime: presentationTime) else {
                writer.cancelWriting()
                throw ExportError.appendFailed(frameIndex)
            }

            await onProgress(Double(frameIndex + 1) / Double(totalFrames))
        }

        writerInput.markAsFinished()
        await writer.finishWriting()

        if writer.status == .failed {
            throw ExportError.writerFailed(writer.error?.localizedDescription ?? "알 수 없는 오류")
        }
    }

    private nonisolated static func renderFrame(
        inputs: RenderInputs,
        pipeline: ShaderPipeline,
        commandQueue: MTLCommandQueue,
        pingTexture: MTLTexture,
        pongTexture: MTLTexture,
        scratchTexture: MTLTexture,
        outputTexture: MTLTexture,
        time: Float
    ) {
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }

        // Clear ping to dark background
        let rpd = MTLRenderPassDescriptor()
        rpd.colorAttachments[0].texture    = pingTexture
        rpd.colorAttachments[0].loadAction  = .clear
        rpd.colorAttachments[0].clearColor  = MTLClearColorMake(0.1, 0.1, 0.1, 1)
        rpd.colorAttachments[0].storeAction = .store
        commandBuffer.makeRenderCommandEncoder(descriptor: rpd)?.endEncoding()

        var inputTex: MTLTexture = pingTexture
        var altTex: MTLTexture   = pongTexture
        let canvasAspect = Float(inputs.width) / Float(inputs.height)

        for layer in inputs.layers {
            switch layer.kind {
            case .image:
                guard let imageTex = inputs.imageTextures[layer.id] else { continue }
                let t = layer.imageTransform
                let params = OverlayUniforms(
                    scale: t.scale, rotation: t.rotation,
                    offsetX: t.offsetX, offsetY: t.offsetY,
                    opacity: layer.opacity, canvasAspect: canvasAspect,
                    blendMode: layer.blendMode.rawValue
                )
                pipeline.encodeOverlay(
                    background: inputTex, overlay: imageTex,
                    outputTexture: altTex, commandBuffer: commandBuffer, params: params
                )

            case .shader:
                pipeline.encode(
                    layer: layer, inputTexture: inputTex, outputTexture: scratchTexture,
                    commandBuffer: commandBuffer, time: time
                )
                let blendParams = OverlayUniforms(
                    scale: 1.0, rotation: 0, offsetX: 0, offsetY: 0,
                    opacity: layer.opacity, canvasAspect: canvasAspect,
                    blendMode: layer.blendMode.rawValue
                )
                pipeline.encodeOverlay(
                    background: inputTex, overlay: scratchTexture,
                    outputTexture: altTex, commandBuffer: commandBuffer, params: blendParams
                )
            }
            swap(&inputTex, &altTex)
        }

        pipeline.encodePassthrough(
            inputTexture: inputTex,
            outputTexture: outputTexture,
            commandBuffer: commandBuffer
        )

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
}

// MARK: - RenderInputs

private final class RenderInputs: @unchecked Sendable {
    let layers: [ShaderLayer]
    let imageTextures: [UUID: MTLTexture]
    let width: Int
    let height: Int

    init(layers: [ShaderLayer], imageTextures: [UUID: MTLTexture], width: Int, height: Int) {
        self.layers        = layers
        self.imageTextures = imageTextures
        self.width         = width
        self.height        = height
    }
}

import AVFoundation
import Combine
import Metal
import Photos
import UIKit

// MARK: - VideoExporter
//
// 20초(600프레임 @30fps) MP4 동영상을 오프스크린 Metal 렌더링으로 생성한 뒤
// 카메라롤에 저장한다. UI 블로킹을 피하기 위해 프레임 렌더링/인코딩 루프는
// Task.detached(백그라운드)에서 실행하고, 진행률만 메인 액터로 반영한다.

@MainActor
final class VideoExporter: ObservableObject {

    // MARK: Published State
    @Published var progress: Double = 0     // 0.0 ~ 1.0
    @Published var isExporting: Bool = false

    // MARK: Constants
    private static let fps: Int32 = 30
    private static let durationSeconds: Int32 = 20
    private static let totalFrames: Int = Int(fps * durationSeconds)   // 600

    // MARK: Errors
    enum ExportError: LocalizedError {
        case photoLibraryDenied
        case noSourceTexture
        case metalSetupFailed
        case writerSetupFailed
        case pixelBufferPoolUnavailable
        case pixelBufferCreationFailed
        case appendFailed(Int)
        case writerFailed(String)

        var errorDescription: String? {
            switch self {
            case .photoLibraryDenied:        return "사진 라이브러리 접근 권한이 필요합니다."
            case .noSourceTexture:           return "원본 이미지 텍스처가 없습니다."
            case .metalSetupFailed:          return "Metal 초기화에 실패했습니다."
            case .writerSetupFailed:         return "동영상 인코더 설정에 실패했습니다."
            case .pixelBufferPoolUnavailable:return "픽셀 버퍼 풀을 생성하지 못했습니다."
            case .pixelBufferCreationFailed: return "픽셀 버퍼 생성에 실패했습니다."
            case .appendFailed(let f):       return "프레임 \(f) 인코딩에 실패했습니다."
            case .writerFailed(let m):       return "동영상 저장에 실패했습니다: \(m)"
            }
        }
    }

    // MARK: - Public API

    /// 세션을 20초 MP4로 렌더링해 카메라롤에 저장한다.
    /// - Note: 메인 액터에서 호출하되, 무거운 렌더링/인코딩은 내부에서 백그라운드로 오프로드된다.
    func export(
        session: EditSession,
        device: MTLDevice,
        pipeline: ShaderPipeline,
        overlayTransform: PhotoTransform = PhotoTransform(scale: 0.5, rotation: 0, offsetX: 0, offsetY: 0)
    ) async throws {
        guard !isExporting else { return }
        isExporting = true
        progress = 0
        defer { isExporting = false }

        // 1. 사진 권한
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw ExportError.photoLibraryDenied
        }

        // 2. 메인 액터에서 렌더 입력을 스냅샷 (EditSession은 @MainActor)
        // texture는 PreviewZoneView에서 처음 렌더링될 때 생성되므로, nil이면 image에서 직접 생성
        let sourceTexture: MTLTexture
        if let tex = session.sourcePhoto?.texture {
            sourceTexture = tex
        } else if let photo = session.sourcePhoto,
                  let tex = TextureUtils.texture(from: photo.image, device: device) {
            sourceTexture = tex
        } else {
            throw ExportError.noSourceTexture
        }
        let size = session.exportSpec.ratio.pixelSize
        let activeLayers = session.shaderStack.filter { $0.isEnabled }

        // PNG 오버레이 텍스처/파라미터 (있을 경우)
        // 위치/스케일/회전은 overlayTransform(Renderer.overlayTransform)에서 읽어온다.
        var overlayTexture: MTLTexture?
        var overlayParams: OverlayUniforms?
        if let overlay = session.pngOverlay {
            overlayTexture = TextureUtils.texture(from: overlay.image, device: device)
            overlayParams = OverlayUniforms(
                scale:    overlayTransform.scale,
                rotation: overlayTransform.rotation,
                offsetX:  overlayTransform.offsetX,
                offsetY:  overlayTransform.offsetY,
                opacity:  overlay.opacity,
                _pad1: 0, _pad2: 0, _pad3: 0
            )
        }

        let inputs = RenderInputs(
            sourceTexture: sourceTexture,
            layers: activeLayers,
            overlayTexture: overlayTexture,
            overlayParams: overlayParams,
            width: Int(size.width),
            height: Int(size.height)
        )

        // 3. 출력 URL (임시 디렉터리)
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("shader_export_\(UUID().uuidString).mp4")
        try? FileManager.default.removeItem(at: outputURL)

        // 4. 렌더링 + 인코딩
        //    renderAndEncode는 nonisolated static async → 메인 액터 밖(백그라운드 실행자)에서
        //    실행되지만 같은 태스크 트리에 속하므로, dev2가 exportTask.cancel() 하면
        //    루프 내부의 checkCancellation으로 취소가 전파된다.
        try await Self.renderAndEncode(
            inputs: inputs,
            device: device,
            pipeline: pipeline,
            outputURL: outputURL,
            totalFrames: Self.totalFrames,
            fps: Self.fps,
            onProgress: { [weak self] p in
                self?.updateProgress(p)
            }
        )

        // 5. 카메라롤 저장
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputURL)
            }
        } catch {
            try? FileManager.default.removeItem(at: outputURL)
            throw ExportError.writerFailed(error.localizedDescription)
        }

        // 6. 임시 파일 정리
        try? FileManager.default.removeItem(at: outputURL)
        progress = 1.0
    }

    private func updateProgress(_ value: Double) {
        progress = value
    }

    // MARK: - Render + Encode (백그라운드)

    /// AVAssetWriter 파이프라인을 구성하고 600프레임을 순차 렌더링/인코딩한다.
    /// nonisolated — 메인 액터 밖(백그라운드 실행자)에서 실행된다.
    private nonisolated static func renderAndEncode(
        inputs: RenderInputs,
        device: MTLDevice,
        pipeline: ShaderPipeline,
        outputURL: URL,
        totalFrames: Int,
        fps: Int32,
        onProgress: @escaping (Double) async -> Void
    ) async throws {
        let width = inputs.width
        let height = inputs.height

        // --- Metal 커맨드 큐 & 재사용 텍스처 (매 프레임 재할당 금지) ---
        guard let commandQueue = device.makeCommandQueue() else {
            throw ExportError.metalSetupFailed
        }
        guard
            let pingTexture = TextureUtils.makeRenderTarget(width: width, height: height, device: device),
            let pongTexture = TextureUtils.makeRenderTarget(width: width, height: height, device: device),
            let outputTexture = TextureUtils.makeRenderTarget(width: width, height: height, device: device)
        else {
            throw ExportError.metalSetupFailed
        }

        // --- AVAssetWriter 구성 ---
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

        // --- 프레임 루프 ---
        for frameIndex in 0..<totalFrames {
            // 취소 확인 (dev2가 exportTask.cancel() 시)
            if Task.isCancelled {
                writer.cancelWriting()
                try? FileManager.default.removeItem(at: outputURL)
                throw CancellationError()
            }

            // writerInput가 데이터를 받을 준비가 될 때까지 대기 (busy-loop 방지)
            while !writerInput.isReadyForMoreMediaData {
                try await Task.sleep(nanoseconds: 5_000_000)   // 5ms
            }

            let time = Float(frameIndex) / Float(fps)

            renderFrame(
                inputs: inputs,
                pipeline: pipeline,
                commandQueue: commandQueue,
                pingTexture: pingTexture,
                pongTexture: pongTexture,
                outputTexture: outputTexture,
                time: time
            )

            // MTLTexture → CVPixelBuffer
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

        // --- 마무리 ---
        writerInput.markAsFinished()
        await writer.finishWriting()

        if writer.status == .failed {
            throw ExportError.writerFailed(writer.error?.localizedDescription ?? "알 수 없는 오류")
        }
    }

    /// 단일 프레임을 오프스크린 렌더링한다 (ping-pong → outputTexture).
    /// Renderer.draw(in:) 구조를 재사용하되 시간 파라미터를 외부에서 주입한다.
    private nonisolated static func renderFrame(
        inputs: RenderInputs,
        pipeline: ShaderPipeline,
        commandQueue: MTLCommandQueue,
        pingTexture: MTLTexture,
        pongTexture: MTLTexture,
        outputTexture: MTLTexture,
        time: Float
    ) {
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }

        // 쉐이더 스택 ping-pong 렌더링
        let finalTexture: MTLTexture
        if inputs.layers.isEmpty {
            pipeline.encodePassthrough(
                inputTexture: inputs.sourceTexture,
                outputTexture: pingTexture,
                commandBuffer: commandBuffer
            )
            finalTexture = pingTexture
        } else {
            var inputTex: MTLTexture? = inputs.sourceTexture
            var outputTex = pingTexture
            var altTex = pongTexture
            for layer in inputs.layers {
                pipeline.encode(
                    layer: layer,
                    inputTexture: inputTex,
                    outputTexture: outputTex,
                    commandBuffer: commandBuffer,
                    time: time
                )
                inputTex = outputTex
                swap(&outputTex, &altTex)
            }
            finalTexture = inputTex ?? pingTexture
        }

        // PNG 오버레이 합성 or 패스스루로 outputTexture에 기록
        if let overlayTex = inputs.overlayTexture, let params = inputs.overlayParams {
            pipeline.encodeOverlay(
                background: finalTexture,
                overlay: overlayTex,
                outputTexture: outputTexture,
                commandBuffer: commandBuffer,
                params: params
            )
        } else {
            pipeline.encodePassthrough(
                inputTexture: finalTexture,
                outputTexture: outputTexture,
                commandBuffer: commandBuffer
            )
        }

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()   // GPU 완료 후 CPU 복사 보장
    }
}

// MARK: - RenderInputs
//
// 백그라운드 태스크로 넘기는 렌더 입력 스냅샷.
// MTLTexture / ShaderLayer 는 Sendable이 아니지만, 스냅샷 이후 메인 액터에서
// 변형되지 않으므로 @unchecked Sendable로 캡슐화한다.
private final class RenderInputs: @unchecked Sendable {
    let sourceTexture: MTLTexture
    let layers: [ShaderLayer]
    let overlayTexture: MTLTexture?
    let overlayParams: OverlayUniforms?
    let width: Int
    let height: Int

    init(
        sourceTexture: MTLTexture,
        layers: [ShaderLayer],
        overlayTexture: MTLTexture?,
        overlayParams: OverlayUniforms?,
        width: Int,
        height: Int
    ) {
        self.sourceTexture = sourceTexture
        self.layers = layers
        self.overlayTexture = overlayTexture
        self.overlayParams = overlayParams
        self.width = width
        self.height = height
    }
}

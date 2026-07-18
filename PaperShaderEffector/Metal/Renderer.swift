import Metal
import MetalKit
import QuartzCore

// MARK: - GestureLayer

enum GestureLayer {
    case photo    // 소스 사진 레이어에 제스처 적용
    case overlay  // PNG 오버레이 레이어에 제스처 적용
}

// MARK: - Renderer

final class Renderer: NSObject, MTKViewDelegate {

    private(set) var device: MTLDevice
    private(set) var commandQueue: MTLCommandQueue

    // Time (accumulated via CADisplayLink)
    var time: Float = 0
    private var lastTimestamp: CFTimeInterval = 0
    private var displayLink: CADisplayLink?

    // Shared state from EditSession (set from SwiftUI side)
    var shaderStack: [ShaderLayer] = []
    var sourceTexture: MTLTexture?

    // MARK: - 제스처 변환 (Renderer 직접 보관 — SwiftUI 업데이트 우회, 60fps 보장)

    /// 소스 사진 아핀 변환 (핀치/팬/로테이션)
    var photoTransform: PhotoTransform = .identity

    /// PNG 오버레이 아핀 변환 (핀치/팬/로테이션)
    var overlayTransform: PhotoTransform = PhotoTransform(
        scale: 0.5, rotation: 0, offsetX: 0, offsetY: 0
    )

    /// 현재 제스처가 어느 레이어에 적용되는지
    var activeLayer: GestureLayer = .photo

    // MARK: - PNG Overlay state

    var pngOverlayTexture: MTLTexture?
    var pngOverlayOpacity: Float = 1.0
    // Tracks the last image used to build pngOverlayTexture (prevents per-frame rebuilding)
    var pngOverlayLastImage: UIImage?

    // Source photo tracking — rebuild texture when photo or canvas ratio changes
    var sourcePhotoImage: UIImage?
    var sourcePhotoRatioKey: String = ""

    // Preview texture size
    var previewSize: CGSize = CGSize(width: 1080, height: 1350)

    // Intermediate textures pool (reused per frame)
    private var pingTexture: MTLTexture?
    private var pongTexture: MTLTexture?
    private var currentPreviewSize: CGSize = .zero

    weak var mtkView: MTKView?

    init?(mtkView: MTKView) {
        guard
            let device = MTLCreateSystemDefaultDevice(),
            let queue  = device.makeCommandQueue()
        else { return nil }

        self.device = device
        self.commandQueue = queue
        self.mtkView = mtkView
        super.init()

        mtkView.device                = device
        mtkView.delegate              = self
        mtkView.colorPixelFormat      = .bgra8Unorm
        mtkView.framebufferOnly       = false
        mtkView.isPaused              = true   // displayLink이 setNeedsDisplay로 트리거
        mtkView.enableSetNeedsDisplay = true   // setNeedsDisplay가 draw를 메인 스레드에서 호출

        ShaderPipeline.shared.setup(device: device, commandQueue: queue)
        setupDisplayLink()
    }

    // MARK: - DisplayLink

    private func setupDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkFired(_:)))
        displayLink?.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 60, preferred: 60)
        displayLink?.add(to: .main, forMode: .common)
    }

    @objc private func displayLinkFired(_ link: CADisplayLink) {
        if lastTimestamp == 0 { lastTimestamp = link.timestamp }
        let dt = Float(link.timestamp - lastTimestamp)
        lastTimestamp = link.timestamp
        time += dt
        mtkView?.setNeedsDisplay()
    }

    deinit {
        displayLink?.invalidate()
    }

    // MARK: - MTKViewDelegate

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        currentPreviewSize = .zero
    }

    func draw(in view: MTKView) {
        guard
            let drawable      = view.currentDrawable,
            let commandBuffer = commandQueue.makeCommandBuffer()
        else { return }

        let w = Int(view.drawableSize.width)
        let h = Int(view.drawableSize.height)
        ensureTextures(width: w, height: h)
        guard let ping = pingTexture, let pong = pongTexture else {
            commandBuffer.commit(); return
        }

        // Step 1: 소스 사진에 photoTransform 적용 → ping
        if let src = sourceTexture {
            ShaderPipeline.shared.encodeTransformedPassthrough(
                inputTexture: src, outputTexture: ping,
                commandBuffer: commandBuffer, transform: photoTransform)
        } else {
            clearTexture(ping, commandBuffer: commandBuffer)
        }

        // Step 2: 셰이더 레이어 ping-pong
        let activeLayers = shaderStack.filter { $0.isEnabled }
        let finalTexture: MTLTexture

        if activeLayers.isEmpty {
            finalTexture = ping
        } else {
            var inputTex: MTLTexture = ping
            var outputTex: MTLTexture = pong

            for layer in activeLayers {
                ShaderPipeline.shared.encode(
                    layer: layer,
                    inputTexture: inputTex,
                    outputTexture: outputTex,
                    commandBuffer: commandBuffer,
                    time: time
                )
                swap(&inputTex, &outputTex)
            }
            finalTexture = inputTex
        }

        // Step 3: PNG 오버레이 합성 → drawable
        if let overlayTex = pngOverlayTexture {
            let overlayParams = OverlayUniforms(
                scale:    overlayTransform.scale,
                rotation: overlayTransform.rotation,
                offsetX:  overlayTransform.offsetX,
                offsetY:  overlayTransform.offsetY,
                opacity:  pngOverlayOpacity,
                _pad1: 0, _pad2: 0, _pad3: 0
            )
            ShaderPipeline.shared.encodeOverlay(
                background:    finalTexture,
                overlay:       overlayTex,
                outputTexture: drawable.texture,
                commandBuffer: commandBuffer,
                params:        overlayParams
            )
        } else {
            ShaderPipeline.shared.encodePassthrough(
                inputTexture:  finalTexture,
                outputTexture: drawable.texture,
                commandBuffer: commandBuffer
            )
        }

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    // MARK: - Helpers

    private func ensureTextures(width: Int, height: Int) {
        let size = CGSize(width: width, height: height)
        guard size != currentPreviewSize else { return }
        currentPreviewSize = size
        pingTexture = TextureUtils.makeRenderTarget(width: width, height: height, device: device)
        pongTexture = TextureUtils.makeRenderTarget(width: width, height: height, device: device)
    }

    private func clearTexture(_ texture: MTLTexture, commandBuffer: MTLCommandBuffer) {
        let rpd = MTLRenderPassDescriptor()
        rpd.colorAttachments[0].texture    = texture
        rpd.colorAttachments[0].loadAction  = .clear
        rpd.colorAttachments[0].clearColor  = MTLClearColorMake(0.1, 0.1, 0.1, 1)
        rpd.colorAttachments[0].storeAction = .store
        let enc = commandBuffer.makeRenderCommandEncoder(descriptor: rpd)
        enc?.endEncoding()
    }

    // MARK: - Photo Transform Helper

    /// 소스 사진에 photoTransform을 적용해 outputTexture에 기록.
    /// draw(in:) 외부에서 단독 호출이 필요할 때 사용.
    func encodePhotoTransform(
        inputTexture: MTLTexture,
        outputTexture: MTLTexture,
        commandBuffer: MTLCommandBuffer,
        transform: PhotoTransform
    ) {
        ShaderPipeline.shared.encodeTransformedPassthrough(
            inputTexture: inputTexture,
            outputTexture: outputTexture,
            commandBuffer: commandBuffer,
            transform: transform
        )
    }

    // MARK: - Export Render

    /// Export 해상도로 1회 렌더링해서 MTLTexture 반환.
    /// photoTransform 및 overlayTransform이 반영된다.
    func renderFrame(size: CGSize) -> MTLTexture? {
        let w = Int(size.width)
        let h = Int(size.height)
        guard
            let outTexture = TextureUtils.makeRenderTarget(width: w, height: h, device: device),
            let commandBuffer = commandQueue.makeCommandBuffer()
        else { return nil }

        let pingTex = TextureUtils.makeRenderTarget(width: w, height: h, device: device)!
        let pongTex = TextureUtils.makeRenderTarget(width: w, height: h, device: device)!

        // photoTransform 적용
        if let src = sourceTexture {
            ShaderPipeline.shared.encodeTransformedPassthrough(
                inputTexture: src, outputTexture: pingTex,
                commandBuffer: commandBuffer, transform: photoTransform)
        } else {
            clearTexture(pingTex, commandBuffer: commandBuffer)
        }

        // 셰이더 레이어 ping-pong
        var inputTex: MTLTexture = pingTex
        var altTex: MTLTexture   = pongTex

        for layer in shaderStack where layer.isEnabled {
            ShaderPipeline.shared.encode(
                layer: layer,
                inputTexture: inputTex,
                outputTexture: altTex,
                commandBuffer: commandBuffer,
                time: time
            )
            swap(&inputTex, &altTex)
        }

        // 결과를 outTexture로 복사
        if let blitEnc = commandBuffer.makeBlitCommandEncoder() {
            blitEnc.copy(
                from: inputTex, sourceSlice: 0, sourceLevel: 0,
                sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
                sourceSize: MTLSize(width: w, height: h, depth: 1),
                to: outTexture, destinationSlice: 0, destinationLevel: 0,
                destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0)
            )
            blitEnc.endEncoding()
        }

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        return outTexture
    }
}

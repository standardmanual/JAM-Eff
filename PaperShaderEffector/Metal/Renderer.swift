import Metal
import MetalKit
import QuartzCore

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

        mtkView.device          = device
        mtkView.delegate        = self
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.framebufferOnly  = false
        mtkView.isPaused         = false
        mtkView.enableSetNeedsDisplay = false

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
        // Recreate intermediate textures when drawable size changes
        currentPreviewSize = .zero
    }

    func draw(in view: MTKView) {
        guard
            let drawable       = view.currentDrawable,
            let commandBuffer  = commandQueue.makeCommandBuffer()
        else { return }

        let drawableWidth  = Int(view.drawableSize.width)
        let drawableHeight = Int(view.drawableSize.height)

        // Ensure intermediate textures match drawable size
        ensureTextures(width: drawableWidth, height: drawableHeight)

        guard let ping = pingTexture, let pong = pongTexture else {
            commandBuffer.commit()
            return
        }

        // If no shader layers, blit source texture or clear
        if shaderStack.isEmpty {
            clearTexture(ping, commandBuffer: commandBuffer)
        } else {
            // First input is source texture (or clear if none)
            var inputTex: MTLTexture? = sourceTexture
            var outputTex = ping
            var altTex    = pong

            for layer in shaderStack where layer.isEnabled {
                ShaderPipeline.shared.encode(
                    layer: layer,
                    inputTexture: inputTex,
                    outputTexture: outputTex,
                    commandBuffer: commandBuffer,
                    time: time
                )
                // Ping-pong: output of this pass is input of next
                inputTex = outputTex
                swap(&outputTex, &altTex)
            }
        }

        // Blit final result to drawable
        let finalTexture = shaderStack.isEmpty ? ping : (pingTexture === pongTexture ? ping : ping)
        blitToDrawable(source: finalTexture, drawable: drawable, commandBuffer: commandBuffer)

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

    private func blitToDrawable(source: MTLTexture, drawable: CAMetalDrawable, commandBuffer: MTLCommandBuffer) {
        let rpd = MTLRenderPassDescriptor()
        rpd.colorAttachments[0].texture    = drawable.texture
        rpd.colorAttachments[0].loadAction  = .clear
        rpd.colorAttachments[0].clearColor  = MTLClearColorMake(0, 0, 0, 1)
        rpd.colorAttachments[0].storeAction = .store

        guard let enc = commandBuffer.makeRenderCommandEncoder(descriptor: rpd) else { return }
        // Simple blit using a passthrough pipeline if needed
        // For now we rely on the last layer's output being already in the drawable-sized texture
        // and do a manual copy via BlitCommandEncoder
        enc.endEncoding()

        // Use blit encoder to copy source → drawable
        if let blitEnc = commandBuffer.makeBlitCommandEncoder() {
            let srcSize = MTLSize(width: min(source.width, drawable.texture.width),
                                  height: min(source.height, drawable.texture.height),
                                  depth: 1)
            blitEnc.copy(
                from: source, sourceSlice: 0, sourceLevel: 0,
                sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
                size: srcSize,
                to: drawable.texture, destinationSlice: 0, destinationLevel: 0,
                destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0)
            )
            blitEnc.endEncoding()
        }
    }

    // MARK: - Export Render

    /// Export 해상도로 1회 렌더링해서 UIImage 반환
    func renderFrame(size: CGSize) -> MTLTexture? {
        let w = Int(size.width)
        let h = Int(size.height)
        guard
            let outTexture = TextureUtils.makeRenderTarget(width: w, height: h, device: device),
            let commandBuffer = commandQueue.makeCommandBuffer()
        else { return nil }

        var inputTex: MTLTexture? = sourceTexture
        var pingTex = TextureUtils.makeRenderTarget(width: w, height: h, device: device)!
        var pongTex = TextureUtils.makeRenderTarget(width: w, height: h, device: device)!

        for layer in shaderStack where layer.isEnabled {
            ShaderPipeline.shared.encode(
                layer: layer,
                inputTexture: inputTex,
                outputTexture: pingTex,
                commandBuffer: commandBuffer,
                time: time
            )
            inputTex = pingTex
            swap(&pingTex, &pongTex)
        }

        // Copy result
        if let blitEnc = commandBuffer.makeBlitCommandEncoder(), let inputTex {
            blitEnc.copy(
                from: inputTex, sourceSlice: 0, sourceLevel: 0,
                sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
                size: MTLSize(width: w, height: h, depth: 1),
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

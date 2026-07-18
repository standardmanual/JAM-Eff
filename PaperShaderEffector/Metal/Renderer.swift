import Metal
import MetalKit
import UIKit
import QuartzCore

// MARK: - Renderer

final class Renderer: NSObject, MTKViewDelegate {

    private(set) var device: MTLDevice
    private(set) var commandQueue: MTLCommandQueue

    var time: Float = 0
    private var lastTimestamp: CFTimeInterval = 0
    private var displayLink: CADisplayLink?

    // Shared state synced from EditSession via MetalPreviewView.updateUIView
    var shaderStack: [ShaderLayer] = []

    // Canvas pixel size (matches exportSpec.ratio.pixelSize) — used as cache key for image layers
    var canvasPixelSize: CGSize = CGSize(width: 1080, height: 1350)
    var currentRatioKey: String = ""

    // Image layer texture cache: layer.id → (ratioKey, MTLTexture)
    var imageTextureCache: [UUID: (String, MTLTexture)] = [:]

    // Selected image layer's live gesture transform (written directly, bypassing SwiftUI)
    var selectedLayerID: UUID? = nil
    var selectedLayerTransform: PhotoTransform = .identity

    private var pingTexture:    MTLTexture?
    private var pongTexture:    MTLTexture?
    private var scratchTexture: MTLTexture?
    private var currentDrawableSize: CGSize = .zero

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
        mtkView.isPaused              = true
        mtkView.enableSetNeedsDisplay = true

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

    deinit { displayLink?.invalidate() }

    // MARK: - MTKViewDelegate

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        currentDrawableSize = .zero
    }

    func draw(in view: MTKView) {
        guard
            let drawable      = view.currentDrawable,
            let commandBuffer = commandQueue.makeCommandBuffer()
        else { return }

        let w = Int(view.drawableSize.width)
        let h = Int(view.drawableSize.height)
        ensureTextures(width: w, height: h)
        guard let ping = pingTexture, let pong = pongTexture, let scratch = scratchTexture else {
            commandBuffer.commit(); return
        }

        clearTexture(ping, commandBuffer: commandBuffer)

        let activeLayers = shaderStack.filter { $0.isEnabled }
        var inputTex: MTLTexture = ping
        var outputTex: MTLTexture = pong
        let ratioKey = "\(Int(canvasPixelSize.width))x\(Int(canvasPixelSize.height))"

        for layer in activeLayers {
            switch layer.kind {
            case .image(let img):
                guard let imageTex = cachedImageTexture(for: layer, image: img, ratioKey: ratioKey) else { continue }
                let transform = (layer.id == selectedLayerID) ? selectedLayerTransform : layer.imageTransform
                let canvasAspect = Float(canvasPixelSize.width / canvasPixelSize.height)
                let params = OverlayUniforms(
                    scale: transform.scale, rotation: transform.rotation,
                    offsetX: transform.offsetX, offsetY: transform.offsetY,
                    opacity: layer.opacity, canvasAspect: canvasAspect,
                    blendMode: layer.blendMode.rawValue
                )
                ShaderPipeline.shared.encodeOverlay(
                    background: inputTex, overlay: imageTex,
                    outputTexture: outputTex, commandBuffer: commandBuffer, params: params
                )

            case .shader:
                // Render shader to scratch, then composite with blend mode + opacity
                ShaderPipeline.shared.encode(
                    layer: layer, inputTexture: inputTex, outputTexture: scratch,
                    commandBuffer: commandBuffer, time: time
                )
                let canvasAspect = Float(canvasPixelSize.width / canvasPixelSize.height)
                let blendParams = OverlayUniforms(
                    scale: 1.0, rotation: 0, offsetX: 0, offsetY: 0,
                    opacity: layer.opacity, canvasAspect: canvasAspect,
                    blendMode: layer.blendMode.rawValue
                )
                ShaderPipeline.shared.encodeOverlay(
                    background: inputTex, overlay: scratch,
                    outputTexture: outputTex, commandBuffer: commandBuffer, params: blendParams
                )
            }
            swap(&inputTex, &outputTex)
        }

        let finalTex = activeLayers.isEmpty ? ping : inputTex
        ShaderPipeline.shared.encodePassthrough(
            inputTexture: finalTex, outputTexture: drawable.texture, commandBuffer: commandBuffer
        )

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    // MARK: - Image Texture Cache

    private func cachedImageTexture(for layer: ShaderLayer, image: UIImage, ratioKey: String) -> MTLTexture? {
        if let (cachedKey, cachedTex) = imageTextureCache[layer.id], cachedKey == ratioKey {
            return cachedTex
        }
        guard let newTex = TextureUtils.canvasTexture(from: image, canvasSize: canvasPixelSize, device: device) else { return nil }
        imageTextureCache[layer.id] = (ratioKey, newTex)
        return newTex
    }

    // MARK: - Helpers

    private func ensureTextures(width: Int, height: Int) {
        let size = CGSize(width: width, height: height)
        guard size != currentDrawableSize else { return }
        currentDrawableSize = size
        pingTexture    = TextureUtils.makeRenderTarget(width: width, height: height, device: device)
        pongTexture    = TextureUtils.makeRenderTarget(width: width, height: height, device: device)
        scratchTexture = TextureUtils.makeRenderTarget(width: width, height: height, device: device)
    }

    private func clearTexture(_ texture: MTLTexture, commandBuffer: MTLCommandBuffer) {
        let rpd = MTLRenderPassDescriptor()
        rpd.colorAttachments[0].texture    = texture
        rpd.colorAttachments[0].loadAction  = .clear
        rpd.colorAttachments[0].clearColor  = MTLClearColorMake(0.1, 0.1, 0.1, 1)
        rpd.colorAttachments[0].storeAction = .store
        commandBuffer.makeRenderCommandEncoder(descriptor: rpd)?.endEncoding()
    }

    // MARK: - Export Render

    func renderFrame(size: CGSize) -> MTLTexture? {
        let w = Int(size.width)
        let h = Int(size.height)
        guard
            let outTexture    = TextureUtils.makeRenderTarget(width: w, height: h, device: device),
            let commandBuffer = commandQueue.makeCommandBuffer()
        else { return nil }

        let pingTex    = TextureUtils.makeRenderTarget(width: w, height: h, device: device)!
        let pongTex    = TextureUtils.makeRenderTarget(width: w, height: h, device: device)!
        let scratchTex = TextureUtils.makeRenderTarget(width: w, height: h, device: device)!
        clearTexture(pingTex, commandBuffer: commandBuffer)

        let ratioKey = "\(w)x\(h)"
        var inputTex: MTLTexture = pingTex
        var altTex: MTLTexture   = pongTex
        let canvasAspect = Float(w) / Float(h)

        for layer in shaderStack where layer.isEnabled {
            switch layer.kind {
            case .image(let img):
                let imageTex: MTLTexture
                if let (cachedKey, cachedTex) = imageTextureCache[layer.id], cachedKey == ratioKey {
                    imageTex = cachedTex
                } else if let newTex = TextureUtils.canvasTexture(from: img, canvasSize: size, device: device) {
                    imageTextureCache[layer.id] = (ratioKey, newTex)
                    imageTex = newTex
                } else {
                    continue
                }
                let transform = (layer.id == selectedLayerID) ? selectedLayerTransform : layer.imageTransform
                let params = OverlayUniforms(
                    scale: transform.scale, rotation: transform.rotation,
                    offsetX: transform.offsetX, offsetY: transform.offsetY,
                    opacity: layer.opacity, canvasAspect: canvasAspect,
                    blendMode: layer.blendMode.rawValue
                )
                ShaderPipeline.shared.encodeOverlay(
                    background: inputTex, overlay: imageTex,
                    outputTexture: altTex, commandBuffer: commandBuffer, params: params
                )

            case .shader:
                ShaderPipeline.shared.encode(
                    layer: layer, inputTexture: inputTex, outputTexture: scratchTex,
                    commandBuffer: commandBuffer, time: time
                )
                let blendParams = OverlayUniforms(
                    scale: 1.0, rotation: 0, offsetX: 0, offsetY: 0,
                    opacity: layer.opacity, canvasAspect: canvasAspect,
                    blendMode: layer.blendMode.rawValue
                )
                ShaderPipeline.shared.encodeOverlay(
                    background: inputTex, overlay: scratchTex,
                    outputTexture: altTex, commandBuffer: commandBuffer, params: blendParams
                )
            }
            swap(&inputTex, &altTex)
        }

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

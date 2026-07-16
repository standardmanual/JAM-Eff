import Metal
import MetalKit

// MARK: - Uniform Structs (must match .metal definitions)

struct CommonUniforms {
    var time: Float
    var resolution: SIMD2<Float>
    var scale: Float
    var rotation: Float
    var originX: Float
    var originY: Float
    var offsetX: Float
    var offsetY: Float
    var fit: Int32
}

struct MeshGradientUniforms {
    var distortion: Float
    var swirl: Float
    var grainMixer: Float
    var grainOverlay: Float
    var colorCount: Int32
}

struct WavesUniforms {
    var shape: Float
    var frequency: Float
    var amplitude: Float
    var spacing: Float
    var proportion: Float
    var softness: Float
    var colorFront: SIMD4<Float>
    var colorBack: SIMD4<Float>
}

// MARK: - Vertex Data

struct VertexData {
    var position: SIMD4<Float>
    var texCoord: SIMD2<Float>
}

// MARK: - ShaderPipeline

final class ShaderPipeline {

    static let shared = ShaderPipeline()

    private var device: MTLDevice?
    private var library: MTLLibrary?
    private var pipelineCache: [String: MTLRenderPipelineState] = [:]
    private var vertexBuffer: MTLBuffer?
    private var commandQueue: MTLCommandQueue?

    // Fullscreen quad vertices (NDC: x ∈ [-1,1], y ∈ [-1,1]; texCoord: [0,1])
    private let quadVertices: [VertexData] = [
        VertexData(position: SIMD4(-1,  1, 0, 1), texCoord: SIMD2(0, 0)),
        VertexData(position: SIMD4( 1,  1, 0, 1), texCoord: SIMD2(1, 0)),
        VertexData(position: SIMD4(-1, -1, 0, 1), texCoord: SIMD2(0, 1)),
        VertexData(position: SIMD4( 1, -1, 0, 1), texCoord: SIMD2(1, 1))
    ]

    private init() { }

    func setup(device: MTLDevice, commandQueue: MTLCommandQueue) {
        self.device = device
        self.commandQueue = commandQueue

        // Load default Metal library (compiled from .metal files in bundle)
        self.library = device.makeDefaultLibrary()

        // Create vertex buffer
        vertexBuffer = device.makeBuffer(
            bytes: quadVertices,
            length: MemoryLayout<VertexData>.stride * quadVertices.count,
            options: .storageModeShared
        )
    }

    // MARK: - Pipeline State

    func pipelineState(for effect: ShaderEffect) -> MTLRenderPipelineState? {
        let key = effect.rawValue
        if let cached = pipelineCache[key] { return cached }

        guard let device, let library else { return nil }

        let (vertexFn, fragmentFn) = shaderFunctionNames(for: effect)
        guard
            let vertex   = library.makeFunction(name: vertexFn),
            let fragment = library.makeFunction(name: fragmentFn)
        else {
            print("[ShaderPipeline] Missing shader functions: \(vertexFn), \(fragmentFn)")
            return nil
        }

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction   = vertex
        descriptor.fragmentFunction = fragment
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        do {
            let state = try device.makeRenderPipelineState(descriptor: descriptor)
            pipelineCache[key] = state
            return state
        } catch {
            print("[ShaderPipeline] Pipeline creation failed for \(effect.rawValue): \(error)")
            return nil
        }
    }

    private func shaderFunctionNames(for effect: ShaderEffect) -> (String, String) {
        switch effect {
        case .meshGradient: return ("vertexPassthrough", "meshGradientFragment")
        case .waves:        return ("vertexPassthrough", "wavesFragment")
        default:            return ("vertexPassthrough", "meshGradientFragment") // fallback
        }
    }

    // MARK: - Render Layer

    /// shaderLayer를 inputTexture에 적용해 outputTexture에 기록
    func encode(
        layer: ShaderLayer,
        inputTexture: MTLTexture?,
        outputTexture: MTLTexture,
        commandBuffer: MTLCommandBuffer,
        time: Float
    ) {
        guard let pipelineState = pipelineState(for: layer.effectType) else { return }
        guard let vertexBuffer else { return }

        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture    = outputTexture
        renderPassDescriptor.colorAttachments[0].loadAction  = .clear
        renderPassDescriptor.colorAttachments[0].clearColor  = MTLClearColorMake(0, 0, 0, 1)
        renderPassDescriptor.colorAttachments[0].storeAction = .store

        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
        encoder.setRenderPipelineState(pipelineState)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)

        // Common uniforms — buffer(0)
        var common = commonUniforms(layer: layer, texture: outputTexture, time: time)
        encoder.setFragmentBytes(&common, length: MemoryLayout<CommonUniforms>.stride, index: 0)

        // Input texture — t0
        if let inputTexture {
            let samplerDescriptor = MTLSamplerDescriptor()
            samplerDescriptor.minFilter = .linear
            samplerDescriptor.magFilter = .linear
            samplerDescriptor.sAddressMode = .clampToEdge
            samplerDescriptor.tAddressMode = .clampToEdge
            if let sampler = device?.makeSamplerState(descriptor: samplerDescriptor) {
                encoder.setFragmentSamplerState(sampler, index: 0)
            }
            encoder.setFragmentTexture(inputTexture, index: 0)
        }

        // Effect-specific uniforms — buffer(1)
        encodeEffectUniforms(encoder: encoder, layer: layer)

        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        encoder.endEncoding()
    }

    private func commonUniforms(layer: ShaderLayer, texture: MTLTexture, time: Float) -> CommonUniforms {
        func floatParam(_ key: String, default val: Float) -> Float {
            if case let .float(v, _, _) = layer.params[key] { return v }
            return val
        }
        func intParam(_ key: String, default val: Int32) -> Int32 {
            if case let .enumInt(v, _) = layer.params[key] { return Int32(v) }
            return val
        }
        return CommonUniforms(
            time:       time,
            resolution: SIMD2<Float>(Float(texture.width), Float(texture.height)),
            scale:      floatParam("scale", default: 1),
            rotation:   floatParam("rotation", default: 0),
            originX:    floatParam("originX", default: 0.5),
            originY:    floatParam("originY", default: 0.5),
            offsetX:    floatParam("offsetX", default: 0),
            offsetY:    floatParam("offsetY", default: 0),
            fit:        intParam("fit", default: 1)
        )
    }

    private func encodeEffectUniforms(encoder: MTLRenderCommandEncoder, layer: ShaderLayer) {
        func floatParam(_ key: String, default val: Float) -> Float {
            if case let .float(v, _, _) = layer.params[key] { return v }
            return val
        }
        func colorParam(_ key: String, default val: SIMD4<Float>) -> SIMD4<Float> {
            if case let .color(v) = layer.params[key] { return v }
            return val
        }

        switch layer.effectType {
        case .meshGradient:
            var u = MeshGradientUniforms(
                distortion:  floatParam("distortion", default: 0.3),
                swirl:       floatParam("swirl", default: 0.2),
                grainMixer:  floatParam("grainMixer", default: 0.1),
                grainOverlay: floatParam("grainOverlay", default: 0.05),
                colorCount:  0
            )
            // Colors — buffer(2) as flat array
            var colors: [SIMD4<Float>] = []
            if case let .colors(vals, _) = layer.params["colors"] {
                colors = Array(vals.prefix(10))
            }
            u.colorCount = Int32(colors.count)
            encoder.setFragmentBytes(&u, length: MemoryLayout<MeshGradientUniforms>.stride, index: 1)
            if !colors.isEmpty {
                encoder.setFragmentBytes(&colors, length: MemoryLayout<SIMD4<Float>>.stride * colors.count, index: 2)
            }

        case .waves:
            var u = WavesUniforms(
                shape:      floatParam("shape", default: 1.5),
                frequency:  floatParam("frequency", default: 1.0),
                amplitude:  floatParam("amplitude", default: 0.3),
                spacing:    floatParam("spacing", default: 1.0),
                proportion: floatParam("proportion", default: 0.5),
                softness:   floatParam("softness", default: 0.3),
                colorFront: colorParam("colorFront", default: SIMD4<Float>(0.1, 0.1, 0.8, 1)),
                colorBack:  colorParam("colorBack",  default: SIMD4<Float>(0.9, 0.9, 1.0, 1))
            )
            encoder.setFragmentBytes(&u, length: MemoryLayout<WavesUniforms>.stride, index: 1)

        default:
            break
        }
    }
}

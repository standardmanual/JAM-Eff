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

struct PerlinNoiseUniforms {
    var proportion: Float
    var softness: Float
    var octaveCount: Float
    var persistence: Float
    var lacunarity: Float
    var colorFront: SIMD4<Float>
    var colorBack: SIMD4<Float>
}

struct GrainGradientUniforms {
    var shape: Int32
    var softness: Float
    var intensity: Float
    var noise: Float
    var colorBack: SIMD4<Float>
    var colorCount: Int32
}

struct HalftonDotsUniforms {
    var type: Int32
    var grid: Int32
    var size: Float
    var radius: Float
    var contrast: Float
    var originalColors: Int32
    var inverted: Int32
    var grainMixer: Float
    var grainOverlay: Float
    var grainSize: Float
    var colorFront: SIMD4<Float>
    var colorBack: SIMD4<Float>
}

struct PaperTextureUniforms {
    var contrast: Float
    var roughness: Float
    var fiber: Float
    var fiberSize: Float
    var crumples: Float
    var foldCount: Float
    var folds: Float
    var fade: Float
    var crumpleSize: Float
    var drops: Float
    var seed: Float
    var colorFront: SIMD4<Float>
    var colorBack: SIMD4<Float>
}

struct PulsingBorderUniforms {
    var aspectRatio: Int32
    var roundness: Float
    var thickness: Float
    var margin: Float
    var softness: Float
    var intensity: Float
    var bloom: Float
    var spots: Float
    var spotSize: Float
    var pulse: Float
    var smoke: Float
    var smokeSize: Float
    var colorBack: SIMD4<Float>
    var colorCount: Int32
}

struct DotOrbitUniforms {
    var size: Float
    var sizeRange: Float
    var spreading: Float
    var stepsPerColor: Float
    var colorBack: SIMD4<Float>
    var colorCount: Int32
}

// MARK: - Phase 2 Uniform Structs

struct FlutedGlassUniforms {
    var shadows: Float;       var highlights: Float;    var size: Float;       var angle: Float
    var distortion: Float;    var shift: Float;         var blur: Float;       var edges: Float
    var grainMixer: Float;    var grainOverlay: Float
    var distortionShape: Int32; var shape: Int32
    // 48B → float4 at 48
    var colorBack: SIMD4<Float>; var colorShadow: SIMD4<Float>; var colorHighlight: SIMD4<Float>
    // 96B
    var stretch: Float; var _pad1: Float; var _pad2: Float; var _pad3: Float
    // Total: 112B
}

struct WaterUniforms {
    var highlights: Float; var layering: Float; var edges: Float; var caustic: Float
    var wavesAmt: Float;   var size: Float;     var _pad0: Float;  var _pad1: Float
    // 32B → float4 at 32
    var colorBack: SIMD4<Float>; var colorHighlight: SIMD4<Float>
}

struct ImageDitheringUniforms {
    var type: Int32; var originalColors: Int32; var inverted: Int32; var _pad0: Int32
    var size: Float; var colorSteps: Float;     var _pad1: Float;   var _pad2: Float
    // 32B → float4 at 32
    var colorFront: SIMD4<Float>; var colorBack: SIMD4<Float>; var colorHighlight: SIMD4<Float>
}

struct HalftoneCMYKUniforms {
    var type: Int32; var _pad0: Int32
    var size: Float; var contrast: Float; var softness: Float; var grainSize: Float
    var grainMixer: Float; var grainOverlay: Float; var gridNoise: Float
    var floodC: Float; var floodM: Float; var floodY: Float
    // 48B → float4 at 48
    var colorBack: SIMD4<Float>; var colorC: SIMD4<Float>; var colorM: SIMD4<Float>
    var colorY: SIMD4<Float>;    var colorK: SIMD4<Float>
    // 128B
    var floodK: Float; var gainC: Float; var gainM: Float; var gainY: Float; var gainK: Float
    var _pad1: Float; var _pad2: Float; var _pad3: Float
    // Total: 160B
}

struct StaticMeshGradientUniforms {
    var waveX: Float; var waveXShift: Float; var waveY: Float; var waveYShift: Float
    var mixing: Float; var grainMixer: Float; var grainOverlay: Float; var colorCount: Int32
    // 32B, no SIMD4 (colors via buffer(2))
}

struct StaticRadialGradientUniforms {
    var radius: Float; var focalDistance: Float; var focalAngle: Float; var falloff: Float
    var mixing: Float; var distortion: Float; var distortionShift: Float; var distortionFreq: Float
    var grainMixer: Float; var grainOverlay: Float; var colorCount: Int32; var _pad0: Int32
    // 48B → float4 at 48
    var colorBack: SIMD4<Float>
}

struct DitheringUniforms {
    var shape: Int32; var type: Int32; var size: Float; var _pad0: Float
    // 16B → float4 at 16
    var colorBack: SIMD4<Float>; var colorFront: SIMD4<Float>
}

struct DotGridUniforms {
    var shape: Int32; var _pad0: Int32
    var size: Float; var gapX: Float; var gapY: Float; var strokeWidth: Float
    var sizeRange: Float; var opacityRange: Float
    // 32B → float4 at 32
    var colorBack: SIMD4<Float>; var colorFill: SIMD4<Float>; var colorStroke: SIMD4<Float>
}

struct WarpUniforms {
    var shape: Int32; var colorCount: Int32
    var proportion: Float; var softness: Float; var shapeScale: Float
    var distortion: Float; var swirl: Float; var swirlIterations: Float
    // 32B, no SIMD4 (colors via buffer(2))
}

struct SpiralUniforms {
    var density: Float; var distortion: Float; var strokeWidth: Float; var strokeTaper: Float
    var strokeCap: Float; var noise: Float; var noiseFrequency: Float; var softness: Float
    // 32B → float4 at 32
    var colorBack: SIMD4<Float>; var colorFront: SIMD4<Float>
}

struct SwirlUniforms {
    var bandCount: Float; var twist: Float; var center: Float; var proportion: Float
    var softness: Float; var noiseFrequency: Float; var noise: Float; var colorCount: Int32
    // 32B → float4 at 32
    var colorBack: SIMD4<Float>
    // (colors via buffer(2))
}

struct NeuroNoiseUniforms {
    var brightness: Float; var contrast: Float; var _pad0: Float; var _pad1: Float
    // 16B → float4 at 16
    var colorFront: SIMD4<Float>; var colorMid: SIMD4<Float>; var colorBack: SIMD4<Float>
}

struct SimplexNoiseUniforms {
    var stepsPerColor: Float; var softness: Float; var colorCount: Int32; var _pad0: Int32
    // 16B, no SIMD4 (colors via buffer(2))
}

struct VoronoiUniforms {
    var stepsPerColor: Float; var distortion: Float; var gap: Float; var glow: Float
    var colorCount: Int32; var _pad0: Int32; var _pad1: Float; var _pad2: Float
    // 32B → float4 at 32
    var colorGap: SIMD4<Float>; var colorGlow: SIMD4<Float>
    // (colors via buffer(2))
}

struct MetaballsUniforms {
    var count: Float; var size: Float; var colorCount: Int32; var _pad0: Int32
    // 16B → float4 at 16
    var colorBack: SIMD4<Float>
    // (colors via buffer(2))
}

struct ColorPanelsUniforms {
    var angle1: Float; var angle2: Float; var length: Float; var blur: Float
    var fadeIn: Float; var fadeOut: Float; var density: Float; var gradient: Float
    var edges: Int32; var colorCount: Int32; var _pad0: Float; var _pad1: Float
    // 48B → float4 at 48
    var colorBack: SIMD4<Float>
    // (colors via buffer(2))
}

struct SmokeRingUniforms {
    var noiseScale: Float; var thickness: Float; var radius: Float; var innerShape: Float
    var noiseIterations: Float; var colorCount: Int32; var _pad0: Float; var _pad1: Float
    // 32B → float4 at 32
    var colorBack: SIMD4<Float>
    // (colors via buffer(2))
}

struct GodRaysUniforms {
    var spotty: Float; var midSize: Float; var midIntensity: Float; var density: Float
    var intensity: Float; var bloom: Float; var colorCount: Int32; var _pad0: Int32
    // 32B → float4 at 32
    var colorBack: SIMD4<Float>; var colorBloom: SIMD4<Float>
    // (colors via buffer(2))
}

struct HeatmapUniforms {
    var contour: Float; var angle: Float; var noise: Float; var innerGlow: Float
    var outerGlow: Float; var colorCount: Int32; var _pad0: Float; var _pad1: Float
    // 32B → float4 at 32
    var colorBack: SIMD4<Float>
    // (colors via buffer(2))
}

struct LiquidMetalUniforms {
    var shape: Int32; var _pad0: Int32
    var repetition: Float; var shiftRed: Float
    var shiftBlue: Float; var contour: Float; var softness: Float; var distortion: Float
    var angle: Float; var _pad1: Float; var _pad2: Float; var _pad3: Float
    // 48B → float4 at 48
    var colorBack: SIMD4<Float>; var colorTint: SIMD4<Float>
}

struct GemSmokeUniforms {
    var shape: Int32; var colorCount: Int32
    var innerDistortion: Float; var outerDistortion: Float
    var outerGlow: Float; var innerGlow: Float; var offset: Float; var angle: Float
    var size: Float; var _pad0: Float; var _pad1: Float; var _pad2: Float
    // 48B → float4 at 48
    var colorBack: SIMD4<Float>; var colorInner: SIMD4<Float>
    // (colors via buffer(2))
}

// MARK: - Transform Uniforms (must match TransformedPassthrough.metal TransformUniforms)
// 48 bytes: 3 columns × float4 (column-major 3×3 with float4 padding)

struct TransformUniforms {
    var m00: Float; var m10: Float; var _p0: Float; var _p1: Float  // col 0
    var m01: Float; var m11: Float; var _p2: Float; var _p3: Float  // col 1
    var tx:  Float; var ty:  Float; var _p4: Float; var _p5: Float  // translation
}

// MARK: - Overlay Uniforms (must match Overlay.metal OverlayUniforms)
// 32 bytes: 8 × float

struct OverlayUniforms {
    var scale:    Float       // 오버레이 크기 배율 (0.5 = 캔버스 절반 크기)
    var rotation: Float       // 오버레이 회전 (라디안)
    var offsetX:  Float       // 오버레이 위치 X (UV 단위, 0=중앙)
    var offsetY:  Float       // 오버레이 위치 Y (UV 단위, 0=중앙)
    var opacity:  Float
    var _pad1: Float = 0; var _pad2: Float = 0; var _pad3: Float = 0
}

// MARK: - Vertex Data

struct VertexData {
    var position: SIMD4<Float>
    var texCoord: SIMD2<Float>
}

// MARK: - ShaderPipeline

final class ShaderPipeline: @unchecked Sendable {

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
        case .meshGradient:    return ("vertexPassthrough", "meshGradientFragment")
        case .waves:           return ("vertexPassthrough", "wavesFragment")
        case .perlinNoise:     return ("vertexPassthrough", "perlinNoiseFragment")
        case .grainGradient:   return ("vertexPassthrough", "grainGradientFragment")
        case .halftoneDots:    return ("vertexPassthrough", "halftonDotsFragment")
        case .paperTexture:    return ("vertexPassthrough", "paperTextureFragment")
        case .pulsingBorder:   return ("vertexPassthrough", "pulsingBorderFragment")
        case .dotOrbit:        return ("vertexPassthrough", "dotOrbitFragment")
        case .flutedGlass:           return ("vertexPassthrough", "flutedGlassFragment")
        case .water:                 return ("vertexPassthrough", "waterFragment")
        case .imageDithering:        return ("vertexPassthrough", "imageDitheringFragment")
        case .halftoneCMYK:          return ("vertexPassthrough", "halftoneCMYKFragment")
        case .staticMeshGradient:    return ("vertexPassthrough", "staticMeshGradientFragment")
        case .staticRadialGradient:  return ("vertexPassthrough", "staticRadialGradientFragment")
        case .dithering:             return ("vertexPassthrough", "ditheringFragment")
        case .dotGrid:               return ("vertexPassthrough", "dotGridFragment")
        case .warp:                  return ("vertexPassthrough", "warpFragment")
        case .spiral:                return ("vertexPassthrough", "spiralFragment")
        case .swirl:                 return ("vertexPassthrough", "swirlFragment")
        case .neuroNoise:            return ("vertexPassthrough", "neuroNoiseFragment")
        case .simplexNoise:          return ("vertexPassthrough", "simplexNoiseFragment")
        case .voronoi:               return ("vertexPassthrough", "voronoiFragment")
        case .metaballs:             return ("vertexPassthrough", "metaballsFragment")
        case .colorPanels:           return ("vertexPassthrough", "colorPanelsFragment")
        case .smokeRing:             return ("vertexPassthrough", "smokeRingFragment")
        case .godRays:               return ("vertexPassthrough", "godRaysFragment")
        case .heatmap:               return ("vertexPassthrough", "heatmapFragment")
        case .liquidMetal:           return ("vertexPassthrough", "liquidMetalFragment")
        case .gemSmoke:              return ("vertexPassthrough", "gemSmokeFragment")
        }
    }

    // MARK: - Passthrough

    func passthroughPipelineState() -> MTLRenderPipelineState? {
        let key = "__passthrough"
        if let cached = pipelineCache[key] { return cached }
        guard let device, let library,
              let vertex   = library.makeFunction(name: "vertexPassthrough"),
              let fragment = library.makeFunction(name: "passthroughFragment") else { return nil }
        let desc = MTLRenderPipelineDescriptor()
        desc.vertexFunction   = vertex
        desc.fragmentFunction = fragment
        desc.colorAttachments[0].pixelFormat = .bgra8Unorm
        let state = try? device.makeRenderPipelineState(descriptor: desc)
        if let state { pipelineCache[key] = state }
        return state
    }

    func encodePassthrough(
        inputTexture: MTLTexture,
        outputTexture: MTLTexture,
        commandBuffer: MTLCommandBuffer
    ) {
        guard let state = passthroughPipelineState(), let vertexBuffer, let device else { return }
        let rpd = MTLRenderPassDescriptor()
        rpd.colorAttachments[0].texture     = outputTexture
        rpd.colorAttachments[0].loadAction  = .clear
        rpd.colorAttachments[0].clearColor  = MTLClearColorMake(0, 0, 0, 1)
        rpd.colorAttachments[0].storeAction = .store
        guard let enc = commandBuffer.makeRenderCommandEncoder(descriptor: rpd) else { return }
        enc.setRenderPipelineState(state)
        enc.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        let sampDesc = MTLSamplerDescriptor()
        sampDesc.minFilter = .linear; sampDesc.magFilter = .linear
        sampDesc.sAddressMode = .clampToEdge; sampDesc.tAddressMode = .clampToEdge
        if let sampler = device.makeSamplerState(descriptor: sampDesc) {
            enc.setFragmentSamplerState(sampler, index: 0)
        }
        enc.setFragmentTexture(inputTexture, index: 0)
        enc.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        enc.endEncoding()
    }

    // MARK: - Transformed Passthrough

    private let transformedPassthroughKey = "__transformedPassthrough"

    func encodeTransformedPassthrough(
        inputTexture: MTLTexture,
        outputTexture: MTLTexture,
        commandBuffer: MTLCommandBuffer,
        transform: PhotoTransform
    ) {
        if pipelineCache[transformedPassthroughKey] == nil {
            guard let device, let library,
                  let vertex   = library.makeFunction(name: "vertexPassthrough"),
                  let fragment = library.makeFunction(name: "transformedPassthroughFragment")
            else {
                print("[ShaderPipeline] Missing transformedPassthrough shader functions")
                return
            }
            let desc = MTLRenderPipelineDescriptor()
            desc.vertexFunction   = vertex
            desc.fragmentFunction = fragment
            desc.colorAttachments[0].pixelFormat = .bgra8Unorm
            if let state = try? device.makeRenderPipelineState(descriptor: desc) {
                pipelineCache[transformedPassthroughKey] = state
            }
        }
        guard let state = pipelineCache[transformedPassthroughKey],
              let vertexBuffer, let device else { return }

        let m = transform.matrix()
        var u = TransformUniforms(
            m00: m.0, m10: m.1, _p0: 0, _p1: 0,
            m01: m.3, m11: m.4, _p2: 0, _p3: 0,
            tx:  m.6, ty:  m.7, _p4: 0, _p5: 0
        )

        let rpd = MTLRenderPassDescriptor()
        rpd.colorAttachments[0].texture     = outputTexture
        rpd.colorAttachments[0].loadAction  = .clear
        rpd.colorAttachments[0].clearColor  = MTLClearColorMake(0, 0, 0, 1)
        rpd.colorAttachments[0].storeAction = .store
        guard let enc = commandBuffer.makeRenderCommandEncoder(descriptor: rpd) else { return }

        enc.setRenderPipelineState(state)
        enc.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        enc.setFragmentBytes(&u, length: MemoryLayout<TransformUniforms>.stride, index: 0)

        let sampDesc = MTLSamplerDescriptor()
        sampDesc.minFilter    = .linear; sampDesc.magFilter = .linear
        sampDesc.sAddressMode = .clampToEdge; sampDesc.tAddressMode = .clampToEdge
        if let sampler = device.makeSamplerState(descriptor: sampDesc) {
            enc.setFragmentSamplerState(sampler, index: 0)
        }
        enc.setFragmentTexture(inputTexture, index: 0)
        enc.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        enc.endEncoding()
    }

    // MARK: - Overlay

    private let overlayPipelineKey = "__overlay"

    func encodeOverlay(
        background: MTLTexture,
        overlay: MTLTexture,
        outputTexture: MTLTexture,
        commandBuffer: MTLCommandBuffer,
        params: OverlayUniforms
    ) {
        guard let device, let library else { return }
        guard let vertexBuffer else { return }

        if pipelineCache[overlayPipelineKey] == nil {
            guard
                let vertex   = library.makeFunction(name: "vertexPassthrough"),
                let fragment = library.makeFunction(name: "overlayFragment")
            else {
                print("[ShaderPipeline] Missing overlay shader functions")
                return
            }
            let desc = MTLRenderPipelineDescriptor()
            desc.vertexFunction   = vertex
            desc.fragmentFunction = fragment
            desc.colorAttachments[0].pixelFormat = .bgra8Unorm
            if let state = try? device.makeRenderPipelineState(descriptor: desc) {
                pipelineCache[overlayPipelineKey] = state
            }
        }

        guard let pipelineState = pipelineCache[overlayPipelineKey] else { return }

        let rpd = MTLRenderPassDescriptor()
        rpd.colorAttachments[0].texture     = outputTexture
        rpd.colorAttachments[0].loadAction  = .clear
        rpd.colorAttachments[0].clearColor  = MTLClearColorMake(0, 0, 0, 1)
        rpd.colorAttachments[0].storeAction = .store

        guard let enc = commandBuffer.makeRenderCommandEncoder(descriptor: rpd) else { return }
        enc.setRenderPipelineState(pipelineState)
        enc.setVertexBuffer(vertexBuffer, offset: 0, index: 0)

        var u = params
        enc.setFragmentBytes(&u, length: MemoryLayout<OverlayUniforms>.stride, index: 0)

        let sampDesc = MTLSamplerDescriptor()
        sampDesc.minFilter = .linear; sampDesc.magFilter = .linear
        sampDesc.sAddressMode = .clampToEdge; sampDesc.tAddressMode = .clampToEdge
        if let sampler = device.makeSamplerState(descriptor: sampDesc) {
            enc.setFragmentSamplerState(sampler, index: 0)
        }

        enc.setFragmentTexture(background, index: 0)
        enc.setFragmentTexture(overlay, index: 1)
        enc.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        enc.endEncoding()
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
        guard let effect = layer.effectType,
              let pipelineState = pipelineState(for: effect) else { return }
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
        func intParam(_ key: String, default val: Int32) -> Int32 {
            if case let .enumInt(v, _) = layer.params[key] { return Int32(v) }
            return val
        }
        func boolParam(_ key: String, default val: Bool) -> Bool {
            if case let .bool(v) = layer.params[key] { return v }
            return val
        }

        guard let effectType = layer.effectType else { return }
        switch effectType {
        case .meshGradient:
            var u = MeshGradientUniforms(
                distortion:  floatParam("distortion", default: 0.3),
                swirl:       floatParam("swirl", default: 0.2),
                grainMixer:  floatParam("grainMixer", default: 0.1),
                grainOverlay: floatParam("grainOverlay", default: 0.05),
                colorCount:  0
            )
            var colors: [SIMD4<Float>] = []
            if let param = layer.params["colors"], case let .colors(vals, _) = param {
                colors = Array(vals.prefix(10))
            }
            if colors.isEmpty {
                colors = [SIMD4<Float>(0.5, 0.3, 0.9, 1), SIMD4<Float>(0.3, 0.6, 1.0, 1)]
            }
            u.colorCount = Int32(colors.count)
            encoder.setFragmentBytes(&u, length: MemoryLayout<MeshGradientUniforms>.stride, index: 1)
            encoder.setFragmentBytes(&colors, length: MemoryLayout<SIMD4<Float>>.stride * colors.count, index: 2)

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

        case .perlinNoise:
            var u = PerlinNoiseUniforms(
                proportion:  floatParam("proportion", default: 0.5),
                softness:    floatParam("softness",   default: 0.3),
                octaveCount: floatParam("octaveCount", default: 4),
                persistence: floatParam("persistence", default: 0.5),
                lacunarity:  floatParam("lacunarity",  default: 2.0),
                colorFront:  colorParam("colorFront", default: SIMD4<Float>(0.2, 0.2, 0.7, 1)),
                colorBack:   colorParam("colorBack",  default: SIMD4<Float>(0.9, 0.9, 0.9, 1))
            )
            encoder.setFragmentBytes(&u, length: MemoryLayout<PerlinNoiseUniforms>.stride, index: 1)

        case .grainGradient:
            var u = GrainGradientUniforms(
                shape:      Int32(intParam("shape",    default: 0)),
                softness:   floatParam("softness",     default: 0.5),
                intensity:  floatParam("intensity",    default: 0.7),
                noise:      floatParam("noise",        default: 0.3),
                colorBack:  colorParam("colorBack",   default: SIMD4<Float>(0.1, 0.1, 0.1, 1)),
                colorCount: 0
            )
            var colors: [SIMD4<Float>] = []
            if let param = layer.params["colors"], case let .colors(vals, _) = param {
                colors = Array(vals.prefix(10))
            }
            if colors.isEmpty { colors = [SIMD4<Float>(0.8, 0.5, 0.2, 1), SIMD4<Float>(0.2, 0.6, 0.9, 1)] }
            u.colorCount = Int32(colors.count)
            encoder.setFragmentBytes(&u, length: MemoryLayout<GrainGradientUniforms>.stride, index: 1)
            encoder.setFragmentBytes(&colors, length: MemoryLayout<SIMD4<Float>>.stride * colors.count, index: 2)

        case .halftoneDots:
            var u = HalftonDotsUniforms(
                type:           Int32(intParam("type",           default: 0)),
                grid:           Int32(intParam("grid",           default: 0)),
                size:           floatParam("size",               default: 0.5),
                radius:         floatParam("radius",             default: 1.0),
                contrast:       floatParam("contrast",           default: 0.5),
                originalColors: boolParam("originalColors",      default: false) ? 1 : 0,
                inverted:       boolParam("inverted",            default: false) ? 1 : 0,
                grainMixer:     floatParam("grainMixer",         default: 0.1),
                grainOverlay:   floatParam("grainOverlay",       default: 0.05),
                grainSize:      floatParam("grainSize",          default: 0.5),
                colorFront:     colorParam("colorFront",         default: SIMD4<Float>(0, 0, 0, 1)),
                colorBack:      colorParam("colorBack",          default: SIMD4<Float>(1, 1, 1, 1))
            )
            encoder.setFragmentBytes(&u, length: MemoryLayout<HalftonDotsUniforms>.stride, index: 1)

        case .paperTexture:
            var u = PaperTextureUniforms(
                contrast:     floatParam("contrast",    default: 0.5),
                roughness:    floatParam("roughness",   default: 0.5),
                fiber:        floatParam("fiber",       default: 0.3),
                fiberSize:    floatParam("fiberSize",   default: 0.5),
                crumples:     floatParam("crumples",    default: 0.3),
                foldCount:    floatParam("foldCount",   default: 5),
                folds:        floatParam("folds",       default: 0.3),
                fade:         floatParam("fade",        default: 0.5),
                crumpleSize:  floatParam("crumpleSize", default: 0.5),
                drops:        floatParam("drops",       default: 0.1),
                seed:         floatParam("seed",        default: 0),
                colorFront:   colorParam("colorFront",  default: SIMD4<Float>(0.95, 0.92, 0.85, 1)),
                colorBack:    colorParam("colorBack",   default: SIMD4<Float>(0.75, 0.72, 0.65, 1))
            )
            encoder.setFragmentBytes(&u, length: MemoryLayout<PaperTextureUniforms>.stride, index: 1)

        case .pulsingBorder:
            var u = PulsingBorderUniforms(
                aspectRatio: Int32(intParam("aspectRatio", default: 0)),
                roundness:   floatParam("roundness",  default: 0.3),
                thickness:   floatParam("thickness",  default: 0.05),
                margin:      floatParam("margin",     default: 0.1),
                softness:    floatParam("softness",   default: 0.5),
                intensity:   floatParam("intensity",  default: 0.8),
                bloom:       floatParam("bloom",      default: 0.4),
                spots:       floatParam("spots",      default: 3),
                spotSize:    floatParam("spotSize",   default: 0.3),
                pulse:       floatParam("pulse",      default: 0.5),
                smoke:       floatParam("smoke",      default: 0.3),
                smokeSize:   floatParam("smokeSize",  default: 0.5),
                colorBack:   colorParam("colorBack",  default: SIMD4<Float>(0, 0, 0, 1)),
                colorCount:  0
            )
            var colors: [SIMD4<Float>] = []
            if let param = layer.params["colors"], case let .colors(vals, _) = param {
                colors = Array(vals.prefix(10))
            }
            if colors.isEmpty { colors = [SIMD4<Float>(0.6, 0.2, 0.9, 1), SIMD4<Float>(0.2, 0.5, 1.0, 1)] }
            u.colorCount = Int32(colors.count)
            encoder.setFragmentBytes(&u, length: MemoryLayout<PulsingBorderUniforms>.stride, index: 1)
            encoder.setFragmentBytes(&colors, length: MemoryLayout<SIMD4<Float>>.stride * colors.count, index: 2)

        case .dotOrbit:
            var u = DotOrbitUniforms(
                size:          floatParam("size",          default: 0.5),
                sizeRange:     floatParam("sizeRange",     default: 0.3),
                spreading:     floatParam("spreading",     default: 0.5),
                stepsPerColor: floatParam("stepsPerColor", default: 3),
                colorBack:     colorParam("colorBack",     default: SIMD4<Float>(0, 0, 0, 1)),
                colorCount:    0
            )
            var colors: [SIMD4<Float>] = []
            if let param = layer.params["colors"], case let .colors(vals, _) = param {
                colors = Array(vals.prefix(10))
            }
            if colors.isEmpty { colors = [SIMD4<Float>(1, 0.5, 0.1, 1), SIMD4<Float>(0.3, 0.7, 1.0, 1), SIMD4<Float>(0.9, 0.2, 0.5, 1)] }
            u.colorCount = Int32(colors.count)
            encoder.setFragmentBytes(&u, length: MemoryLayout<DotOrbitUniforms>.stride, index: 1)
            encoder.setFragmentBytes(&colors, length: MemoryLayout<SIMD4<Float>>.stride * colors.count, index: 2)

        case .flutedGlass:
            var u = FlutedGlassUniforms(
                shadows: floatParam("shadows", default: 0.5),
                highlights: floatParam("highlights", default: 0.5),
                size: floatParam("size", default: 0.3),
                angle: floatParam("angle", default: 0),
                distortion: floatParam("distortion", default: 0.5),
                shift: floatParam("shift", default: 0),
                blur: floatParam("blur", default: 0.1),
                edges: floatParam("edges", default: 0.3),
                grainMixer: floatParam("grainMixer", default: 0.05),
                grainOverlay: floatParam("grainOverlay", default: 0.05),
                distortionShape: intParam("distortionShape", default: 0),
                shape: intParam("shape", default: 0),
                colorBack: colorParam("colorBack", default: SIMD4<Float>(0.5, 0.5, 0.6, 1)),
                colorShadow: colorParam("colorShadow", default: SIMD4<Float>(0.2, 0.2, 0.3, 1)),
                colorHighlight: colorParam("colorHighlight", default: SIMD4<Float>(0.9, 0.9, 1, 1)),
                stretch: floatParam("stretch", default: 0),
                _pad1: 0, _pad2: 0, _pad3: 0
            )
            encoder.setFragmentBytes(&u, length: MemoryLayout<FlutedGlassUniforms>.stride, index: 1)

        case .water:
            var u = WaterUniforms(
                highlights: floatParam("highlights", default: 0.5),
                layering: floatParam("layering", default: 0.5),
                edges: floatParam("edges", default: 0.3),
                caustic: floatParam("caustic", default: 0.3),
                wavesAmt: floatParam("wavesAmt", default: 0.5),
                size: floatParam("size", default: 1.0),
                _pad0: 0, _pad1: 0,
                colorBack: colorParam("colorBack", default: SIMD4<Float>(0.1, 0.3, 0.6, 1)),
                colorHighlight: colorParam("colorHighlight", default: SIMD4<Float>(0.8, 0.9, 1, 1))
            )
            encoder.setFragmentBytes(&u, length: MemoryLayout<WaterUniforms>.stride, index: 1)

        case .imageDithering:
            var u = ImageDitheringUniforms(
                type: intParam("type", default: 1),
                originalColors: boolParam("originalColors", default: false) ? 1 : 0,
                inverted: boolParam("inverted", default: false) ? 1 : 0,
                _pad0: 0,
                size: floatParam("size", default: 0.5),
                colorSteps: floatParam("colorSteps", default: 4),
                _pad1: 0, _pad2: 0,
                colorFront: colorParam("colorFront", default: SIMD4<Float>(0, 0, 0, 1)),
                colorBack: colorParam("colorBack", default: SIMD4<Float>(1, 1, 1, 1)),
                colorHighlight: colorParam("colorHighlight", default: SIMD4<Float>(0.5, 0.5, 0.5, 1))
            )
            encoder.setFragmentBytes(&u, length: MemoryLayout<ImageDitheringUniforms>.stride, index: 1)

        case .halftoneCMYK:
            var u = HalftoneCMYKUniforms(
                type: intParam("type", default: 1),
                _pad0: 0,
                size: floatParam("size", default: 0.3),
                contrast: floatParam("contrast", default: 0.5),
                softness: floatParam("softness", default: 0.2),
                grainSize: floatParam("grainSize", default: 0.5),
                grainMixer: floatParam("grainMixer", default: 0.05),
                grainOverlay: floatParam("grainOverlay", default: 0.05),
                gridNoise: floatParam("gridNoise", default: 0.1),
                floodC: floatParam("floodC", default: 0.15),
                floodM: floatParam("floodM", default: 0),
                floodY: floatParam("floodY", default: 0),
                colorBack: colorParam("colorBack", default: SIMD4<Float>(1, 1, 1, 1)),
                colorC: colorParam("colorC", default: SIMD4<Float>(0, 1, 1, 1)),
                colorM: colorParam("colorM", default: SIMD4<Float>(1, 0, 1, 1)),
                colorY: colorParam("colorY", default: SIMD4<Float>(1, 1, 0, 1)),
                colorK: colorParam("colorK", default: SIMD4<Float>(0, 0, 0, 1)),
                floodK: floatParam("floodK", default: 0),
                gainC: floatParam("gainC", default: 0.3),
                gainM: floatParam("gainM", default: 0),
                gainY: floatParam("gainY", default: 0.2),
                gainK: floatParam("gainK", default: 0),
                _pad1: 0, _pad2: 0, _pad3: 0
            )
            encoder.setFragmentBytes(&u, length: MemoryLayout<HalftoneCMYKUniforms>.stride, index: 1)

        case .staticMeshGradient:
            var u = StaticMeshGradientUniforms(
                waveX: floatParam("waveX", default: 3.0),
                waveXShift: floatParam("waveXShift", default: 0),
                waveY: floatParam("waveY", default: 3.0),
                waveYShift: floatParam("waveYShift", default: 0),
                mixing: floatParam("mixing", default: 0.5),
                grainMixer: floatParam("grainMixer", default: 0.05),
                grainOverlay: floatParam("grainOverlay", default: 0.05),
                colorCount: 0
            )
            var colors: [SIMD4<Float>] = []
            if let param = layer.params["colors"], case let .colors(vals, _) = param {
                colors = Array(vals.prefix(10))
            }
            if colors.isEmpty { colors = [SIMD4<Float>(0.8, 0.3, 0.9, 1), SIMD4<Float>(0.3, 0.7, 1, 1), SIMD4<Float>(0.9, 0.5, 0.2, 1)] }
            u.colorCount = Int32(colors.count)
            encoder.setFragmentBytes(&u, length: MemoryLayout<StaticMeshGradientUniforms>.stride, index: 1)
            encoder.setFragmentBytes(&colors, length: MemoryLayout<SIMD4<Float>>.stride * colors.count, index: 2)

        case .staticRadialGradient:
            var u = StaticRadialGradientUniforms(
                radius: floatParam("radius", default: 0.5),
                focalDistance: floatParam("focalDistance", default: 0),
                focalAngle: floatParam("focalAngle", default: 0),
                falloff: floatParam("falloff", default: 1.0),
                mixing: floatParam("mixing", default: 0.5),
                distortion: floatParam("distortion", default: 0.1),
                distortionShift: floatParam("distortionShift", default: 0),
                distortionFreq: floatParam("distortionFreq", default: 3.0),
                grainMixer: floatParam("grainMixer", default: 0.05),
                grainOverlay: floatParam("grainOverlay", default: 0.05),
                colorCount: 0,
                _pad0: 0,
                colorBack: colorParam("colorBack", default: SIMD4<Float>(0, 0, 0, 1))
            )
            var colors: [SIMD4<Float>] = []
            if let param = layer.params["colors"], case let .colors(vals, _) = param {
                colors = Array(vals.prefix(10))
            }
            if colors.isEmpty { colors = [SIMD4<Float>(0.9, 0.6, 0.2, 1), SIMD4<Float>(0.8, 0.2, 0.7, 1)] }
            u.colorCount = Int32(colors.count)
            encoder.setFragmentBytes(&u, length: MemoryLayout<StaticRadialGradientUniforms>.stride, index: 1)
            encoder.setFragmentBytes(&colors, length: MemoryLayout<SIMD4<Float>>.stride * colors.count, index: 2)

        case .dithering:
            var u = DitheringUniforms(
                shape: intParam("shape", default: 0),
                type: intParam("type", default: 1),
                size: floatParam("size", default: 0.5),
                _pad0: 0,
                colorBack: colorParam("colorBack", default: SIMD4<Float>(1, 1, 1, 1)),
                colorFront: colorParam("colorFront", default: SIMD4<Float>(0, 0, 0, 1))
            )
            encoder.setFragmentBytes(&u, length: MemoryLayout<DitheringUniforms>.stride, index: 1)

        case .dotGrid:
            var u = DotGridUniforms(
                shape: intParam("shape", default: 0),
                _pad0: 0,
                size: floatParam("size", default: 8),
                gapX: floatParam("gapX", default: 32),
                gapY: floatParam("gapY", default: 32),
                strokeWidth: floatParam("strokeWidth", default: 0),
                sizeRange: floatParam("sizeRange", default: 0.2),
                opacityRange: floatParam("opacityRange", default: 0.2),
                colorBack: colorParam("colorBack", default: SIMD4<Float>(0.95, 0.95, 0.95, 1)),
                colorFill: colorParam("colorFill", default: SIMD4<Float>(0.3, 0.3, 0.9, 1)),
                colorStroke: colorParam("colorStroke", default: SIMD4<Float>(0.1, 0.1, 0.5, 1))
            )
            encoder.setFragmentBytes(&u, length: MemoryLayout<DotGridUniforms>.stride, index: 1)

        case .warp:
            var u = WarpUniforms(
                shape: intParam("shape", default: 0),
                colorCount: 0,
                proportion: floatParam("proportion", default: 0.5),
                softness: floatParam("softness", default: 0.3),
                shapeScale: floatParam("shapeScale", default: 0.5),
                distortion: floatParam("distortion", default: 0.5),
                swirl: floatParam("swirl", default: 0.3),
                swirlIterations: floatParam("swirlIterations", default: 3)
            )
            var colors: [SIMD4<Float>] = []
            if let param = layer.params["colors"], case let .colors(vals, _) = param {
                colors = Array(vals.prefix(10))
            }
            if colors.isEmpty { colors = [SIMD4<Float>(0.9, 0.3, 0.5, 1), SIMD4<Float>(0.3, 0.6, 1, 1), SIMD4<Float>(0.9, 0.8, 0.2, 1)] }
            u.colorCount = Int32(colors.count)
            encoder.setFragmentBytes(&u, length: MemoryLayout<WarpUniforms>.stride, index: 1)
            encoder.setFragmentBytes(&colors, length: MemoryLayout<SIMD4<Float>>.stride * colors.count, index: 2)

        case .spiral:
            var u = SpiralUniforms(
                density: floatParam("density", default: 0.5),
                distortion: floatParam("distortion", default: 0.2),
                strokeWidth: floatParam("strokeWidth", default: 0.3),
                strokeTaper: floatParam("strokeTaper", default: 0.5),
                strokeCap: floatParam("strokeCap", default: 0.5),
                noise: floatParam("noise", default: 0.2),
                noiseFrequency: floatParam("noiseFrequency", default: 2.0),
                softness: floatParam("softness", default: 0.3),
                colorBack: colorParam("colorBack", default: SIMD4<Float>(0, 0, 0, 1)),
                colorFront: colorParam("colorFront", default: SIMD4<Float>(0.9, 0.9, 0.9, 1))
            )
            encoder.setFragmentBytes(&u, length: MemoryLayout<SpiralUniforms>.stride, index: 1)

        case .swirl:
            var u = SwirlUniforms(
                bandCount: floatParam("bandCount", default: 5),
                twist: floatParam("twist", default: 0.5),
                center: floatParam("center", default: 0.5),
                proportion: floatParam("proportion", default: 0.5),
                softness: floatParam("softness", default: 0.3),
                noiseFrequency: floatParam("noiseFrequency", default: 2.0),
                noise: floatParam("noise", default: 0.3),
                colorCount: 0,
                colorBack: colorParam("colorBack", default: SIMD4<Float>(0, 0, 0, 1))
            )
            var colors: [SIMD4<Float>] = []
            if let param = layer.params["colors"], case let .colors(vals, _) = param {
                colors = Array(vals.prefix(10))
            }
            if colors.isEmpty { colors = [SIMD4<Float>(0.8, 0.2, 0.9, 1), SIMD4<Float>(0.2, 0.5, 1, 1)] }
            u.colorCount = Int32(colors.count)
            encoder.setFragmentBytes(&u, length: MemoryLayout<SwirlUniforms>.stride, index: 1)
            encoder.setFragmentBytes(&colors, length: MemoryLayout<SIMD4<Float>>.stride * colors.count, index: 2)

        case .neuroNoise:
            var u = NeuroNoiseUniforms(
                brightness: floatParam("brightness", default: 0.5),
                contrast: floatParam("contrast", default: 0.6),
                _pad0: 0, _pad1: 0,
                colorFront: colorParam("colorFront", default: SIMD4<Float>(0.9, 0.7, 1, 1)),
                colorMid: colorParam("colorMid", default: SIMD4<Float>(0.4, 0.2, 0.8, 1)),
                colorBack: colorParam("colorBack", default: SIMD4<Float>(0.05, 0.05, 0.15, 1))
            )
            encoder.setFragmentBytes(&u, length: MemoryLayout<NeuroNoiseUniforms>.stride, index: 1)

        case .simplexNoise:
            var u = SimplexNoiseUniforms(
                stepsPerColor: floatParam("stepsPerColor", default: 1.0),
                softness: floatParam("softness", default: 0.5),
                colorCount: 0,
                _pad0: 0
            )
            var colors: [SIMD4<Float>] = []
            if let param = layer.params["colors"], case let .colors(vals, _) = param {
                colors = Array(vals.prefix(10))
            }
            if colors.isEmpty { colors = [SIMD4<Float>(0.3, 0.8, 0.9, 1), SIMD4<Float>(0.9, 0.3, 0.6, 1), SIMD4<Float>(0.9, 0.9, 0.3, 1)] }
            u.colorCount = Int32(colors.count)
            encoder.setFragmentBytes(&u, length: MemoryLayout<SimplexNoiseUniforms>.stride, index: 1)
            encoder.setFragmentBytes(&colors, length: MemoryLayout<SIMD4<Float>>.stride * colors.count, index: 2)

        case .voronoi:
            var u = VoronoiUniforms(
                stepsPerColor: floatParam("stepsPerColor", default: 1.0),
                distortion: floatParam("distortion", default: 0.3),
                gap: floatParam("gap", default: 0.05),
                glow: floatParam("glow", default: 0.2),
                colorCount: 0,
                _pad0: 0, _pad1: 0, _pad2: 0,
                colorGap: colorParam("colorGap", default: SIMD4<Float>(0, 0, 0, 1)),
                colorGlow: colorParam("colorGlow", default: SIMD4<Float>(1, 1, 1, 1))
            )
            var colors: [SIMD4<Float>] = []
            if let param = layer.params["colors"], case let .colors(vals, _) = param {
                colors = Array(vals.prefix(5))
            }
            if colors.isEmpty { colors = [SIMD4<Float>(0.9, 0.3, 0.4, 1), SIMD4<Float>(0.3, 0.6, 0.9, 1), SIMD4<Float>(0.9, 0.8, 0.2, 1)] }
            u.colorCount = Int32(colors.count)
            encoder.setFragmentBytes(&u, length: MemoryLayout<VoronoiUniforms>.stride, index: 1)
            encoder.setFragmentBytes(&colors, length: MemoryLayout<SIMD4<Float>>.stride * colors.count, index: 2)

        case .metaballs:
            var u = MetaballsUniforms(
                count: floatParam("count", default: 5),
                size: floatParam("size", default: 0.4),
                colorCount: 0,
                _pad0: 0,
                colorBack: colorParam("colorBack", default: SIMD4<Float>(0, 0, 0, 1))
            )
            var colors: [SIMD4<Float>] = []
            if let param = layer.params["colors"], case let .colors(vals, _) = param {
                colors = Array(vals.prefix(8))
            }
            if colors.isEmpty { colors = [SIMD4<Float>(0.5, 0.2, 0.9, 1), SIMD4<Float>(0.2, 0.7, 0.9, 1)] }
            u.colorCount = Int32(colors.count)
            encoder.setFragmentBytes(&u, length: MemoryLayout<MetaballsUniforms>.stride, index: 1)
            encoder.setFragmentBytes(&colors, length: MemoryLayout<SIMD4<Float>>.stride * colors.count, index: 2)

        case .colorPanels:
            var u = ColorPanelsUniforms(
                angle1: floatParam("angle1", default: 45),
                angle2: floatParam("angle2", default: 135),
                length: floatParam("length", default: 0.5),
                blur: floatParam("blur", default: 0.1),
                fadeIn: floatParam("fadeIn", default: 0.1),
                fadeOut: floatParam("fadeOut", default: 0.1),
                density: floatParam("density", default: 1.0),
                gradient: floatParam("gradient", default: 0.3),
                edges: boolParam("edges", default: false) ? 1 : 0,
                colorCount: 0,
                _pad0: 0, _pad1: 0,
                colorBack: colorParam("colorBack", default: SIMD4<Float>(0, 0, 0, 1))
            )
            var colors: [SIMD4<Float>] = []
            if let param = layer.params["colors"], case let .colors(vals, _) = param {
                colors = Array(vals.prefix(7))
            }
            if colors.isEmpty { colors = [SIMD4<Float>(0.9, 0.3, 0.5, 1), SIMD4<Float>(0.3, 0.5, 0.9, 1), SIMD4<Float>(0.9, 0.8, 0.3, 1)] }
            u.colorCount = Int32(colors.count)
            encoder.setFragmentBytes(&u, length: MemoryLayout<ColorPanelsUniforms>.stride, index: 1)
            encoder.setFragmentBytes(&colors, length: MemoryLayout<SIMD4<Float>>.stride * colors.count, index: 2)

        case .smokeRing:
            var u = SmokeRingUniforms(
                noiseScale: floatParam("noiseScale", default: 3.0),
                thickness: floatParam("thickness", default: 0.15),
                radius: floatParam("radius", default: 0.35),
                innerShape: floatParam("innerShape", default: 0),
                noiseIterations: floatParam("noiseIterations", default: 3),
                colorCount: 0,
                _pad0: 0, _pad1: 0,
                colorBack: colorParam("colorBack", default: SIMD4<Float>(0, 0, 0, 1))
            )
            var colors: [SIMD4<Float>] = []
            if let param = layer.params["colors"], case let .colors(vals, _) = param {
                colors = Array(vals.prefix(10))
            }
            if colors.isEmpty { colors = [SIMD4<Float>(0.9, 0.5, 0.2, 1), SIMD4<Float>(0.9, 0.2, 0.5, 1)] }
            u.colorCount = Int32(colors.count)
            encoder.setFragmentBytes(&u, length: MemoryLayout<SmokeRingUniforms>.stride, index: 1)
            encoder.setFragmentBytes(&colors, length: MemoryLayout<SIMD4<Float>>.stride * colors.count, index: 2)

        case .godRays:
            var u = GodRaysUniforms(
                spotty: floatParam("spotty", default: 0.3),
                midSize: floatParam("midSize", default: 0.1),
                midIntensity: floatParam("midIntensity", default: 0.8),
                density: floatParam("density", default: 8),
                intensity: floatParam("intensity", default: 0.6),
                bloom: floatParam("bloom", default: 0.3),
                colorCount: 0,
                _pad0: 0,
                colorBack: colorParam("colorBack", default: SIMD4<Float>(0.05, 0, 0.1, 1)),
                colorBloom: colorParam("colorBloom", default: SIMD4<Float>(1, 0.9, 0.7, 1))
            )
            var colors: [SIMD4<Float>] = []
            if let param = layer.params["colors"], case let .colors(vals, _) = param {
                colors = Array(vals.prefix(10))
            }
            if colors.isEmpty { colors = [SIMD4<Float>(1, 0.8, 0.3, 1), SIMD4<Float>(0.8, 0.3, 1, 1)] }
            u.colorCount = Int32(colors.count)
            encoder.setFragmentBytes(&u, length: MemoryLayout<GodRaysUniforms>.stride, index: 1)
            encoder.setFragmentBytes(&colors, length: MemoryLayout<SIMD4<Float>>.stride * colors.count, index: 2)

        case .heatmap:
            var u = HeatmapUniforms(
                contour: floatParam("contour", default: 0.2),
                angle: floatParam("angle", default: 0),
                noise: floatParam("noise", default: 0.3),
                innerGlow: floatParam("innerGlow", default: 0.3),
                outerGlow: floatParam("outerGlow", default: 0.3),
                colorCount: 0,
                _pad0: 0, _pad1: 0,
                colorBack: colorParam("colorBack", default: SIMD4<Float>(0, 0, 0, 1))
            )
            var colors: [SIMD4<Float>] = []
            if let param = layer.params["colors"], case let .colors(vals, _) = param {
                colors = Array(vals.prefix(10))
            }
            if colors.isEmpty { colors = [SIMD4<Float>(0.1, 0.1, 0.9, 1), SIMD4<Float>(0.1, 0.9, 0.1, 1), SIMD4<Float>(0.9, 0.9, 0.1, 1), SIMD4<Float>(0.9, 0.1, 0.1, 1)] }
            u.colorCount = Int32(colors.count)
            encoder.setFragmentBytes(&u, length: MemoryLayout<HeatmapUniforms>.stride, index: 1)
            encoder.setFragmentBytes(&colors, length: MemoryLayout<SIMD4<Float>>.stride * colors.count, index: 2)

        case .liquidMetal:
            var u = LiquidMetalUniforms(
                shape: intParam("shape", default: 0),
                _pad0: 0,
                repetition: floatParam("repetition", default: 3.0),
                shiftRed: floatParam("shiftRed", default: 0.01),
                shiftBlue: floatParam("shiftBlue", default: 0.01),
                contour: floatParam("contour", default: 0.3),
                softness: floatParam("softness", default: 0.3),
                distortion: floatParam("distortion", default: 0.5),
                angle: floatParam("angle", default: 0),
                _pad1: 0, _pad2: 0, _pad3: 0,
                colorBack: colorParam("colorBack", default: SIMD4<Float>(0, 0, 0, 1)),
                colorTint: colorParam("colorTint", default: SIMD4<Float>(0.8, 0.9, 1, 1))
            )
            encoder.setFragmentBytes(&u, length: MemoryLayout<LiquidMetalUniforms>.stride, index: 1)

        case .gemSmoke:
            var u = GemSmokeUniforms(
                shape: intParam("shape", default: 1),
                colorCount: 0,
                innerDistortion: floatParam("innerDistortion", default: 0.3),
                outerDistortion: floatParam("outerDistortion", default: 0.5),
                outerGlow: floatParam("outerGlow", default: 0.5),
                innerGlow: floatParam("innerGlow", default: 0.5),
                offset: floatParam("offset", default: 0),
                angle: floatParam("angle", default: 0),
                size: floatParam("size", default: 0.5),
                _pad0: 0, _pad1: 0, _pad2: 0,
                colorBack: colorParam("colorBack", default: SIMD4<Float>(0, 0, 0, 1)),
                colorInner: colorParam("colorInner", default: SIMD4<Float>(0.9, 0.7, 1, 1))
            )
            var colors: [SIMD4<Float>] = []
            if let param = layer.params["colors"], case let .colors(vals, _) = param {
                colors = Array(vals.prefix(6))
            }
            if colors.isEmpty { colors = [SIMD4<Float>(0.7, 0.3, 1, 1), SIMD4<Float>(0.3, 0.7, 1, 1)] }
            u.colorCount = Int32(colors.count)
            encoder.setFragmentBytes(&u, length: MemoryLayout<GemSmokeUniforms>.stride, index: 1)
            encoder.setFragmentBytes(&colors, length: MemoryLayout<SIMD4<Float>>.stride * colors.count, index: 2)
        }
    }
}

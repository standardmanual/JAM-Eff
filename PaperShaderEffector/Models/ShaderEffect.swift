import Foundation
import simd

// MARK: - ShaderEffect Enum (29종)

enum ShaderEffect: String, CaseIterable, Identifiable {
    var id: String { rawValue }

    // Image Filters
    case paperTexture       = "Paper Texture"
    case flutedGlass        = "Fluted Glass"
    case water              = "Water"
    case imageDithering     = "Image Dithering"
    case halftoneDots       = "Halftone Dots"
    case halftoneCMYK       = "Halftone CMYK"

    // Effects
    case meshGradient       = "Mesh Gradient"
    case staticMeshGradient = "Static Mesh Gradient"
    case staticRadialGradient = "Static Radial Gradient"
    case dithering          = "Dithering"
    case grainGradient      = "Grain Gradient"
    case dotOrbit           = "Dot Orbit"
    case dotGrid            = "Dot Grid"
    case warp               = "Warp"
    case spiral             = "Spiral"
    case swirl              = "Swirl"
    case waves              = "Waves"
    case neuroNoise         = "Neuro Noise"
    case perlinNoise        = "Perlin Noise"
    case simplexNoise       = "Simplex Noise"
    case voronoi            = "Voronoi"
    case pulsingBorder      = "Pulsing Border"
    case metaballs          = "Metaballs"
    case colorPanels        = "Color Panels"
    case smokeRing          = "Smoke Ring"
    case godRays            = "God Rays"

    // Logo Animations
    case heatmap            = "Heatmap"
    case liquidMetal        = "Liquid Metal"
    case gemSmoke           = "Gem Smoke"

    // MARK: Category

    enum Category: String {
        case imageFilter = "Image Filter"
        case effect      = "Effect"
        case logo        = "Logo"
    }

    var category: Category {
        switch self {
        case .paperTexture, .flutedGlass, .water, .imageDithering, .halftoneDots, .halftoneCMYK:
            return .imageFilter
        case .meshGradient, .staticMeshGradient, .staticRadialGradient, .dithering,
             .grainGradient, .dotOrbit, .dotGrid, .warp, .spiral, .swirl, .waves,
             .neuroNoise, .perlinNoise, .simplexNoise, .voronoi, .pulsingBorder,
             .metaballs, .colorPanels, .smokeRing, .godRays:
            return .effect
        case .heatmap, .liquidMetal, .gemSmoke:
            return .logo
        }
    }

    /// Phase 1 구현 완료 여부
    var isImplemented: Bool {
        switch self {
        case .meshGradient, .waves: return true
        default: return false
        }
    }

    // MARK: Default Parameters Factory

    /// 각 쉐이더의 기본 파라미터 딕셔너리 반환
    func defaultParams() -> [String: ShaderParam] {
        var params: [String: ShaderParam] = commonSizingParams()

        switch self {
        case .meshGradient:
            params["colors"]      = .colors(values: [
                SIMD4<Float>(0.8, 0.4, 0.9, 1),
                SIMD4<Float>(0.3, 0.6, 1.0, 1),
                SIMD4<Float>(0.9, 0.7, 0.3, 1),
                SIMD4<Float>(0.2, 0.9, 0.6, 1)
            ], maxCount: 10)
            params["distortion"]  = .float(value: 0.3, min: 0, max: 1)
            params["swirl"]       = .float(value: 0.2, min: 0, max: 1)
            params["grainMixer"]  = .float(value: 0.1, min: 0, max: 1)
            params["grainOverlay"] = .float(value: 0.05, min: 0, max: 1)

        case .waves:
            params["colorFront"]  = .color(value: SIMD4<Float>(0.1, 0.1, 0.8, 1))
            params["colorBack"]   = .color(value: SIMD4<Float>(0.9, 0.9, 1.0, 1))
            params["shape"]       = .float(value: 1.5, min: 0, max: 3)
            params["frequency"]   = .float(value: 1.0, min: 0, max: 2)
            params["amplitude"]   = .float(value: 0.3, min: 0, max: 1)
            params["spacing"]     = .float(value: 1.0, min: 0, max: 2)
            params["proportion"]  = .float(value: 0.5, min: 0, max: 1)
            params["softness"]    = .float(value: 0.3, min: 0, max: 1)

        case .perlinNoise:
            params["colorFront"]  = .color(value: SIMD4<Float>(0.2, 0.2, 0.7, 1))
            params["colorBack"]   = .color(value: SIMD4<Float>(0.9, 0.9, 0.9, 1))
            params["proportion"]  = .float(value: 0.5, min: 0, max: 1)
            params["softness"]    = .float(value: 0.3, min: 0, max: 1)
            params["octaveCount"] = .float(value: 4, min: 1, max: 8)
            params["persistence"] = .float(value: 0.5, min: 0.3, max: 1)
            params["lacunarity"]  = .float(value: 2.0, min: 1.5, max: 10)

        case .grainGradient:
            params["colorBack"]   = .color(value: SIMD4<Float>(0.1, 0.1, 0.1, 1))
            params["colors"]      = .colors(values: [
                SIMD4<Float>(0.8, 0.5, 0.2, 1),
                SIMD4<Float>(0.2, 0.6, 0.9, 1)
            ], maxCount: 10)
            params["shape"]       = .enumInt(value: 0, options: ["wave","dots","truchet","corners","ripple","blob","sphere"])
            params["softness"]    = .float(value: 0.5, min: 0, max: 1)
            params["intensity"]   = .float(value: 0.7, min: 0, max: 1)
            params["noise"]       = .float(value: 0.3, min: 0, max: 1)

        case .halftoneDots:
            params["colorFront"]    = .color(value: SIMD4<Float>(0, 0, 0, 1))
            params["colorBack"]     = .color(value: SIMD4<Float>(1, 1, 1, 1))
            params["type"]          = .enumInt(value: 0, options: ["classic","gooey","holes","soft"])
            params["grid"]          = .enumInt(value: 0, options: ["square","hex"])
            params["size"]          = .float(value: 0.5, min: 0, max: 1)
            params["radius"]        = .float(value: 1.0, min: 0, max: 2)
            params["contrast"]      = .float(value: 0.5, min: 0, max: 1)
            params["originalColors"] = .bool(value: false)
            params["inverted"]      = .bool(value: false)
            params["grainMixer"]    = .float(value: 0.1, min: 0, max: 1)
            params["grainOverlay"]  = .float(value: 0.05, min: 0, max: 1)
            params["grainSize"]     = .float(value: 0.5, min: 0, max: 1)

        case .pulsingBorder:
            params["colorBack"]     = .color(value: SIMD4<Float>(0, 0, 0, 1))
            params["colors"]        = .colors(values: [
                SIMD4<Float>(0.6, 0.2, 0.9, 1),
                SIMD4<Float>(0.2, 0.5, 1.0, 1)
            ], maxCount: 10)
            params["aspectRatio"]   = .enumInt(value: 0, options: ["auto","square"])
            params["roundness"]     = .float(value: 0.3, min: 0, max: 1)
            params["thickness"]     = .float(value: 0.05, min: 0, max: 1)
            params["margin"]        = .float(value: 0.1, min: 0, max: 1)
            params["softness"]      = .float(value: 0.5, min: 0, max: 1)
            params["intensity"]     = .float(value: 0.8, min: 0, max: 1)
            params["bloom"]         = .float(value: 0.4, min: 0, max: 1)
            params["spots"]         = .float(value: 3, min: 0, max: 10)
            params["spotSize"]      = .float(value: 0.3, min: 0, max: 1)
            params["pulse"]         = .float(value: 0.5, min: 0, max: 1)
            params["smoke"]         = .float(value: 0.3, min: 0, max: 1)
            params["smokeSize"]     = .float(value: 0.5, min: 0, max: 1)

        case .dotOrbit:
            params["colorBack"]     = .color(value: SIMD4<Float>(0, 0, 0, 1))
            params["colors"]        = .colors(values: [
                SIMD4<Float>(1, 0.5, 0.1, 1),
                SIMD4<Float>(0.3, 0.7, 1.0, 1),
                SIMD4<Float>(0.9, 0.2, 0.5, 1)
            ], maxCount: 10)
            params["size"]          = .float(value: 0.5, min: 0, max: 1)
            params["sizeRange"]     = .float(value: 0.3, min: 0, max: 1)
            params["spreading"]     = .float(value: 0.5, min: 0, max: 1)
            params["stepsPerColor"] = .float(value: 3, min: 1, max: 10)

        default:
            break
        }
        return params
    }

    // MARK: Common Sizing Params

    private func commonSizingParams() -> [String: ShaderParam] {
        return [
            "fit":      .enumInt(value: 1, options: ["none","contain","cover"]),
            "scale":    .float(value: 1.0, min: 0.01, max: 4),
            "rotation": .float(value: 0, min: 0, max: 360),
            "originX":  .float(value: 0.5, min: 0, max: 1),
            "originY":  .float(value: 0.5, min: 0, max: 1),
            "offsetX":  .float(value: 0, min: -1, max: 1),
            "offsetY":  .float(value: 0, min: -1, max: 1)
        ]
    }

    // MARK: Parameter Grouping

    /// 색상 파라미터 키 목록 (파라미터 패널 "색상" 섹션)
    var colorParamKeys: [String] {
        defaultParams().keys.filter { key in
            let param = defaultParams()[key]!
            if case .color = param { return true }
            if case .colors = param { return true }
            return false
        }.sorted()
    }

    /// float/bool/enum 파라미터 키 목록 (파라미터 패널 "조절" 섹션)
    var adjustParamKeys: [String] {
        let layoutKeys = Set(["fit","scale","rotation","originX","originY","offsetX","offsetY"])
        return defaultParams().keys.filter { key in
            if layoutKeys.contains(key) { return false }
            let param = defaultParams()[key]!
            switch param {
            case .float, .bool, .enumInt: return true
            default: return false
            }
        }.sorted()
    }

    /// 공통 레이아웃 파라미터 키
    var layoutParamKeys: [String] {
        ["fit","scale","rotation","originX","originY","offsetX","offsetY"]
    }
}

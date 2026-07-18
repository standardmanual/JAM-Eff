import Foundation
import UIKit
import simd

// MARK: - LayerBlendMode

enum LayerBlendMode: Int32, CaseIterable {
    case normal     = 0
    case multiply   = 1
    case screen     = 2
    case overlay    = 3
    case softLight  = 4
    case hardLight  = 5
    case colorDodge = 6
    case colorBurn  = 7
    case darken     = 8
    case lighten    = 9
    case difference = 10
    case exclusion  = 11

    var displayName: String {
        switch self {
        case .normal:     return "Normal"
        case .multiply:   return "Multiply"
        case .screen:     return "Screen"
        case .overlay:    return "Overlay"
        case .softLight:  return "Soft Light"
        case .hardLight:  return "Hard Light"
        case .colorDodge: return "Color Dodge"
        case .colorBurn:  return "Color Burn"
        case .darken:     return "Darken"
        case .lighten:    return "Lighten"
        case .difference: return "Difference"
        case .exclusion:  return "Exclusion"
        }
    }
}

// MARK: - ShaderParam

enum ShaderParam {
    case float(value: Float, min: Float, max: Float)
    case color(value: SIMD4<Float>)
    case colors(values: [SIMD4<Float>], maxCount: Int)
    case bool(value: Bool)
    case enumInt(value: Int, options: [String])
}

// MARK: - LayerKind

enum LayerKind {
    case shader(ShaderEffect)
    case image(UIImage)
}

// MARK: - ShaderLayer

struct ShaderLayer: Identifiable {
    var id: UUID = UUID()
    var kind: LayerKind
    var params: [String: ShaderParam]
    var opacity: Float = 1.0
    var blendMode: LayerBlendMode = .normal
    var isEnabled: Bool = true
    var imageTransform: PhotoTransform = .identity

    // MARK: Computed helpers

    var effectType: ShaderEffect? {
        if case .shader(let e) = kind { return e }
        return nil
    }

    var isImageLayer: Bool {
        if case .image = kind { return true }
        return false
    }

    var uiImage: UIImage? {
        if case .image(let img) = kind { return img }
        return nil
    }

    // MARK: Init

    init(effectType: ShaderEffect) {
        self.kind = .shader(effectType)
        self.params = effectType.defaultParams()
    }

    init(image: UIImage) {
        self.kind = .image(image)
        self.params = [:]
    }
}

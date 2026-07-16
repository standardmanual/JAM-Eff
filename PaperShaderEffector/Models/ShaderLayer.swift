import Foundation
import simd

// MARK: - ShaderParam

enum ShaderParam {
    case float(value: Float, min: Float, max: Float)
    case color(value: SIMD4<Float>)
    case colors(values: [SIMD4<Float>], maxCount: Int)
    case bool(value: Bool)
    case enumInt(value: Int, options: [String])
}

// MARK: - ShaderLayer

struct ShaderLayer: Identifiable {
    var id: UUID = UUID()
    var effectType: ShaderEffect
    var params: [String: ShaderParam]
    var opacity: Float = 1.0
    var isEnabled: Bool = true

    init(effectType: ShaderEffect) {
        self.effectType = effectType
        self.params = effectType.defaultParams()
    }
}

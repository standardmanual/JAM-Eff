import Foundation
import UIKit
import simd

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

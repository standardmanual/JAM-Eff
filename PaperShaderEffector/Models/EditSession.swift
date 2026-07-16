import Foundation
import UIKit
import Metal
import Combine

// MARK: - SourcePhoto

struct SourcePhoto {
    var image: UIImage
    var originalSize: CGSize
    var texture: MTLTexture?

    init(image: UIImage) {
        self.image = image
        self.originalSize = image.size
        self.texture = nil
    }
}

// MARK: - EditSession

@MainActor
final class EditSession: ObservableObject {
    @Published var sourcePhoto: SourcePhoto?
    @Published var shaderStack: [ShaderLayer] = []
    @Published var selectedLayerIndex: Int = 0
    @Published var exportSpec: ExportSpec = ExportSpec()
    @Published var showToast: Bool = false
    @Published var toastMessage: String = ""

    // MARK: - Layer Management

    func addLayer(_ effect: ShaderEffect) {
        let layer = ShaderLayer(effectType: effect)
        shaderStack.append(layer)
        selectedLayerIndex = shaderStack.count - 1
    }

    func removeLayer(at index: Int) {
        guard shaderStack.indices.contains(index) else { return }
        shaderStack.remove(at: index)
        if selectedLayerIndex >= shaderStack.count {
            selectedLayerIndex = max(0, shaderStack.count - 1)
        }
    }

    func moveLayer(from source: IndexSet, to destination: Int) {
        shaderStack.move(fromOffsets: source, toOffset: destination)
    }

    var selectedLayer: ShaderLayer? {
        guard shaderStack.indices.contains(selectedLayerIndex) else { return nil }
        return shaderStack[selectedLayerIndex]
    }

    func updateParam(_ key: String, value: ShaderParam, layerIndex: Int? = nil) {
        let idx = layerIndex ?? selectedLayerIndex
        guard shaderStack.indices.contains(idx) else { return }
        shaderStack[idx].params[key] = value
    }

    // MARK: - Toast

    func showToastMessage(_ message: String) {
        toastMessage = message
        showToast = true
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            showToast = false
        }
    }
}

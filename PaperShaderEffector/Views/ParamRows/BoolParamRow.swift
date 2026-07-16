import SwiftUI

// MARK: - BoolParamRow (높이 44pt)

struct BoolParamRow: View {
    let name: String
    let paramKey: String
    @Binding var layer: ShaderLayer

    var body: some View {
        if case let .bool(val) = layer.params[paramKey] {
            let binding = Binding<Bool>(
                get: { val },
                set: { newVal in layer.params[paramKey] = .bool(value: newVal) }
            )
            Toggle(isOn: binding) {
                Text(name)
                    .font(.system(size: 16))
            }
            .frame(height: 44)
            .padding(.horizontal, 16)
        }
    }
}

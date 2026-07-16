import SwiftUI

// MARK: - EnumParamRow (Picker: segmented ≤3, menu ≥4, 높이 44pt)

struct EnumParamRow: View {
    let name: String
    let paramKey: String
    @Binding var layer: ShaderLayer

    var body: some View {
        if case let .enumInt(val, options) = layer.params[paramKey] {
            let binding = Binding<Int>(
                get: { val },
                set: { newVal in layer.params[paramKey] = .enumInt(value: newVal, options: options) }
            )
            HStack {
                Text(name)
                    .font(.system(size: 16))
                    .frame(maxWidth: .infinity, alignment: .leading)

                if options.count <= 3 {
                    Picker(name, selection: binding) {
                        ForEach(options.indices, id: \.self) { idx in
                            Text(options[idx]).tag(idx)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 200)
                } else {
                    Picker(name, selection: binding) {
                        ForEach(options.indices, id: \.self) { idx in
                            Text(options[idx]).tag(idx)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .frame(height: 44)
            .padding(.horizontal, 16)
        }
    }
}

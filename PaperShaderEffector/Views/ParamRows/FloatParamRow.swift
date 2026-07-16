import SwiftUI

// MARK: - FloatParamRow (높이 52pt)

struct FloatParamRow: View {
    let name: String
    let minValue: Float
    let maxValue: Float
    @Binding var value: Float

    var body: some View {
        HStack(spacing: 8) {
            Text(name)
                .font(.system(size: 16))
                .frame(width: 100, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Slider(value: $value, in: Double(minValue)...Double(maxValue))
                .tint(.blue)

            Text(String(format: "%.2f", value))
                .font(.system(size: 15, design: .monospaced))
                .frame(width: 44, alignment: .trailing)
                .foregroundStyle(Color.secondary)
        }
        .frame(height: 52)
        .padding(.horizontal, 16)
    }
}

// MARK: - Bound to ShaderLayer param

struct FloatParamRowBound: View {
    let name: String
    let paramKey: String
    @Binding var layer: ShaderLayer

    var body: some View {
        if case let .float(val, minV, maxV) = layer.params[paramKey] {
            let binding = Binding<Float>(
                get: { val },
                set: { newVal in
                    layer.params[paramKey] = .float(value: newVal, min: minV, max: maxV)
                }
            )
            FloatParamRow(name: name, minValue: minV, maxValue: maxV, value: binding)
        }
    }
}

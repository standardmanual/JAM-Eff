import SwiftUI

// MARK: - ColorParamRow (높이 52pt)

struct ColorParamRow: View {
    let name: String
    let paramKey: String
    @Binding var layer: ShaderLayer

    var body: some View {
        if case let .color(simd) = layer.params[paramKey] {
            let binding = Binding<Color>(
                get: { Color(red: Double(simd.x), green: Double(simd.y), blue: Double(simd.z), opacity: Double(simd.w)) },
                set: { newColor in
                    let resolved = newColor.resolve(in: EnvironmentValues())
                    layer.params[paramKey] = .color(value: SIMD4<Float>(
                        Float(resolved.red),
                        Float(resolved.green),
                        Float(resolved.blue),
                        Float(resolved.opacity)
                    ))
                }
            )
            HStack {
                Text(name)
                    .font(.system(size: 16))
                    .lineLimit(1)
                Spacer()
                ColorPicker("", selection: binding)
                    .labelsHidden()
                    .frame(width: 44, height: 44)
            }
            .frame(height: 52)
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - ColorsParamRow (color[] 배열)

struct ColorsParamRow: View {
    let name: String
    let paramKey: String
    @Binding var layer: ShaderLayer

    var body: some View {
        if case let .colors(values, maxCount) = layer.params[paramKey] {
            VStack(alignment: .leading, spacing: 8) {
                Text(name)
                    .font(.system(size: 16))
                    .padding(.horizontal, 16)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(values.indices, id: \.self) { idx in
                            colorSwatch(values: values, idx: idx, maxCount: maxCount)
                        }
                        if values.count < maxCount {
                            addColorButton(values: values, maxCount: maxCount)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 8)
        }
    }

    @ViewBuilder
    private func colorSwatch(values: [SIMD4<Float>], idx: Int, maxCount: Int) -> some View {
        let simd = values[idx]
        let color = Color(red: Double(simd.x), green: Double(simd.y), blue: Double(simd.z))
        let binding = Binding<Color>(
            get: { color },
            set: { newColor in
                let resolved = newColor.resolve(in: EnvironmentValues())
                var newValues = values
                newValues[idx] = SIMD4<Float>(Float(resolved.red), Float(resolved.green), Float(resolved.blue), Float(resolved.opacity))
                layer.params[paramKey] = .colors(values: newValues, maxCount: maxCount)
            }
        )
        ZStack {
            Circle().fill(color).frame(width: 32, height: 32)
            ColorPicker("", selection: binding)
                .labelsHidden()
                .opacity(0.015)
                .frame(width: 32, height: 32)
        }
        .overlay(
            Circle().stroke(Color.secondary.opacity(0.4), lineWidth: 1)
        )
        .onLongPressGesture {
            if values.count > 1 {
                var newValues = values
                newValues.remove(at: idx)
                layer.params[paramKey] = .colors(values: newValues, maxCount: maxCount)
            }
        }
    }

    @ViewBuilder
    private func addColorButton(values: [SIMD4<Float>], maxCount: Int) -> some View {
        Button {
            var newValues = values
            newValues.append(SIMD4<Float>(0.5, 0.5, 0.5, 1.0))
            layer.params[paramKey] = .colors(values: newValues, maxCount: maxCount)
        } label: {
            Circle()
                .strokeBorder(Color.secondary.opacity(0.5), style: StrokeStyle(lineWidth: 1.5, dash: [3]))
                .frame(width: 32, height: 32)
                .overlay(Image(systemName: "plus").font(.system(size: 11)).foregroundStyle(Color.secondary))
        }
        .buttonStyle(.plain)
        .frame(width: 44, height: 44)
        .contentShape(Rectangle())
    }
}

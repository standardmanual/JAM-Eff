import SwiftUI

// MARK: - RatioToggle (4:5 / 9:16 Pill)

struct RatioToggle: View {
    @Binding var ratio: ExportSpec.OutputRatio

    var body: some View {
        HStack(spacing: 0) {
            ratioButton(.fourFive)
            ratioButton(.nineSixteen)
        }
        .background(.thinMaterial)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 0.5))
    }

    @ViewBuilder
    private func ratioButton(_ r: ExportSpec.OutputRatio) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                ratio = r
            }
        } label: {
            Text(r.rawValue)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(ratio == r ? Color.primary : Color.secondary)
                .frame(minWidth: 44, minHeight: 32)
                .padding(.horizontal, 10)
                .background(
                    ratio == r
                        ? Color.white.opacity(0.6)
                        : Color.clear
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    @Previewable @State var ratio: ExportSpec.OutputRatio = .fourFive
    RatioToggle(ratio: $ratio)
        .padding()
}

import SwiftUI

// MARK: - LayerChip (80×80pt)

struct LayerChip: View {
    let layer: ShaderLayer
    let isSelected: Bool
    let onTap: () -> Void
    let onToggle: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Thumbnail area (top 4/5 = 64pt)
            ZStack(alignment: .topTrailing) {
                ShaderThumbnailView(effect: layer.effectType, cornerRadius: 8)
                    .frame(height: 64)

                // Enable/disable badge
                Button(action: onToggle) {
                    Image(systemName: layer.isEnabled ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 14))
                        .foregroundStyle(layer.isEnabled ? Color.blue : Color.white.opacity(0.7))
                        .background(Circle().fill(.ultraThinMaterial).frame(width: 18, height: 18))
                }
                .buttonStyle(.plain)
                .frame(width: 44, height: 44) // expanded touch target
                .contentShape(Rectangle())
                .offset(x: 4, y: -4)
            }

            // Label area (bottom 1/5 = 16pt)
            Text(layer.effectType.rawValue)
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundStyle(Color.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 16)
                .padding(.horizontal, 2)
        }
        .frame(width: 80, height: 80)
        .opacity(layer.isEnabled ? 1.0 : 0.4)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
        .onTapGesture(perform: onTap)
    }
}

// MARK: - Add Layer Chip

struct AddLayerChip: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color.secondary)
                Text("추가")
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
            }
            .frame(width: 80, height: 80)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.secondary.opacity(0.5), style: StrokeStyle(lineWidth: 1.5, dash: [4]))
            )
        }
        .buttonStyle(.plain)
    }
}

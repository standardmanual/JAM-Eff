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
                thumbnail
                    .frame(height: 64)

                // Enable/disable badge
                Button(action: onToggle) {
                    Image(systemName: layer.isEnabled ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 14))
                        .foregroundStyle(layer.isEnabled ? Color.blue : Color.white.opacity(0.7))
                        .background(Circle().fill(.ultraThinMaterial).frame(width: 18, height: 18))
                }
                .buttonStyle(.plain)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .offset(x: 4, y: -4)
            }

            // Label area (bottom 1/5 = 16pt)
            Text(chipLabel)
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

    @ViewBuilder
    private var thumbnail: some View {
        if let img = layer.uiImage {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: 64)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else if let effect = layer.effectType {
            ShaderThumbnailView(effect: effect, cornerRadius: 8)
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.3))
        }
    }

    private var chipLabel: String {
        if layer.isImageLayer { return "사진" }
        return layer.effectType?.rawValue ?? ""
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

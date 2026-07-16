import SwiftUI

// MARK: - LayerTrayView (Zone 3, 96pt)

struct LayerTrayView: View {
    @EnvironmentObject var session: EditSession
    @Binding var showAddShaderSheet: Bool

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 8) {
                ForEach(session.shaderStack.indices, id: \.self) { idx in
                    LayerChip(
                        layer: session.shaderStack[idx],
                        isSelected: session.selectedLayerIndex == idx,
                        onTap: {
                            let haptic = UIImpactFeedbackGenerator(style: .soft)
                            haptic.impactOccurred()
                            session.selectedLayerIndex = idx
                        },
                        onToggle: {
                            session.shaderStack[idx].isEnabled.toggle()
                        }
                    )
                    .contextMenu {
                        Button(role: .destructive) {
                            session.removeLayer(at: idx)
                        } label: {
                            Label("삭제", systemImage: "trash")
                        }
                    }
                }

                AddLayerChip {
                    showAddShaderSheet = true
                }
            }
            .padding(.horizontal, 8)
        }
        .frame(height: 96)
        .background(.regularMaterial)
        .overlay(alignment: .top) {
            Divider()
        }
    }
}

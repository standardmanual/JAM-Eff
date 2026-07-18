import SwiftUI
import UniformTypeIdentifiers

// MARK: - LayerTrayView (Zone 3, 96pt)

struct LayerTrayView: View {
    @EnvironmentObject var session: EditSession
    @Binding var showAddShaderSheet: Bool
    @State private var draggingIndex: Int? = nil

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
                    .opacity(draggingIndex == idx ? 0.45 : 1.0)
                    .scaleEffect(draggingIndex == idx ? 0.92 : 1.0)
                    .animation(.easeInOut(duration: 0.15), value: draggingIndex)
                    .onDrag {
                        draggingIndex = idx
                        let haptic = UIImpactFeedbackGenerator(style: .rigid)
                        haptic.impactOccurred()
                        return NSItemProvider(object: String(idx) as NSString)
                    }
                    .onDrop(
                        of: [UTType.plainText],
                        delegate: LayerDropDelegate(session: session, targetIndex: idx, draggingIndex: $draggingIndex)
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

// MARK: - LayerDropDelegate

private struct LayerDropDelegate: DropDelegate {
    let session: EditSession
    let targetIndex: Int
    @Binding var draggingIndex: Int?

    func performDrop(info: DropInfo) -> Bool {
        draggingIndex = nil
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let from = draggingIndex, from != targetIndex else { return }
        let sel = session.selectedLayerIndex
        withAnimation(.easeInOut(duration: 0.2)) {
            session.shaderStack.move(
                fromOffsets: IndexSet(integer: from),
                toOffset: targetIndex > from ? targetIndex + 1 : targetIndex
            )
        }
        // Keep selectedLayerIndex tracking the same layer
        if sel == from {
            session.selectedLayerIndex = targetIndex
        } else if from < targetIndex, sel > from, sel <= targetIndex {
            session.selectedLayerIndex = sel - 1
        } else if from > targetIndex, sel >= targetIndex, sel < from {
            session.selectedLayerIndex = sel + 1
        }
        draggingIndex = targetIndex
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}

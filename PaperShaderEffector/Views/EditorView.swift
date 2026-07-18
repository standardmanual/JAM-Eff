import SwiftUI
import MetalKit

// MARK: - EditorLayout Constants

enum EditorLayout {
    static let navBarHeight: CGFloat      = 44
    static let previewZoneHeight: CGFloat = 320
    static let layerTrayHeight: CGFloat   = 96
}

// MARK: - EditorView (4-Zone Layout)

struct EditorView: View {
    @EnvironmentObject var session: EditSession
    @Environment(\.dismiss) private var dismiss

    @State private var renderer: Renderer?
    @State private var showAddShaderSheet: Bool = false
    @State private var isEditingMode: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Zone 1: Navigation Bar (44pt)
            navigationBar

            if let renderer {
                if isEditingMode {
                    // Edit mode: preview fills remaining space, gestures active
                    PreviewZoneView(renderer: renderer, isEditingMode: true)
                        .environmentObject(session)
                        .frame(maxHeight: .infinity)
                } else {
                    // Normal mode: 320pt preview, gestures disabled
                    PreviewZoneView(renderer: renderer, isEditingMode: false)
                        .environmentObject(session)

                    // Zone 3: Layer Tray (96pt)
                    LayerTrayView(showAddShaderSheet: $showAddShaderSheet)
                        .environmentObject(session)

                    // Zone 4: Parameter Panel (remaining)
                    ParamPanelView()
                        .environmentObject(session)
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.light)
        .animation(.easeInOut(duration: 0.25), value: isEditingMode)
        .toast(isPresented: $session.showToast, message: session.toastMessage)
        .sheet(isPresented: $showAddShaderSheet) {
            AddShaderSheet(isPresented: $showAddShaderSheet)
                .environmentObject(session)
        }
        .task {
            await setupRenderer()
        }
    }

    // MARK: - Zone 1: Navigation Bar

    private var navigationBar: some View {
        HStack {
            if !isEditingMode {
                Button { dismiss() } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                        Text("뒤로")
                            .font(.system(size: 16))
                    }
                    .foregroundStyle(Color.primary)
                }
                .buttonStyle(.plain)
                .frame(minWidth: 44, minHeight: 44)
            } else {
                // 편집 모드에서는 왼쪽 공간만 확보
                Spacer().frame(width: 44)
            }

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isEditingMode.toggle()
                }
            } label: {
                Text(isEditingMode ? "완료" : "편집")
                    .font(.system(size: 16, weight: isEditingMode ? .semibold : .regular))
                    .foregroundStyle(Color.blue)
            }
            .buttonStyle(.plain)
            .frame(minWidth: 44, minHeight: 44)
        }
        .padding(.horizontal, 12)
        .frame(height: EditorLayout.navBarHeight)
        .background(.regularMaterial)
    }

    // MARK: - Setup

    private func setupRenderer() async {
        let mtkView = MTKView()
        if let r = Renderer(mtkView: mtkView) {
            renderer = r
        }
    }
}

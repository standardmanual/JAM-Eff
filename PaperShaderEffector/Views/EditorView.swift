import SwiftUI
import MetalKit

// MARK: - EditorLayout Constants

enum EditorLayout {
    static let navBarHeight: CGFloat    = 44
    static let previewZoneHeight: CGFloat = 320
    static let layerTrayHeight: CGFloat = 96
}

// MARK: - EditorView (4-Zone Layout)

struct EditorView: View {
    @EnvironmentObject var session: EditSession
    @Environment(\.dismiss) private var dismiss

    @State private var renderer: Renderer?
    @State private var showAddShaderSheet: Bool = false
    @State private var isSaving: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Zone 1: Navigation Bar (44pt)
            navigationBar

            if let renderer {
                // Zone 2: Preview (320pt)
                PreviewZoneView(renderer: renderer)
                    .environmentObject(session)

                // Zone 3: Layer Tray (96pt)
                LayerTrayView(showAddShaderSheet: $showAddShaderSheet)
                    .environmentObject(session)

                // Zone 4: Parameter Panel (remaining)
                ParamPanelView()
                    .environmentObject(session)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.light)
        .toast(isPresented: $session.showToast, message: session.toastMessage)
        .sheet(isPresented: $showAddShaderSheet) {
            AddShaderSheet(isPresented: $showAddShaderSheet)
                .environmentObject(session)
        }
        .task {
            await setupRenderer()
            // Add default layer if stack is empty
            if session.shaderStack.isEmpty {
                session.addLayer(.meshGradient)
            }
        }
    }

    // MARK: - Zone 1: Navigation Bar

    private var navigationBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
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

            Spacer()

            Text("편집")
                .font(.system(size: 17, weight: .semibold))

            Spacer()

            Button {
                Task { await saveImage() }
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.blue)
            }
            .buttonStyle(.plain)
            .frame(minWidth: 44, minHeight: 44)
            .disabled(isSaving)
            .overlay {
                if isSaving {
                    ProgressView().scaleEffect(0.7)
                }
            }
        }
        .padding(.horizontal, 12)
        .frame(height: EditorLayout.navBarHeight)
        .background(.regularMaterial)
    }

    // MARK: - Setup

    private func setupRenderer() async {
        // MTKView must be created for Renderer.init — we use a temporary view
        let mtkView = MTKView()
        if let r = Renderer(mtkView: mtkView) {
            // Load source texture if available
            if let photo = session.sourcePhoto {
                r.sourceTexture = TextureUtils.texture(from: photo.image, device: r.device)
            }
            renderer = r
        }
    }

    // MARK: - Save

    private func saveImage() async {
        guard let renderer else { return }
        isSaving = true
        do {
            try await ImageExporter.exportToPhotoLibrary(renderer: renderer, exportSpec: session.exportSpec)
            let haptic = UINotificationFeedbackGenerator()
            haptic.notificationOccurred(.success)
            session.showToastMessage("카메라롤에 저장됨")
        } catch {
            let haptic = UINotificationFeedbackGenerator()
            haptic.notificationOccurred(.error)
            session.showToastMessage("저장 실패: \(error.localizedDescription)")
        }
        isSaving = false
    }
}

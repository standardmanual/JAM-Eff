import SwiftUI
import MetalKit
import PhotosUI

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
    @State private var isSaving: Bool = false
    @State private var photoPickerItem: PhotosPickerItem? = nil

    @StateObject private var videoExporter = VideoExporter()
    @State private var exportTask: Task<Void, Never>? = nil

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
        }
        .overlay {
            if videoExporter.isExporting {
                ExportProgressView(
                    progress: videoExporter.progress,
                    onCancel: {
                        exportTask?.cancel()
                        videoExporter.isExporting = false
                    }
                )
            }
        }
        .onChange(of: photoPickerItem) { _, newItem in
            Task {
                guard let newItem else { return }
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    session.addImageLayer(image)
                }
                photoPickerItem = nil
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

            PhotosPicker(selection: $photoPickerItem, matching: .images) {
                Image(systemName: "photo.badge.plus")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.secondary)
            }
            .buttonStyle(.plain)
            .frame(minWidth: 44, minHeight: 44)

            Button {
                startVideoExport()
            } label: {
                Image(systemName: "video.badge.plus")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.blue)
            }
            .buttonStyle(.plain)
            .frame(minWidth: 44, minHeight: 44)
            .disabled(videoExporter.isExporting || session.shaderStack.isEmpty)

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
        let mtkView = MTKView()
        if let r = Renderer(mtkView: mtkView) {
            renderer = r
        }
    }

    // MARK: - Save

    private func saveImage() async {
        guard let renderer else { return }
        isSaving = true
        do {
            try await ImageExporter.exportToPhotoLibrary(renderer: renderer, exportSpec: session.exportSpec)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            session.showToastMessage("카메라롤에 저장됨")
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            session.showToastMessage("저장 실패: \(error.localizedDescription)")
        }
        isSaving = false
    }

    // MARK: - Video Export

    private func startVideoExport() {
        guard let device = MTLCreateSystemDefaultDevice() else { return }
        exportTask = Task {
            do {
                try await videoExporter.export(
                    session: session,
                    device: device,
                    pipeline: ShaderPipeline.shared
                )
                session.showToastMessage("동영상이 저장됐어요!")
            } catch {
                session.showToastMessage("저장 실패: \(error.localizedDescription)")
            }
        }
    }
}

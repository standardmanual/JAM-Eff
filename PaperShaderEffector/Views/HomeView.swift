import SwiftUI
import PhotosUI

// MARK: - HomeView (PhotosPicker 전체화면)

struct HomeView: View {
    @EnvironmentObject var session: EditSession
    @State private var selectedItem: PhotosPickerItem?
    @State private var isLoading: Bool = false
    @State private var navigateToEditor: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color(red: 0.95, green: 0.92, blue: 1.0), Color(red: 0.88, green: 0.95, blue: 1.0)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 32) {
                    Spacer()

                    // App icon / title
                    VStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                        Text("Paper Shader")
                            .font(.system(size: 28, weight: .bold))
                        Text("사진에 쉐이더 효과를 적용해보세요")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.secondary)
                    }

                    Spacer()

                    // Photo Picker Button
                    PhotosPicker(
                        selection: $selectedItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        HStack(spacing: 8) {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 18))
                            Text("사진 선택")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 32)
                    }
                    .onChange(of: selectedItem) { _, newItem in
                        Task { await loadPhoto(newItem) }
                    }

                    // Skip with default (no photo — start with gradient only)
                    Button {
                        session.sourcePhoto = nil
                        navigateToEditor = true
                    } label: {
                        Text("사진 없이 시작")
                            .font(.system(size: 15))
                            .foregroundStyle(Color.secondary)
                    }
                    .frame(height: 44)

                    Spacer()
                        .frame(height: 40)
                }

                if isLoading {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    ProgressView("불러오는 중...")
                        .padding(24)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .navigationDestination(isPresented: $navigateToEditor) {
                EditorView()
                    .environmentObject(session)
            }
        }
        .preferredColorScheme(.light)
    }

    private func loadPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        isLoading = true
        defer { isLoading = false }

        if let data = try? await item.loadTransferable(type: Data.self),
           let uiImage = UIImage(data: data) {
            session.sourcePhoto = SourcePhoto(image: uiImage)
            navigateToEditor = true
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(EditSession())
}

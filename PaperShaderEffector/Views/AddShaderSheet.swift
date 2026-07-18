import SwiftUI
import PhotosUI

// MARK: - AddShaderSheet (Bottom Sheet — 3열 그리드)

struct AddShaderSheet: View {
    @EnvironmentObject var session: EditSession
    @Binding var isPresented: Bool
    @State private var searchText: String = ""
    @State private var photoItem: PhotosPickerItem? = nil

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var filteredEffects: [ShaderEffect] {
        let implemented = ShaderEffect.allCases.filter { $0.isImplemented }
        if searchText.isEmpty { return implemented }
        return implemented.filter {
            $0.rawValue.localizedCaseInsensitiveContains(searchText) ||
            $0.category.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Photo / PNG layer option
                photoSection
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 4)

                Divider()
                    .padding(.vertical, 4)

                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Color.secondary)
                    TextField("쉐이더 검색", text: $searchText)
                        .font(.system(size: 16))
                        .autocorrectionDisabled()
                }
                .padding(.horizontal, 12)
                .frame(height: 44)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(filteredEffects) { effect in
                            ShaderGridCell(effect: effect) {
                                session.addLayer(effect)
                                let haptic = UIImpactFeedbackGenerator(style: .medium)
                                haptic.impactOccurred()
                                isPresented = false
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("레이어 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") { isPresented = false }
                        .font(.system(size: 16))
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onChange(of: photoItem) { _, newItem in
            Task {
                guard let newItem else { return }
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    session.addImageLayer(image)
                    let haptic = UIImpactFeedbackGenerator(style: .medium)
                    haptic.impactOccurred()
                    isPresented = false
                }
            }
        }
    }

    // MARK: - Photo Section

    private var photoSection: some View {
        PhotosPicker(selection: $photoItem, matching: .images) {
            HStack(spacing: 12) {
                Image(systemName: "photo.badge.plus")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.blue)
                    .frame(width: 44, height: 44)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text("사진/PNG 추가")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.primary)
                    Text("새 이미지 레이어로 스택에 추가")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - ShaderGridCell

struct ShaderGridCell: View {
    let effect: ShaderEffect
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 4) {
                ShaderThumbnailView(effect: effect, cornerRadius: 8)
                    .aspectRatio(1, contentMode: .fit)

                Text(effect.rawValue)
                    .font(.system(size: 13))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.primary)

                Text(effect.category.rawValue)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

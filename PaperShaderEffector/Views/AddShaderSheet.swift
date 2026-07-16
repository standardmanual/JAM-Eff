import SwiftUI

// MARK: - AddShaderSheet (Bottom Sheet — 3열 그리드)

struct AddShaderSheet: View {
    @EnvironmentObject var session: EditSession
    @Binding var isPresented: Bool
    @State private var searchText: String = ""

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var filteredEffects: [ShaderEffect] {
        if searchText.isEmpty { return ShaderEffect.allCases }
        return ShaderEffect.allCases.filter {
            $0.rawValue.localizedCaseInsensitiveContains(searchText) ||
            $0.category.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
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
            .navigationTitle("쉐이더 추가")
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
    }
}

// MARK: - ShaderGridCell

struct ShaderGridCell: View {
    let effect: ShaderEffect
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 4) {
                // Thumbnail placeholder
                RoundedRectangle(cornerRadius: 8)
                    .fill(thumbnailGradient)
                    .overlay(
                        effect.isImplemented
                            ? AnyView(EmptyView())
                            : AnyView(
                                Text("준비 중")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.white.opacity(0.8))
                                    .padding(4)
                                    .background(Color.black.opacity(0.4))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            )
                    )
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
        .opacity(effect.isImplemented ? 1.0 : 0.6)
    }

    private var thumbnailGradient: LinearGradient {
        switch effect.category {
        case .imageFilter:
            return LinearGradient(colors: [.orange.opacity(0.7), .pink.opacity(0.7)],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        case .effect:
            return LinearGradient(colors: [.blue.opacity(0.7), .purple.opacity(0.7)],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        case .logo:
            return LinearGradient(colors: [.teal.opacity(0.7), .green.opacity(0.7)],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

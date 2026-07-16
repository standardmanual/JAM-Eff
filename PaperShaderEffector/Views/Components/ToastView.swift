import SwiftUI

// MARK: - ToastView

struct ToastView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.regularMaterial)
            .background(Color.black.opacity(0.7))
            .clipShape(Capsule())
    }
}

// MARK: - Toast Modifier

struct ToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String

    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            content
            if isPresented {
                ToastView(message: message)
                    .padding(.bottom, 60)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(duration: 0.4), value: isPresented)
                    .zIndex(999)
            }
        }
    }
}

extension View {
    func toast(isPresented: Binding<Bool>, message: String) -> some View {
        modifier(ToastModifier(isPresented: isPresented, message: message))
    }
}

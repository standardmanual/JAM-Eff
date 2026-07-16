import SwiftUI

// MARK: - ContentView (앱 루트)

struct ContentView: View {
    @StateObject private var session = EditSession()

    var body: some View {
        HomeView()
            .environmentObject(session)
            .preferredColorScheme(.light)
    }
}

#Preview {
    ContentView()
}

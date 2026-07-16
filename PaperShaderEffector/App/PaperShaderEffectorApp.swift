import SwiftUI

@main
struct PaperShaderEffectorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)  // 라이트 모드 고정
        }
    }
}

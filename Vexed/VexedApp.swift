import SwiftUI

@main
struct VexedApp: App {
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                GameView()

                if showSplash {
                    SplashView {
                        withAnimation(.easeIn(duration: 0.2)) {
                            showSplash = false
                        }
                    }
                    .zIndex(100)
                }
            }
        }
    }
}

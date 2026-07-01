import SwiftUI

@main
struct VexedApp: App {
    @State private var showSplash = true
    @AppStorage("selectedDifficulty") private var savedDifficultyRaw: String = Difficulty.easy.rawValue

    var body: some Scene {
        WindowGroup {
            let difficulty = Difficulty(rawValue: savedDifficultyRaw) ?? .easy
            ZStack {
                GameView(initialDifficulty: difficulty, onResetAll: {
                    withAnimation(.easeOut(duration: 0.2)) { showSplash = true }
                })

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

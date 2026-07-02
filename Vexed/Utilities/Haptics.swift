import UIKit

enum Haptics {
    static func light()   { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func medium()  { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
    static func rigid()   { UIImpactFeedbackGenerator(style: .rigid).impactOccurred() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func warning() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }

    /// Double-punch used for word scored: heavy thud then notification success 80ms later.
    static func wordScore() {
        let heavy = UIImpactFeedbackGenerator(style: .heavy)
        heavy.prepare()
        heavy.impactOccurred(intensity: 1.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    /// Word-scored haptic that escalates with combo streak — combo 1 is the normal double-punch;
    /// combo 2/3 add extra staccato taps; combo 4+ adds a fast triple-tap flourish.
    static func comboScore(combo: Int) {
        wordScore()
        guard combo >= 2 else { return }
        let extraTaps = min(combo - 1, 3)
        for i in 0..<extraTaps {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.16 + Double(i) * 0.09) {
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.85)
            }
        }
    }

    /// Tile Forge reveal — a light tap for one tile, escalating to a success chime for a big drop.
    static func forge(count: Int) {
        if count >= 3 {
            let heavy = UIImpactFeedbackGenerator(style: .medium)
            heavy.prepare()
            heavy.impactOccurred(intensity: 0.9)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        } else {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}

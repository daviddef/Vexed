import AVFoundation

/// Reads a formed word aloud in Kid Mode — the mascot "saying" the word back reinforces the
/// spelling mechanic itself rather than just decorating the celebration with generic effects.
enum KidVoice {
    private static let synthesizer = AVSpeechSynthesizer()

    static func say(_ word: String) {
        guard UserDefaults.standard.bool(forKey: "kidMode") else { return }
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: word)
        utterance.rate = 0.42
        utterance.pitchMultiplier = 1.25
        utterance.voice = AVSpeechSynthesisVoice(language: AVSpeechSynthesisVoice.currentLanguageCode())
        synthesizer.speak(utterance)
    }
}

import Foundation

/// Fetches a short plain-text definition for the word preview overlay. Deliberately NOT using
/// UIReferenceLibraryViewController here — that's a WebView-backed UIKit controller that isn't
/// safe to embed inline in a small, transparent, non-blocking overlay (see GameView.swift comment
/// on wordPreviewOverlay for the crash that caused this). A plain-text network lookup lets the
/// definition render as ordinary SwiftUI Text instead, so it can sit in a transparent overlay
/// without interrupting gameplay.
enum DictionaryAPI {
    private static var cache: [String: String?] = [:]

    /// Returns a short definition string, or nil if none is found / the request fails.
    /// Results are cached in-memory per word for the life of the app.
    static func definition(for word: String) async -> String? {
        let key = word.uppercased()
        if let cached = cache[key] { return cached }
        guard let url = URL(string: "https://api.dictionaryapi.dev/api/v2/entries/en/\(word.lowercased())") else {
            return nil
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let entries = try JSONDecoder().decode([Entry].self, from: data)
            let text = entries.first?.meanings.first?.definitions.first?.definition
            cache[key] = text
            return text
        } catch {
            cache[key] = nil
            return nil
        }
    }

    private struct Entry: Decodable {
        let meanings: [Meaning]
    }
    private struct Meaning: Decodable {
        let definitions: [Definition]
    }
    private struct Definition: Decodable {
        let definition: String
    }
}

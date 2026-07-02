import Foundation

/// Kid Mode collectible reward: the first time a child spells a given word (ever, across
/// sessions), they earn a sticker for it. The reward is tied to the specific word they formed —
/// not a generic badge — echoing the Duolingo ABC finding that celebration should reinforce the
/// mechanic itself rather than sit as a layer on top of it.
enum WordSticker {
    private static let defaultsKey = "kidWordStickers"

    private static let palette = [
        "🦊", "🐸", "🐙", "🦉", "🐢", "🦄", "🐳", "🦋", "🐝", "🦖",
        "🐬", "🦁", "🐧", "🐨", "🦒", "🐳", "🦩", "🐿️", "🦔", "🐲",
        "🍎", "🍓", "🍉", "🍩", "🍦", "🍭", "🎈", "🌈", "⭐️", "🌟",
        "🚀", "🎨", "🎸", "🪁", "🎁", "🧩", "🔮", "🍄", "🌻", "🍀"
    ]

    /// Stable across launches/devices — Swift's String.hashValue is randomly salted per process,
    /// so the same word could map to a different emoji every relaunch without this.
    private static func stableHash(_ s: String) -> UInt64 {
        var hash: UInt64 = 14695981039346656037
        for byte in s.uppercased().utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 1099511628211
        }
        return hash
    }

    static func emoji(for word: String) -> String {
        palette[Int(stableHash(word) % UInt64(palette.count))]
    }

    static func hasCollected(_ word: String) -> Bool {
        collectedWords().contains(word.uppercased())
    }

    /// Records the word as collected. Returns true if this is the FIRST time — the caller should
    /// only show the "New sticker!" celebration when this is true.
    @discardableResult
    static func record(_ word: String) -> Bool {
        var set = collectedWords()
        let key = word.uppercased()
        guard !set.contains(key) else { return false }
        set.insert(key)
        UserDefaults.standard.set(Array(set), forKey: defaultsKey)
        return true
    }

    static func collectedWords() -> Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: defaultsKey) ?? [])
    }

    static func count() -> Int { collectedWords().count }

    static func clearAll() {
        UserDefaults.standard.removeObject(forKey: defaultsKey)
    }
}

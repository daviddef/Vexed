import Foundation

/// Deterministic RNG (SplitMix64) — the same seed always produces the same sequence.
/// Used to generate an identical Daily Puzzle board for every player on a given date.
/// NOT `Hasher`-based: Swift's Hasher is randomly salted per process launch and would
/// produce a different board on every app relaunch.
final class SeededRNG: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    /// FNV-1a 64-bit hash — portable and stable across devices/launches, unlike Hasher.
    static func seed(forDateKey key: String) -> UInt64 {
        var hash: UInt64 = 14695981039346656037
        for byte in key.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 1099511628211
        }
        return hash
    }

    /// "yyyyMMdd" in UTC so every player gets the same board on the same calendar day
    /// regardless of local timezone.
    static func todayKey(date: Date = Date()) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyyMMdd"
        df.timeZone = TimeZone(identifier: "UTC")
        return df.string(from: date)
    }
}

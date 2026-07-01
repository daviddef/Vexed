import Foundation

// Trie node for O(n) word lookup
private class TrieNode {
    var children: [Character: TrieNode] = [:]
    var isWord = false
}

final class WordValidator {
    private static var cache: [String: WordValidator] = [:]
    private static let cacheLock = NSLock()

    static func forResource(_ name: String) -> WordValidator {
        cacheLock.lock()
        if let cached = cache[name] { cacheLock.unlock(); return cached }
        cacheLock.unlock()
        let v = WordValidator(resourceName: name)
        cacheLock.lock()
        cache[name] = v
        cacheLock.unlock()
        return v
    }

    private let root = TrieNode()
    private(set) var wordCount = 0

    private init(resourceName: String) {
        load(resourceName: resourceName)
    }

    private func load(resourceName: String) {
        let parts = resourceName.components(separatedBy: ".")
        let name = parts.first ?? resourceName
        let ext  = parts.count > 1 ? parts.last : "txt"
        let content: String?
        if let url = Bundle.main.url(forResource: name, withExtension: ext) {
            content = try? String(contentsOf: url, encoding: .utf8)
        } else {
            content = try? String(contentsOfFile: "/usr/share/dict/words", encoding: .utf8)
        }
        guard let content else { return }
        for line in content.components(separatedBy: .newlines) {
            let raw = line.trimmingCharacters(in: .whitespaces)
            // easy_words.txt is pre-uppercased; dictionary.txt / words.txt are lowercase
            let lower = raw.lowercased()
            guard let first = lower.first, first.isLetter else { continue }
            let word = lower.uppercased()
            guard word.count >= 3, word.count <= 10,
                  word.allSatisfy({ $0.isLetter && $0.isASCII }) else { continue }
            insert(word)
        }
    }

    private func insert(_ word: String) {
        var node = root
        for ch in word {
            if node.children[ch] == nil { node.children[ch] = TrieNode() }
            node = node.children[ch]!
        }
        if !node.isWord { node.isWord = true; wordCount += 1 }
    }

    func isValid(_ word: String) -> Bool {
        guard !word.isEmpty else { return false }
        var node = root
        for ch in word.uppercased() {
            guard let next = node.children[ch] else { return false }
            node = next
        }
        return node.isWord
    }
}

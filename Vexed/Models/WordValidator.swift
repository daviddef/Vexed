import Foundation

// Trie node for O(n) word lookup
private class TrieNode {
    var children: [Character: TrieNode] = [:]
    var isWord = false
}

final class WordValidator {
    static let shared = WordValidator()

    private let root = TrieNode()
    private(set) var wordCount = 0

    private init() {
        loadBuiltIn()
    }

    private func loadBuiltIn() {
        // Load bundled dictionary (works on device + simulator)
        // Falls back to system path in Simulator if bundle resource missing
        let content: String?
        if let url = Bundle.main.url(forResource: "dictionary", withExtension: "txt") {
            content = try? String(contentsOf: url, encoding: .utf8)
        } else {
            content = try? String(contentsOfFile: "/usr/share/dict/words", encoding: .utf8)
        }
        guard let content else { return }
        for line in content.components(separatedBy: .newlines) {
            let word = line.trimmingCharacters(in: .whitespaces).uppercased()
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

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
        // Load curated game dictionary from bundle (words.txt — ~33k common English words)
        // This replaces the system /usr/share/dict/words which contains obscure Latin,
        // archaic, and technical terms that confuse players when they score unexpectedly.
        if let url = Bundle.main.url(forResource: "words", withExtension: "txt"),
           let content = try? String(contentsOf: url, encoding: .utf8) {
            for line in content.components(separatedBy: .newlines) {
                let word = line.trimmingCharacters(in: .whitespaces)
                guard word.count >= 3, word.count <= 10,
                      word.allSatisfy({ $0.isLetter && $0.isASCII }) else { continue }
                insert(word.uppercased())
            }
        } else {
            // Fallback if bundle resource missing
            loadFallbackWords()
        }
    }

    private func loadFallbackWords() {
        let words = "CAT BAT HAT RAT DOG LOG FOG RUN SUN FUN GUN BIT HIT SIT FIT BED FED RED TOP HOP MOP POP CAVE GAVE SAVE WAVE BALE GALE MALE PALE SALE TALE CORE BORE MORE SORE WORE LIME TIME GAME FAME NAME SAME VOTE NOTE BONE CONE TONE ZONE BEST REST TEST VEST WEST NEST PEST FARM HARM WARM DARK LARK MARK PARK WORD WARD BIRD FIRE HIRE WIRE TIRE"
        for word in words.components(separatedBy: .whitespaces) { insert(word) }
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

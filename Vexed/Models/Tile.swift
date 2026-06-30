import Foundation

enum Vowel: Character, CaseIterable, Hashable {
    case A = "A", E = "E", I = "I", O = "O", U = "U"
}

enum TileType: Equatable {
    case consonant
    case vowel(Vowel)
}

enum TileAnimState {
    case idle, selected, danger, vanishing, scoring
}

struct Tile: Identifiable, Equatable {
    let id: UUID
    let letter: Character
    let type: TileType
    var animState: TileAnimState = .idle

    init(letter: Character) {
        self.id = UUID()
        self.letter = letter
        if let v = Vowel(rawValue: letter) {
            self.type = .vowel(v)
        } else {
            self.type = .consonant
        }
    }

    var isVowel: Bool {
        if case .vowel = type { return true }
        return false
    }

    var vowel: Vowel? {
        if case .vowel(let v) = type { return v }
        return nil
    }
}

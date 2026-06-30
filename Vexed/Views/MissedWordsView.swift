import SwiftUI

struct MissedWordEntry: Identifiable {
    let id = UUID()
    let word: String
    let points: Int
}

struct MissedWordsView: View {
    let grid: [[Tile?]]
    let config: DifficultyConfig

    private var foundWords: [MissedWordEntry] {
        let validator = WordValidator.shared
        var seen: Set<String> = []
        var results: [MissedWordEntry] = []

        func scanLine(_ positions: [Position]) {
            var i = 0
            while i < positions.count {
                guard grid[positions[i].row][positions[i].col] != nil else { i += 1; continue }
                var j = i
                while j < positions.count, grid[positions[j].row][positions[j].col] != nil { j += 1 }
                let run = Array(positions[i..<j])
                for start in 0..<run.count {
                    for end in stride(from: run.count, through: start + config.minWordLength, by: -1) {
                        let slice = Array(run[start..<end])
                        let word = slice.compactMap { grid[$0.row][$0.col]?.letter }
                                       .map { String($0) }.joined()
                        if word.count == end - start, validator.isValid(word), !seen.contains(word) {
                            seen.insert(word)
                            let pts = word.count * 10 + (word.count > 4 ? 20 : 0)
                            results.append(MissedWordEntry(word: word, points: pts))
                        }
                    }
                }
                i = j
            }
        }

        for r in 0..<config.rows {
            scanLine((0..<config.cols).map { Position(r, $0) })
        }
        for c in 0..<config.cols {
            scanLine((0..<config.rows).map { Position($0, c) })
        }

        return results.sorted { $0.points > $1.points }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("WORDS YOU COULD FIND")
                .font(.system(size: 11, weight: .black))
                .foregroundColor(Color(white: 0.4))
                .tracking(3)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 12)

            if foundWords.isEmpty {
                Text("No words found on the current board.")
                    .font(.system(size: 14))
                    .foregroundColor(Color(white: 0.35))
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(foundWords) { entry in
                            HStack {
                                Text(entry.word)
                                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                Spacer()
                                Text("+\(entry.points)")
                                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.yellow)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)

                            Divider()
                                .background(Color(white: 0.12))
                        }
                    }
                }
            }
        }
        .background(Color(red: 0.06, green: 0.06, blue: 0.09))
    }
}

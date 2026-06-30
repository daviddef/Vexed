import Foundation

struct Position: Hashable, Equatable {
    let row: Int
    let col: Int

    init(_ row: Int, _ col: Int) {
        self.row = row
        self.col = col
    }

    func moved(_ dir: Direction) -> Position {
        Position(row + dir.dr, col + dir.dc)
    }

    func isValid(rows: Int, cols: Int) -> Bool {
        row >= 0 && row < rows && col >= 0 && col < cols
    }
}

enum Direction: CaseIterable {
    case up, down, left, right
    case upLeft, upRight, downLeft, downRight

    var dr: Int {
        switch self {
        case .up, .upLeft, .upRight: return -1
        case .down, .downLeft, .downRight: return 1
        case .left, .right: return 0
        }
    }

    var dc: Int {
        switch self {
        case .left, .upLeft, .downLeft: return -1
        case .right, .upRight, .downRight: return 1
        case .up, .down: return 0
        }
    }

    // Cardinal only (used for slide mechanic)
    static var cardinal: [Direction] { [.up, .down, .left, .right] }

    init?(translation: CGSize) {
        let h = translation.width, v = translation.height
        guard max(abs(h), abs(v)) > 10 else { return nil }
        if abs(h) > abs(v) {
            self = h > 0 ? .right : .left
        } else {
            self = v > 0 ? .down : .up
        }
    }
}

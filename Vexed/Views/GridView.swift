import SwiftUI

struct GridView: View {
    @ObservedObject var engine: GameEngine
    @State private var dragStart: Position? = nil
    @State private var touchedPosition: Position? = nil
    @Namespace private var tileNamespace
    @State private var revealedRows: Set<Int> = []
    @State private var lastBoardVersion: Int = -1

    var body: some View {
        GeometryReader { geo in
            let rows = engine.config.rows
            let cols = engine.config.cols
            let gap: CGFloat = 6
            let totalGapW = gap * CGFloat(cols - 1) + 20
            let totalGapH = gap * CGFloat(rows - 1) + 20
            let tileW = (geo.size.width - totalGapW) / CGFloat(cols)
            let tileH = (geo.size.height - totalGapH) / CGFloat(rows)
            let tileSize = min(tileW, tileH)

            // Flatten slide paths into quick-lookup sets
            let pathSet: Set<Position> = Set(engine.slidePaths.values.flatMap { $0 })
            let destSet: Set<Position> = Set(engine.slidePaths.values.compactMap { $0.last })
            let pathColor: Color = selectedTileColor()

            ZStack {
                // ── Game board background ──────────────────────────────
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 0.07, green: 0.07, blue: 0.11))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(white: 0.35), lineWidth: 1)
                    )

                // ── Tile grid ─────────────────────────────────────────
                VStack(spacing: gap) {
                    ForEach(0..<rows, id: \.self) { r in
                        HStack(spacing: gap) {
                            ForEach(0..<cols, id: \.self) { c in
                                let pos = Position(r, c)
                                let tile = engine.grid[r][c]
                                let isSelected = engine.selectedPosition == pos
                                let isTouching = touchedPosition == pos
                                let isPath = pathSet.contains(pos)
                                let isDest = destSet.contains(pos)

                                Group {
                                    if let tile {
                                        TileCellView(
                                            tile: tile,
                                            isSelected: isSelected,
                                            size: tileSize,
                                            isTouching: isTouching
                                        )
                                        .matchedGeometryEffect(id: tile.id, in: tileNamespace)
                                    } else {
                                        TileCellView(
                                            tile: nil,
                                            isSelected: false,
                                            size: tileSize,
                                            isTouching: false,
                                            pathColor: isPath ? pathColor : nil,
                                            isDestination: isDest
                                        )
                                    }
                                }
                                .contentShape(Rectangle())
                                .gesture(tileDragGesture(at: pos))
                                .onTapGesture { engine.select(position: pos) }
                            }
                        }
                        .opacity(revealedRows.contains(r) ? 1 : 0)
                        .offset(y: revealedRows.contains(r) ? 0 : -20)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onChange(of: engine.boardVersion) { _, version in
                    guard version != lastBoardVersion else { return }
                    lastBoardVersion = version
                    revealedRows = []
                    for r in 0..<engine.config.rows {
                        DispatchQueue.main.asyncAfter(deadline: .now() + Double(r) * 0.07) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
                                _ = revealedRows.insert(r)
                            }
                        }
                    }
                }
                .onAppear {
                    lastBoardVersion = engine.boardVersion
                    revealedRows = []
                    for r in 0..<engine.config.rows {
                        DispatchQueue.main.asyncAfter(deadline: .now() + Double(r) * 0.07 + 0.15) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
                                _ = revealedRows.insert(r)
                            }
                        }
                    }
                }
            }
        }
    }

    private func selectedTileColor() -> Color {
        guard let pos = engine.selectedPosition,
              let tile = engine.grid[pos.row][pos.col] else { return Color(white: 0.6) }
        switch tile.type {
        case .consonant:  return Color(white: 0.7)
        case .vowel(.A):  return Color(red: 1.0, green: 0.35, blue: 0.35)
        case .vowel(.E):  return Color(red: 0.3, green: 1.0, blue: 0.5)
        case .vowel(.I):  return Color(red: 0.45, green: 0.6, blue: 1.0)
        case .vowel(.O):  return Color(red: 1.0, green: 0.75, blue: 0.2)
        case .vowel(.U):  return Color(red: 0.85, green: 0.4, blue: 1.0)
        }
    }

    private func tileDragGesture(at pos: Position) -> some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { _ in
                if dragStart == nil {
                    dragStart = pos
                    touchedPosition = pos
                    Haptics.light()
                }
            }
            .onEnded { value in
                guard let origin = dragStart else { return }
                dragStart = nil
                touchedPosition = nil
                guard let dir = Direction(translation: value.translation) else { return }

                if engine.selectedPosition != origin {
                    engine.select(position: origin)
                }
                engine.slide(direction: dir)
            }
    }
}

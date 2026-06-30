import SwiftUI

struct GridView: View {
    @ObservedObject var engine: GameEngine
    @State private var dragStart: Position? = nil
    @State private var touchedPosition: Position? = nil
    @Namespace private var tileNamespace

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

            ZStack {
                // ── Game board background ──────────────────────────────
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 0.07, green: 0.07, blue: 0.11))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(white: 0.16), lineWidth: 1)
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
                                            isTouching: false
                                        )
                                    }
                                }
                                .contentShape(Rectangle())
                                .gesture(tileDragGesture(at: pos))
                                .onTapGesture { engine.select(position: pos) }
                            }
                        }
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    // Drag on a tile: if selected tile matches, slide it; otherwise select then slide
    private func tileDragGesture(at pos: Position) -> some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { _ in
                // Record drag origin tile once and light up touch glow immediately
                if dragStart == nil {
                    dragStart = pos
                    touchedPosition = pos
                }
            }
            .onEnded { value in
                guard let origin = dragStart else { return }
                dragStart = nil
                touchedPosition = nil
                guard let dir = Direction(translation: value.translation) else { return }

                // Select origin tile if not already, then slide
                if engine.selectedPosition != origin {
                    engine.select(position: origin)
                }
                engine.slide(direction: dir)
            }
    }
}

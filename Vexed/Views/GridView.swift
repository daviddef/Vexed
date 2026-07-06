import SwiftUI

struct GridView: View {
    @ObservedObject var engine: GameEngine
    @State private var dragStart: Position? = nil
    @State private var touchedPosition: Position? = nil
    @Namespace private var tileNamespace
    @State private var revealedRows: Set<Int> = []
    @State private var lastBoardVersion: Int = -1
    @State private var wordPulse: Bool = false
    @State private var hintPulse: Bool = false
    @AppStorage("appTheme") private var appThemeRaw: String = AppTheme.regular.rawValue
    private var isLightTheme: Bool { AppTheme(rawValue: appThemeRaw) == .light }
    private var boardFill: Color { isLightTheme ? Color.white : Color(red: 0.07, green: 0.07, blue: 0.11) }
    private var boardStroke: Color { isLightTheme ? Color(white: 0.85) : Color(white: 0.35) }

    var body: some View {
        GeometryReader { geo in
            let rows = engine.config.rows
            let cols = engine.config.cols
            let gap: CGFloat = 6
            let padding: CGFloat = 10
            let totalGapW = gap * CGFloat(cols - 1) + padding * 2
            let totalGapH = gap * CGFloat(rows - 1) + padding * 2
            let tileW = (geo.size.width - totalGapW) / CGFloat(cols)
            let tileH = (geo.size.height - totalGapH) / CGFloat(rows)
            let tileSize = min(tileW, tileH)

            // Flatten slide paths into quick-lookup sets
            let pathSet: Set<Position> = Set(engine.slidePaths.values.flatMap { $0 })
            let destSet: Set<Position> = Set(engine.slidePaths.values.compactMap { $0.last })
            let pathColor: Color = selectedTileColor()
            // Map each position to the longest available word it belongs to (already sorted longest-first)
            let wordAtPosition: [Position: GameEngine.AvailableWord] = Dictionary(
                engine.availableWords.flatMap { w in w.positions.map { ($0, w) } },
                uniquingKeysWith: { first, _ in first }
            )
            let hintWord = engine.hintWordId.flatMap { id in engine.availableWords.first { $0.id == id } }
            let hintPositions: Set<Position> = Set(hintWord?.positions ?? [])
            let hintMovePositions: Set<Position> = Set(engine.hintMoves.map { $0.from })

            // Where the tile content actually starts within the ZStack
            // (VStack with maxWidth/Height:infinity centers its content)
            let contentWidth  = CGFloat(cols) * tileSize + CGFloat(cols - 1) * gap
            let contentHeight = CGFloat(rows) * tileSize + CGFloat(rows - 1) * gap
            let gridX = (geo.size.width  - contentWidth)  / 2
            let gridY = (geo.size.height - contentHeight) / 2

            ZStack {
                // ── Game board background ──────────────────────────────
                RoundedRectangle(cornerRadius: 20)
                    .fill(boardFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(boardStroke, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(isLightTheme ? 0.10 : 0), radius: isLightTheme ? 14 : 0, x: 0, y: 6)

                // ── Tile grid ─────────────────────────────────────────
                VStack(spacing: gap) {
                    ForEach(0..<rows, id: \.self) { r in
                        HStack(spacing: gap) {
                            ForEach(0..<cols, id: \.self) { c in
                                let pos = Position(r, c)
                                let tile: Tile? = r < engine.grid.count && c < engine.grid[r].count
                                    ? engine.grid[r][c] : nil
                                let isSelected = engine.selectedPosition == pos
                                let isTouching = touchedPosition == pos
                                let isPath = pathSet.contains(pos)
                                let isDest = destSet.contains(pos)
                                let isHintTile = tile != nil && (hintPositions.contains(pos) || hintMovePositions.contains(pos))
                                let isCritical = tile != nil && engine.criticalDangerPositions.contains(pos)
                                let isDimmed: Bool = {
                                    guard let hl = engine.highlightedPositions else { return false }
                                    // Never dim a tile that the hint is pointing to
                                    if isHintTile { return false }
                                    return tile != nil && !hl.contains(pos)
                                }()

                                ZStack {
                                    if let tile {
                                        TileCellView(
                                            tile: tile,
                                            isSelected: isSelected,
                                            size: tileSize,
                                            isTouching: isTouching,
                                            isHintTile: isHintTile,
                                            isCriticalDanger: isCritical
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
                                    // Dimming overlay: separate from matchedGeometryEffect to avoid SwiftUI animation conflicts
                                    if isDimmed {
                                        RoundedRectangle(cornerRadius: tileSize * 0.2)
                                            .fill(Color.black.opacity(0.48))
                                            .allowsHitTesting(false)
                                            .transition(.opacity)
                                    }
                                    // Kid hint beacon: expanding rings on the first tap target (phase 2)
                                    if engine.hintBeaconActive &&
                                       (hintWord?.positions.first == pos || engine.hintMoves.first?.from == pos) {
                                        BeaconView(size: tileSize)
                                            .allowsHitTesting(false)
                                    }
                                    // Kid slide hint: arrow(s) showing which tile(s) to move
                                    // Step 1 arrow — always shown when hintMoves is non-empty
                                    if let move = engine.hintMoves.first, move.from == pos {
                                        hintArrow(direction: move.direction, tileSize: tileSize, scale: hintPulse ? 1.25 : 0.8, opacity: 1.0)
                                    }
                                    // Step 2 arrow — revealed only in phase 2 (beacon active) if a 2-step path exists
                                    if engine.hintBeaconActive, engine.hintMoves.count > 1,
                                       let move2 = engine.hintMoves.dropFirst().first, move2.from == pos {
                                        hintArrow(direction: move2.direction, tileSize: tileSize, scale: hintPulse ? 1.1 : 0.75, opacity: 0.7)
                                    }
                                }
                                .frame(width: tileSize, height: tileSize)
                                .animation(.easeInOut(duration: 0.18), value: isDimmed)
                                .contentShape(Rectangle())
                                .gesture(tileDragGesture(at: pos))
                                .onTapGesture {
                                    if let word = wordAtPosition[pos] {
                                        engine.collectWord(word)
                                    } else {
                                        engine.select(position: pos)
                                    }
                                }
                            }
                        }
                        .opacity(revealedRows.contains(r) ? 1 : 0)
                        .offset(y: revealedRows.contains(r) ? 0 : -20)
                    }
                }
                .padding(padding)
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
                    withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                        wordPulse = true
                    }
                    withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                        hintPulse = true
                    }
                }

                // ── Word outline overlay ───────────────────────────────
                // One rounded rect per word. Tap the outline (or its interior) to collect.
                // Drags still reach the tiles below because TapGesture only fires on stationary touches.
                ZStack(alignment: .topLeading) {
                    ForEach(engine.availableWords) { word in
                        let minR = word.positions.map({ $0.row }).min() ?? 0
                        let maxR = word.positions.map({ $0.row }).max() ?? 0
                        let minC = word.positions.map({ $0.col }).min() ?? 0
                        let maxC = word.positions.map({ $0.col }).max() ?? 0
                        let outset: CGFloat = 3
                        let x = gridX + CGFloat(minC) * (tileSize + gap) - outset
                        let y = gridY + CGFloat(minR) * (tileSize + gap) - outset
                        let w = CGFloat(maxC - minC + 1) * tileSize + CGFloat(maxC - minC) * gap + outset * 2
                        let h = CGFloat(maxR - minR + 1) * tileSize + CGFloat(maxR - minR) * gap + outset * 2
                        let cr = tileSize * 0.26 + outset

                        RoundedRectangle(cornerRadius: cr)
                            .stroke(
                                Color(red: 1.0, green: 0.85, blue: 0.2)
                                    .opacity(wordPulse ? 0.85 : 0.2),
                                lineWidth: 2.5
                            )
                            .frame(width: w, height: h)
                            .offset(x: x, y: y)
                            .allowsHitTesting(false)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: wordPulse)
            }
        }
    }

    private func arrowSymbol(for direction: Direction) -> String {
        switch direction {
        case .up:    return "arrow.up"
        case .down:  return "arrow.down"
        case .left:  return "arrow.left"
        default:     return "arrow.right"
        }
    }

    @ViewBuilder
    private func hintArrow(direction: Direction, tileSize: CGFloat, scale: CGFloat, opacity: Double) -> some View {
        let (dx, dy): (CGFloat, CGFloat) = switch direction {
        case .right: (tileSize * 0.7, 0)
        case .left:  (-tileSize * 0.7, 0)
        case .down:  (0, tileSize * 0.7)
        default:     (0, -tileSize * 0.7)
        }
        Image(systemName: arrowSymbol(for: direction))
            .font(.system(size: tileSize * 0.38, weight: .black))
            .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.2).opacity(opacity))
            .shadow(color: Color(red: 1.0, green: 0.75, blue: 0.0).opacity(0.85 * opacity), radius: 10)
            .scaleEffect(scale)
            .offset(x: dx, y: dy)
            .allowsHitTesting(false)
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

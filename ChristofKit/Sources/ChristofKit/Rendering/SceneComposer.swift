/// 구성 요소를 쌓는 순서: 벽 → 시계 → 창문 → 고양이 → 방 안 물건 → 사람. 사람 곁의 고양이(front)는 사람 앞이다.
/// 윤곽선은 물체마다 따로 두르므로 순서가 바뀌면 다른 그림이 된다.
public enum SceneComposer {
    public static func grid(for context: SceneContext, cols: Int, rows: Int) -> DotGrid {
        let s = DotScene(context)
        let L = RoomLayout(cols: cols, rows: rows, tree: s.looks.room.contains { $0.spot == .lamp }, pets: s.theme.pets)
        let cat = L.catSpot(s.catState)
        var g = DotGrid(cols: cols, rows: rows)
        WallPainter.draw(&g, L, s)
        g.ink { ClockPainter.draw(&$0, L, s) }
        for look in s.looks.clock { look.bare(&g, L.clock.x, L.clock.y, s) }
        WindowPainter.draw(&g, L, s)
        if !cat.front { g.ink { CatPainter.draw(&$0, s, cat) } }
        RoomPainter.draw(&g, L, s)
        g.ink { PersonPainter.draw(&$0, L, s) }
        if cat.front { g.ink { CatPainter.draw(&$0, s, cat) } }
        return g
    }
}

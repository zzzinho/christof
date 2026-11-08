import Foundation

/// 한국 도시: 먼 풍경(지역마다 다르다), 가까이 낮은 상가·빌라. 해가 진 뒤와 흐린 날은 창에 호박색 불이 켜진다.
/// 불을 켜지 않는 낮에도 난수를 같은 만큼 써서 건물 모양이 때와 관계없이 같다.
/// 밤에 켜지는 교회 십자가 자리 [가운데, 바닥]를 돌려준다. 십자가는 가로수 다음에 그린다(drawCross).
struct CityEffect {
    func draw(_ g: inout DotGrid, _ w: Int, _ h: Int, _ s: DotScene) -> (x: Int, y: Int)? {
        var city = SeededRandom(seed: 7)
        let lit = s.phase == .day ? 0 : s.phase == .grey ? 0.4 : 1
        let windowLit = LofiPalette.color("window-lit")
        let farBottom = jsRound(Double(h) * 0.86)
        s.farView.draw(&g, w, h, s, &city, lit: lit, farBottom: farBottom)
        // 가까운 낮은 건물. 밤에는 오른쪽 유리(창턱 고양이와 겹치지 않는 곳)의 첫 건물 옥상에 교회 빨간 네온 십자가가 켜진다.
        let night = s.phase == .night || s.phase == .dusk
        var cross: (x: Int, y: Int)?
        var bx = city(-3...0)
        while bx < Double(w) {
            let bw = city.int(jsRound(14 / DotGrid.dot), jsRound(30 / DotGrid.dot))
            let top = jsRound(Double(h) * 0.95) - jsRound(city(8...20) / DotGrid.dot + Double(h) * 0.08)
            g.rect(bx, Double(top), Double(bw), Double(h - top), s.color("city"))
            if s.snowCovered { g.rect(bx, Double(top), Double(bw), 1, s.color("snow")) }
            for wy in stride(from: top + 2, to: h, by: 2) {
                var wx = jsRound(bx) + 1
                while Double(wx) < bx + Double(bw) - 1 {
                    if city(0...1) < 0.25 * lit { g.set(wx, wy, windowLit) }
                    wx += 2
                }
            }
            if night, cross == nil, bx + Double(bw) / 2 > Double(w) * 0.6 { cross = (jsRound(bx + Double(bw) / 2), top) }
            bx += Double(bw + city.int(0, 2))
        }
        return cross
    }

    /// 십자가는 낮은 건물 옥상보다 높이 서 있어 가로수에 가리지 않는다.
    static func drawCross(_ g: inout DotGrid, _ at: (x: Int, y: Int)) {
        g.sprite(at.x, at.y, [".X.", "XXX", ".X.", ".X."], ["X": "bulb-1"])
    }
}

/// 기본 테마 창밖: 한국 도시와 가로수, 밤의 교회 십자가
struct KoreanTownEffect: OutsideEffect {
    func draw(_ g: inout DotGrid, _ w: Int, _ h: Int, _ s: DotScene) {
        let cross = CityEffect().draw(&g, w, h, s)
        StreetTreeEffect().draw(&g, w, h, s)
        if let cross { CityEffect.drawCross(&g, cross) }
    }
}

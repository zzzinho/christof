import Foundation

/// 헤네시스(메이플스토리 궁수 마을). 멀리 뾰족한 청록 산맥과 그 앞 둥근 초록 언덕, 앞에는 알록달록한 큰 버섯집과 하얀 줄기 나무가 창을 채운다.
/// 낮에는 가끔 뿔버섯·초록버섯이 집 앞을 지난다. 해가 진 뒤와 흐린 날은 집 창에 불이 켜진다.
/// 산맥 꼭대기를 기본 테마 뒷산 능선(skyline)에 맞춰 해·달 높이가 그대로이고, 산이 보름달을 가리지 않는다.
struct HenesysEffect: OutsideEffect {
    /// [가운데 가로 위치, 갓 폭, 갓 색, 바닥에서 띄운 칸]. 먼 집부터 그린다.
    static let houses: [(x: Double, capW: Int, cap: String, lift: Int)] = [(0.6, 15, "cap-2", 4), (0.27, 25, "cap-1", 0), (0.87, 21, "cap-3", 1)]
    /// 산 봉우리 [가로 위치, 높이 칸, 비탈 기울기]. 봉우리를 줄이고 비탈을 눕혀 작은 세모가 아닌 큰 산줄기로 읽히게 한다.
    static let peaks: [(x: Double, height: Double, slope: Double)] = [(0.06, 7, 0.8), (0.3, 9, 0.85), (0.55, 8, 0.8), (0.8, 9, 0.85), (1.02, 7, 0.8)]
    /// 시각마다 창밖을 지나는 몬스터. 절반은 아무도 없다.
    static let visitors: [[Monster]] = [[], [], [], [.horny], [.green], [.horny, .green]]

    func draw(_ g: inout DotGrid, _ w: Int, _ h: Int, _ s: DotScene) {
        let lit = s.phase == .day ? 0 : s.phase == .grey ? 0.4 : 1, dark = s.phase == .night || s.phase == .dusk
        // large 의 높은 창에서는 집과 나무를 1.4배로 키운다. 그대로 두면 창 아래에 작게 깔려 큰 버섯집으로 읽히지 않았다.
        let top = jsRound(skyline(h)), ground = h - 3, scale = h > 60 ? 1.4 : 1
        var town = SeededRandom(seed: 43)
        drawPeaks(&g, w, h, s, top)
        for x in 0..<w {
            let y0 = top + 8 - jsRound(1.5 * sin(Double(x) * 0.12 + 1) + sin(Double(x) * 0.05))
            g.rect(x, y0, 1, h - y0, s.color("mountain"))
        }
        for x in 0..<w {
            let y0 = ground - 2 - jsRound(sin(Double(x) * 0.15) * 0.8)
            g.rect(x, y0, 1, h - y0, s.color("meadow"))
        }
        drawTree(&g, jsRound(Double(w) * 0.47), ground - 2, jsRound(13 * scale), s, dark: dark)
        for house in Self.houses {
            drawHouse(&g, (house.x, jsRound(Double(house.capW) * scale), house.cap, house.lift), w, ground, s, &town, lit: lit)
        }
        // 몬스터는 낮에만 나온다(밤·흐린 날 색을 따로 두지 않는다). 가운데 문살(창폭 50%)을 피해 큰 집 벽 앞에 선다.
        if s.phase == .day {
            var random = SeededRandom(seed: s.seed)
            for (i, monster) in Self.visitors[random.int(0, Self.visitors.count - 1)].enumerated() {
                g.sprite(jsRound(Double(w) * [0.38, 0.7][i]), ground + 1, monster.rows, monster.colors)
            }
        }
    }

    /// 뾰족한 청록 산맥. 가장 높은 봉우리 꼭대기가 skyline 이고, 봉우리마다 오른쪽 비탈이 그늘이다. 눈이 오면 꼭대기에 눈.
    private func drawPeaks(_ g: inout DotGrid, _ w: Int, _ h: Int, _ s: DotScene, _ top: Int) {
        for x in 0..<w {
            var best = -Double.infinity, shade = false
            for peak in Self.peaks {
                let px = jsRound(peak.x * Double(w)), rise = peak.height - Double(abs(x - px)) * peak.slope
                if rise > best { (best, shade) = (rise, x > px) }
            }
            let y0 = top + 9 - jsRound(best)
            g.rect(x, y0, 1, h - y0, s.color(shade ? "peak-dark" : "peak"))
            if s.snowCovered { g.set(x, y0, s.color("snow")) }
        }
    }

    /// 버섯집: 크림색 벽에 아치 문과 둥근 창, 벽보다 양쪽으로 다섯 칸 넓은 둥근 갓. 갓 끝은 한 칸 처지고 크림색 점과 지붕창이 있다.
    /// 갓 높이와 벽 높이는 갓 폭에 비례한다. 눈이 오면 갓 위에 눈을 얹는다. 창 불빛은 작은 집도 난수를 한 번 쓴다.
    private func drawHouse(_ g: inout DotGrid, _ house: (x: Double, capW: Int, cap: String, lift: Int), _ w: Int, _ ground: Int, _ s: DotScene, _ random: inout SeededRandom, lit: Double) {
        let capW = house.capW, cx = jsRound(house.x * Double(w)), bottom = ground - house.lift
        let capH = jsRound(Double(capW) * 0.36), wallW = capW - 10, wallH = jsRound(Double(capW) * 0.32)
        let x0 = cx - capW / 2, wallTop = bottom - wallH
        let cottage = s.color("cottage"), city = s.color("city")
        func glow() -> UInt32 { random(0...1) < 0.7 * lit ? LofiPalette.color("window-lit") : city }
        g.rect(cx - wallW / 2, wallTop, wallW, wallH, cottage)
        let doorW = capW > 16 ? 3 : 1, doorH = jsRound(Double(wallH) * 0.6)
        g.rect(cx - doorW / 2, bottom - doorH, doorW, doorH, city)
        if doorW == 3 { for dx in [-1, 1] { g.set(cx + dx, bottom - doorH, cottage) } }
        // 작은 집은 문만 둔다. 문과 1칸 창이 나란하면 창살처럼 보였다.
        let windowSize = 2, c = glow()
        if capW > 16 {
            for side in [-1, 1] {
                g.rect(cx + side * jsRound(Double(wallW) * 0.32) - (side < 0 ? windowSize - 1 : 0), wallTop + 2, windowSize, windowSize, c)
            }
        }
        var tops: [Int] = []
        for i in 0..<capW {
            let u = abs((Double(i) + 0.5 - Double(capW) / 2) / (Double(capW) / 2))
            let colH = max(1, jsRound(Double(capH) * pow(1 - pow(u, 2.5), 0.45)))
            let y0 = wallTop - colH, droop = u > 0.8 ? 1 : 0
            g.rect(x0 + i, y0, 1, colH + droop, s.color(house.cap))
            if s.snowCovered { g.set(x0 + i, y0, s.color("snow")) }
            tops.append(y0 + (s.snowCovered ? 1 : 0))
        }
        // 갓의 점 [가로 -1~1, 높이 0(아래)~1(위), 폭]. 갓 밖으로 나가는 칸은 칠하지 않는다.
        for (u, v, size) in [(-0.6, 0.3, 2), (-0.15, 0.75, 2), (0.45, 0.55, 2), (0.15, 0.15, 1)] {
            let sx = cx + jsRound(u * Double(capW) / 2), sy = wallTop - 2 - jsRound(v * Double(capH - 2))
            for i in 0..<size {
                for j in 0..<size where tops.indices.contains(sx + i - x0) && sy - j >= tops[sx + i - x0] { g.set(sx + i, sy - j, cottage) }
            }
        }
        // 큰 집은 갓 오른쪽에 지붕창을 낸다.
        if capW > 16 {
            let x = cx + jsRound(Double(capW) * 0.22), glass = glow()
            g.rect(x - 1, wallTop - 2, 3, 2, cottage)
            g.set(x, wallTop - 3, cottage)
            g.set(x, wallTop - 2, glass)
        }
    }

    /// 하얀 줄기에 둥근 잎 덩어리. 잎 색은 기본 테마 가로수와 같이 계절을 따르고, 해가 진 뒤에는 실루엣이다.
    /// 줄기를 길게 세워 잎 덩어리가 버섯집 갓 위로 올라와야 계절이 보인다.
    private func drawTree(_ g: inout DotGrid, _ cx: Int, _ ground: Int, _ height: Int, _ s: DotScene, dark: Bool) {
        let bark = dark ? s.color("city") : s.color("cottage"), top = ground - height, r = 5.0
        g.rect(cx, top, 1, ground - top, bark)
        if let crowns = StreetTreeEffect.crowns(s.season) {
            let main = dark ? bark : LofiPalette.color(crowns[0]), shade = dark ? bark : LofiPalette.color(crowns[1])
            g.shape(Double(cx) - r, Double(top) - r - 1, Double(cx) + r + 1, Double(top) + r - 1,
                    inside: { px, py in jsHypot(px - Double(cx) - 0.5, py - Double(top) + 1) <= r },
                    color: { px, py in Double(px - cx + py - top) > r * 0.6 ? shade : main })
        } else {
            for k in 1...3 {
                g.set(cx - k, top + 3 - k, bark)
                g.set(cx + k, top + 4 - k, bark)
            }
            g.rect(cx, top - 3, 1, 3, bark)
        }
    }
}

/// 창밖 몬스터. 뿔버섯은 가시 돋은 파란 갓, 초록버섯은 매끈한 초록 갓이다. 몸통은 주황버섯과 같은 크림색에 점 눈.
struct Monster: Sendable {
    let rows: [String]
    let colors: [Character: String]

    static let horny = Monster(rows: [".h.h.h.h.", ".hHHHHHh.", "HHHHHHHHH", "hhhhhhhhh", "..wwwww..", "..wewew..", "..wwwww.."],
                               colors: ["H": "horny", "h": "horny-dark", "w": "santa-trim", "e": "outline"])
    static let green = Monster(rows: ["...GGG...", ".GGGGGGG.", "GGGGGGGGG", "ggggggggg", "..wwwww..", "..wewew..", "..wwwww.."],
                               colors: ["G": "green-cap", "g": "green-cap-dark", "w": "santa-trim", "e": "outline"])
}

/// 헤네시스의 주황버섯. 고양이와 같은 자세 이름·자리를 쓴다. c 갓, T 갓의 노란 점, R 갓 테두리 빛, D 갓 아래 그늘, w 몸통, e 눈.
/// 갓 그늘(pot)·몸통(santa-trim)·테두리 빛(cheese-rim)은 방에 이미 있는 색을 써서 장면 색 수(55개 안쪽)를 지킨다.
/// 버섯은 어느 쪽에서 봐도 같은 모양이라 뒷모습과 옆모습은 눈으로만 갈린다. 옆모습은 두 눈을 오른쪽(사람·불빛 쪽)으로 몰아 그쪽을 본다.
extension Pets {
    private static let cap = ["...ccccc...", "..cTTcccR..", ".ccTTccTTR.", "cccccccTTcR", "cTTcccccccR", "DDDDDDDDDDD"]
    private static let scarf = ["..SSSSSSS..", "..S........"]

    static let mushroom = Pets(
        back: CatPose(rows: cap + ["..wwwwwww..", ".wwwwwwwww.", ".wwwwwwwww.", ".wwwwwwwww."], head: (5.5, 0),
                      scarf: ["..SSSSSSS..", "...S.......", "...S......."], scarfBottom: 9),
        side: CatPose(rows: cap + ["..wwwwwww..", ".wwwwewwew.", ".wwwwwwwww.", ".wwwwwwwww."], head: (5.5, 0), scarf: scarf, scarfBottom: 8),
        // 메이플 버섯은 통통 뛰어다닌다. 바닥에서 두 칸 떠 있다.
        walk: CatPose(rows: cap + ["..wwwwwww..", ".wwwwewwew.", ".wwwwwwwww.", "..wwwwwww..", "...........", "..........."], head: (5.5, 0), scarf: scarf, scarfBottom: 8),
        // 고개를 숙일 목이 없어 눈만 아래 그릇 쪽으로 내린다. 그릇은 버섯 다음에 그린다.
        eat: CatPose(rows: cap + ["..wwwwwww..", ".wwwwwwwww.", ".wwwwwewwe.", ".wwwwwwwww."], head: (5.5, 0), scarf: scarf, scarfBottom: 8),
        // 감은 눈, 갓을 눌러 쓴 듯 납작하게 앉았다.
        curled: CatPose(rows: Array(cap[..<4]) + ["DDDDDDDDDDD", ".wwwwwwwww.", ".weewwweew.", "wwwwwwwwwww", "wwwwwwwwwww"], head: (5.5, 0),
                        scarf: [".SSSSSSSSS.", ".........S."], scarfBottom: 7),
        lit: ["c": "mushroom", "T": "mushroom-spot", "R": "cheese-rim", "D": "pot", "w": "santa-trim"],
        unlit: ["c": "mushroom", "T": "mushroom-spot", "R": "mushroom", "D": "pot", "w": "santa-trim"])
}

/// 창 아래쪽 가로수로 계절을 보인다. 해가 진 뒤에는 실루엣이고, 겨울은 잎 없는 가지다.
/// 봄은 새잎(은행나무·느티나무), 가을은 은행나무 노랑에 셋째마다 단풍. 벚꽃은 일본으로 읽혀서 쓰지 않는다.
struct StreetTreeEffect: OutsideEffect {
    func draw(_ g: inout DotGrid, _ w: Int, _ h: Int, _ s: DotScene) {
        var random = SeededRandom(seed: 13)
        let dark = s.phase == .night || s.phase == .dusk
        let crowns = Self.crowns(s.season)
        let bark = dark ? s.color("city") : LofiPalette.color("branch")
        var x = random(1...4), i = 0
        while x < Double(w + 4) {
            let r = random(3...4.6), cx = jsRound(x), top = h - random.int(7, 10)
            g.rect(cx, top, 1, h - top, bark)
            if let crowns {
                let main = dark ? bark : LofiPalette.color(crowns[i % 3 == 2 && crowns.count > 2 ? 2 : 0])
                let shade = dark ? bark : LofiPalette.color(crowns[1])
                g.shape(Double(cx) - r, Double(top) - r, Double(cx) + r + 1, Double(top) + r,
                        inside: { px, py in jsHypot(px - Double(cx) - 0.5, py - Double(top)) <= r },
                        color: { px, py in Double(px - cx + py - top) > r * 0.6 ? shade : main })
            } else {
                for k in 1...3 {
                    g.set(cx - k, top + 3 - k, bark)
                    g.set(cx + k, top + 4 - k, bark)
                }
                g.rect(cx, top - 3, 1, 3, bark)
            }
            x += r * 2 + random(1...4)
            i += 1
        }
        // 봄: 길가 개나리 울타리
        if s.season == .spring {
            for x in 0..<w {
                let top = h - 2 - (random(0...1) < 0.5 ? 1 : 0)
                g.rect(x, top, 1, h - top, dark ? s.color("city") : LofiPalette.color("forsythia"))
            }
        }
    }

    /// 잎 색 [기본, 그늘, 셋째마다]. 겨울은 잎이 없다.
    static func crowns(_ season: Season) -> [String]? {
        switch season {
        case .spring: ["leaf-new", "leaf-new-dark"]
        case .summer: ["summer-1", "summer-2"]
        case .autumn: ["ginkgo", "autumn-3", "autumn-1"]
        case .winter: nil
        }
    }
}

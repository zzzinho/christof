/// 디자인(테마). 지역과 따로 고른다. 지역은 날씨·시각·해달·이벤트를, 테마는 그림 세계를 정한다. 시안의 THEMES 다.
/// 테마가 바꾸는 것: 창밖 마을(town), 창틀(frame), 고양이 자리의 동물(pets), 평소 옷(outfit).
/// 벽·책상·시계·스탠드와 이벤트 모양은 테마와 관계없이 같다. 지역별 먼 풍경(남산타워, 광안대교)은 기본 테마에만 있다.
public struct Theme: Hashable, Sendable, Identifiable {
    /// 설정에 저장되는 키라 바꾸지 않는다.
    public let id: String
    public let name: LocalizedName
    let town: any OutsideEffect
    let frame: any WindowFrame
    let pets: Pets
    let outfit: Outfit

    public static let lofi = Theme(id: "lofi", name: LocalizedName(en: "Default", ko: "기본"), town: KoreanTownEffect(), frame: SashFrame(), pets: .cat, outfit: .pajama)
    public static let henesys = Theme(id: "henesys", name: LocalizedName(en: "Henesys", ko: "헤네시스"), town: HenesysEffect(), frame: CottageFrame(), pets: .mushroom, outfit: .bowman)
    public static let all = [lofi, henesys]

    /// 목록에 없는 id(없어진 테마 등)는 기본 테마다.
    public static func named(_ id: String?) -> Theme {
        all.first { $0.id == id } ?? .lofi
    }

    public static func == (a: Theme, b: Theme) -> Bool { a.id == b.id }
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

/// 고양이 자리의 동물. 자세 이름과 자리는 고양이와 같고, lit·unlit 은 불 켬·끔 색표에 덮어쓰는 글자 → 색이다.
struct Pets: Sendable {
    let back: CatPose
    let side: CatPose
    let walk: CatPose
    let eat: CatPose
    let curled: CatPose
    var lit: [Character: String] = [:]
    var unlit: [Character: String] = [:]

    static let cat = Pets(back: .back, side: .side, walk: .walk, eat: .eat, curled: .curled)

    func colors(lightOn: Bool) -> [Character: String] {
        Sprites.colors(lightOn: lightOn).merging(lightOn ? lit : unlit) { $1 }
    }
}

/// 창틀. 창밖을 그린 뒤 그 위에 칠한다.
protocol WindowFrame: Sendable {
    func draw(_ g: inout DotGrid, _ L: RoomLayout)
}

/// 아파트 샷시: 흰 PVC 틀에 미닫이 두 짝. 가운데는 두 짝의 문틀이 겹쳐 굵고, 크리센트 잠금이 달렸다.
struct SashFrame: WindowFrame {
    func draw(_ t: inout DotGrid, _ L: RoomLayout) {
        let (x0, x1, y0, sill) = (L.x0, L.x1, L.y0, L.sill)
        let sash = LofiPalette.color("sash")
        for y in y0..<sill {
            for x in x0..<x1 where !(x >= x0 + 2 && x < x1 - 2 && y >= y0 + 2) {
                t.set(x, y, y == y0 ? LofiPalette.color("sash-light") : sash)
            }
        }
        let midX = jsRound(Double(x0 + x1) / 2)
        t.rect(midX - 1, y0 + 2, 3, sill - y0 - 2, sash)
        t.rect(midX, y0 + 2, 1, sill - y0 - 2, LofiPalette.color("sash-dark"))
        t.rect(midX - 1, jsRound(Double(y0) + Double(sill - y0) * 0.55), 1, 2, LofiPalette.color("outline"))
    }
}

/// 버섯집 나무 창: 위 두 모서리를 둥글게 깎은 창 구멍과 가운데 세로 문살. 아파트 샷시는 한국 아파트로 읽혀 헤네시스에 맞지 않는다.
struct CottageFrame: WindowFrame {
    func draw(_ t: inout DotGrid, _ L: RoomLayout) {
        let (x0, x1, y0, sill) = (L.x0, L.x1, L.y0, L.sill)
        let r = 7.0, left = x0 + 2, right = x1 - 2, top = y0 + 2
        let lit = LofiPalette.color("desk-lit"), light = LofiPalette.color("wood-light")
        for y in y0..<sill {
            for x in x0..<x1 {
                let cx = Double(x) + 0.5, cy = Double(y) + 0.5
                let corner = jsHypot(max(0, Double(left) + r - cx, cx - (Double(right) - r)), max(0, Double(top) + r - cy))
                if x >= left, x < right, y >= top, corner <= r { continue }
                t.set(x, y, y == y0 ? light : lit)
            }
        }
        let midX = jsRound(Double(x0 + x1) / 2)
        t.rect(midX - 1, y0 + 2, 2, sill - y0 - 2, lit)
        t.rect(midX, y0 + 2, 1, sill - y0 - 2, light)
    }
}

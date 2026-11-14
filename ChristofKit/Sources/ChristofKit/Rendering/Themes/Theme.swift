/// 디자인(테마). 지역이 하나씩 단다(RegionLooks.theme). 시안의 THEMES 다.
/// 테마가 바꾸는 것: 창밖 마을(town), 창틀(frame), 고양이 자리의 동물(pets), 평소 옷(outfit).
/// 벽·책상·시계·스탠드와 이벤트 모양은 테마와 관계없이 같다. 지역별 먼 풍경(남산타워, 광안대교)은 기본 테마에만 있다.
public struct Theme: Equatable, Sendable {
    /// 시안 비교(scenes.json)가 시안의 THEMES 키로 쓴다.
    public let id: String
    let town: any OutsideEffect
    let frame: any WindowFrame
    let pets: Pets
    let outfit: Outfit

    public static let lofi = Theme(id: "lofi", town: KoreanTownEffect(), frame: SashFrame(), pets: .cat, outfit: .pajama)

    public static func == (a: Theme, b: Theme) -> Bool { a.id == b.id }
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


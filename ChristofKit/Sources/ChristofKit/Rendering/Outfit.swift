/// 사람 스프라이트의 옷 칸(o 기본, d 그늘, r 테두리 빛, j 바지·치마)을 칠하는 색. 시안의 OUTFITS 다.
/// paint 는 무늬다: 옷 칸 글자, 칸 i, 옷 첫 줄부터 센 줄 k, 그 줄을 받아 색 이름을 돌려준다. nil 이면 기본·그늘 색이다.
struct Outfit: Sendable {
    let base: String
    let shade: String
    var rim = "hoodie-rim"
    var skirt = "curtain-dark"
    var paint: (@Sendable (Character, Int, Int, String) -> String?)?
    /// 등에 멘 것. 사람 스프라이트 왼쪽 위 칸을 받는다. 머리가 길어도 보이게 머리 위에 얹는다.
    var back: (@Sendable (inout DotGrid, Int, Int) -> Void)?

    func color(_ ch: Character, _ i: Int, _ k: Int, _ row: String) -> String? {
        switch ch {
        case "j": skirt
        case "r": rim
        case "o": paint?(ch, i, k, row) ?? base
        case "d": paint?(ch, i, k, row) ?? shade
        default: nil
        }
    }

    /// 평소 옷: 무늬 없는 오트밀 극세사 잠옷
    static let pajama = Outfit(base: "pajama", shade: "pajama-dark", rim: "pajama-rim")
    /// 설날 색동 한복: 첫 줄은 깃, 소매 두 칸은 줄마다 색동
    static let seollal = Outfit(base: "hanbok", shade: "hanbok", skirt: "pouch") { _, i, k, row in
        collar(k) ?? (isSleeve(i, row) ? saekdong[k % saekdong.count] : nil)
    }
    /// 정월대보름 쪽빛 저고리
    static let daeboreum = Outfit(base: "pouch-knot", shade: "curtain-dark", skirt: "lamp-body") { _, _, k, _ in collar(k) }
    /// 부처님오신날 연분홍 가디건, 가운데 단추
    static let buddha = Outfit(base: "spring-1", shade: "spring-2") { _, i, k, row in button(i, k, row, "santa-trim") }
    /// 추석 옥색 한복
    static let chuseok = Outfit(base: "hanbok-jade", shade: "summer-2", skirt: "hanbok") { _, _, k, _ in collar(k) }
    /// 새해 첫날 남색 코트, 가운데 금단추
    static let newYear = Outfit(base: "beanie", shade: "beanie-dark") { _, i, k, row in button(i, k, row, "pouch-gold") }
    /// 할로윈 줄무늬 니트
    static let halloween = Outfit(base: "pumpkin", shade: "pumpkin-dark") { _, _, k, _ in k % 4 >= 2 ? "witch" : nil }
    /// 크리스마스 노르딕 니트
    static let christmas = Outfit(base: "santa", shade: "santa-dark", rim: "pouch-light") { _, i, k, _ in
        k == 3 || k == 5 ? "santa-trim" : k == 4 ? (i % 2 == 1 ? "summer-2" : "santa-trim") : nil
    }

    /// 헤네시스 평소 옷: 궁수 마을이라 초록 궁수 튜닉. 등 위쪽 그늘(d)이 내려놓은 후드로 읽히고, 허리에 가죽 띠를 맨다.
    /// 뒷모습이라 옷만으로는 궁수로 읽히지 않아 오른쪽 어깨에 화살통을 멘다. 화살깃이 머리 오른쪽으로 솟는다.
    static let bowman = Outfit(base: "summer-1", shade: "summer-2", rim: "leaf-new", paint: { _, _, k, _ in k == 6 ? "pot" : nil }) { g, left, top in
        g.sprite(left + 11, top + 22, Sprites.quiver, ["a": "hanbok-collar", "q": "wood-light", "Q": "pot"])
    }

    private static let saekdong = ["pouch", "pouch-gold", "summer-1", "pouch-knot", "hanbok"]

    private static func collar(_ k: Int) -> String? {
        k == 0 ? "hanbok-collar" : nil
    }

    private static func button(_ i: Int, _ k: Int, _ row: String, _ color: String) -> String? {
        k % 2 == 1 && i == row.count / 2 - 1 ? color : nil
    }

    /// 뒷모습 소매: 옷 칸(o·d)이 있는 줄의 양 끝 두 칸
    private static func isSleeve(_ i: Int, _ row: String) -> Bool {
        let cloth = row.enumerated().filter { "od".contains($0.element) }.map(\.offset)
        guard let first = cloth.first, let last = cloth.last else { return false }
        return i <= first + 1 || i >= last - 1
    }
}

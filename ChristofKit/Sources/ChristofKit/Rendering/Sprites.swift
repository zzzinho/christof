// 시안의 SPRITES·SPRITE_COLORS 를 옮겼다. 불빛(스탠드·트리)이 오른쪽에 있어 오른쪽 가장자리에 따뜻한 테두리 빛이 진다.

enum Sprites {
    static let colors: [Character: String] = [
        "h": "hair-brown", "H": "hair-brown-rim", "F": "headphone-band", "n": "headphone-band", "k": "headphone-steel", "K": "headphone-cup", "C": "headphone-band", "s": "skin", "S": "hoodie-rim", "e": "outline",
        "c": "cheese", "R": "cheese-rim", "T": "cheese-dark",
        "L": "lamp", "b": "lamp-body", "Y": "lamp-light", "m": "mug-dark", "M": "mug", "t": "steam",
        "1": "book-1", "2": "book-2", "3": "book-3", "l": "plant", "p": "pot",
    ]
    /// 불을 끈 낮에는 테두리 빛 자리를 바탕색으로 칠한다.
    static let unlitColors = colors.merging(["H": "hair-brown", "S": "skin", "R": "cheese", "Y": "lamp"]) { $1 }

    static func colors(lightOn: Bool) -> [Character: String] {
        lightOn ? colors : unlitColors
    }

    static let lamp = [
        "...LLLL...",
        "..LLLLLLb.",
        ".LLLLLLLb.",
        "..YYYY..b.",
        ".........b",
        ".........b",
        "........b.",
        ".......b..",
        "......b...",
        ".....b....",
        "....b.....",
        "..bbbbbb..",
    ]
    static let mug = [".t.t...", "t.t....", ".t.t...", ".......", "mmmmm..", "mMMMmmm", "mMMMm.m", "mMMMmmm", ".mmm..."]
    static let books = [".11111111.", "2222222222", ".33333333.", "1111111111"]
    static let plant = [".l.l.", "lLlLl", ".lLl.", "ppppp", ".ppp."]
    /// 김은 성긴 점이라 그릇 줄만 윤곽선을 두른다.
    static let rice = [".t.t.", ".www.", "BBBBB", ".BBB."]
    // 오방색 두루주머니: 청·백 주름 입, 황 끈 고리와 福 패, 흑 매듭, 적 몸통.
    static let bokjumeoni = [".WBWBW.", "Y.YKY.Y", ".YRRRY.", "RRRRRRR", "RRYYYRR", ".RRRRR."]
    static let bokjumeoniColors: [Character: String] = ["B": "pouch-knot", "R": "pouch", "Y": "pouch-gold", "W": "hanbok-collar", "K": "clock-hand"]
    /// 오른쪽 어깨에서 왼쪽 허리로 비스듬히 멘 가죽 화살통. 위로 화살깃 셋이 솟는다.
}

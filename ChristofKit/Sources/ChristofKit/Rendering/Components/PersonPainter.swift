/// 책상 앞(카메라 쪽)에 앉아 창을 바라보는 여성의 뒷모습. 허리 아래는 위젯 아래 끝에서 잘린다.
enum PersonPainter {
    struct Sprite {
        let rows: [String]
        /// 옷이 시작하는 줄
        let body: Int
        /// 헤드폰(에어팟 맥스): F 머리띠, k 강철 팔, K 알루미늄 귀덮개, C 쿠션. n 은 목 뒤로 두른 머리띠(neckBand)에만 쓴다.
        /// 목에 건 귀덮개와 목 뒤로 두른 머리띠, 각각의 아랫줄
        let neck: [String]
        let neckBottom: Int
        let neckBand: [String]
        let neckBandBottom: Int
        /// 늘어진 머리. 단발 끝줄(start)부터 한 해에 rows 줄 자라고, 폭은 머리 폭(cols)이다.
        /// 어깨 줄(shoulder)부터 한 칸씩 퍼지고, strands 는 끝의 결 자리다.
        let fall: (start: Int, shoulder: Int, cols: (Int, Int), strands: [Int], rows: Int)
    }

    static let sprite = Sprite(
        rows: [
            "................",
            ".....FFFFFF.....",
            "....FhhhhhHF....",
            "...khhhhhhhhk...",
            "...khhhhhhhhk...",
            "..khhhhhhhhhHk..",
            "KKChhhhhhhhhHCKK",
            "KKChhhhhhhhhHCKK",
            "KKChhhhhhhhhHCKK",
            "KKChhhhhhhhhHCKK",
            "KKChhhhhhhhhHCKK",
            "...hhhhhhhhhH...",
            "....hhhhhhhH....",
            "......sssS......",
            "...dddddddddd...",
            ".ooddddddddddoo.",
            "ooooddddddddooor",
            "oooooddddddoooor",
            "ooooooddddooooor",
            "oooooooooooooorr",
            "oooooodooooooorr",
            "oooooodooooooorr",
            "oooooodooooooorr",
            "oooooodooooooorr",
            "oooooodooooooorr",
            "oooooodooooooorr",
        ],
        body: 14,
        neck: [".KKC........CKK.", ".KKC........CKK.", ".KKC........CKK.", ".KKC........CKK."],
        neckBottom: 15,
        neckBand: ["...nnnnnnnnnn..."],
        neckBandBottom: 14,
        fall: (12, 15, (3, 12), [5, 9], 6))

    static func draw(_ g: inout DotGrid, _ L: RoomLayout, _ s: DotScene) {
        let p = sprite, top = L.personTop, left = jsRound(Double(L.personX) - Double(p.rows[0].count) / 2)
        let lit = Sprites.colors(lightOn: s.lightOn)
        // 헤드폰을 벗으면 머리띠(F)·팔(k)·귀덮개(K·C) 자리를 비운다.
        // 팔 자리까지 머리색으로 채우면 관자놀이가 귀 자리보다 넓어져 양쪽이 튀어나와 보인다.
        let colors = s.headwear == .headphones ? lit : lit.filter { !"FkKC".contains($0.key) }
        for (j, row) in p.rows.enumerated() {
            for (i, ch) in row.enumerated() {
                // 불을 끈 낮에는 옷의 테두리 빛(r) 자리도 기본 색이다.
                let cloth: Character = s.lightOn || ch != "r" ? ch : "o"
                let name = j >= p.body && "odrj".contains(ch) ? s.outfit.color(cloth, i, j - p.body, row) : colors[ch]
                if let name { g.set(left + i, top + j, LofiPalette.color(name)) }
            }
        }
        // 목 뒤로 두른 머리띠는 늘어진 머리 밑에 깔려 단발일 때만 보인다.
        if s.headwear == .neck { g.sprite(L.personX, top + p.neckBandBottom, p.neckBand, lit) }
        // 늘어진 머리는 목에서 좁아지지 않고 머리 폭 그대로 내려와 어깨에 얹히며 한 칸씩 퍼진다. 끝 두 줄을 한 칸씩 깎아 둥글게 하고(단발은 한 줄),
        // 네 줄 넘게 자라면 끝 세 줄에 진한 결을 넣고 결 자리 끝을 비워 머리끝이 갈라져 보이게 한다. 오른쪽 끝 칸은 테두리 빛이다.
        // 머리는 한 달에 1cm 남짓 자라서 한 해 6줄(3pt 한 줄이 2cm 쯤)이다. 더 길게 늘이거나 매끈한 판으로 두면 등에 붙인 판처럼 보였다.
        let rows = 1 + jsRound(s.hair * Double(p.fall.rows)), (c0, c1) = p.fall.cols
        let hair = LofiPalette.color(lit["h"]!), rim = LofiPalette.color(lit["H"]!), dark = LofiPalette.color("hair-brown-dark")
        for j in 0..<rows {
            let y = p.fall.start + j, fromEnd = rows - 1 - j, flare = y >= p.fall.shoulder ? 1 : 0
            let inset = max(0, (rows >= 3 ? 2 : 1) - fromEnd), i0 = c0 - flare + inset, i1 = c1 + flare - inset
            for i in stride(from: i0, through: i1, by: 1) {
                let strand = rows >= 4 && fromEnd <= 3 && p.fall.strands.contains(i)
                if strand && fromEnd == 0 { continue }
                g.set(left + i, top + y, strand ? dark : i == i1 ? rim : hair)
            }
        }
        // 목에 건 귀덮개는 늘어진 머리 위에 걸친다.
        if s.headwear == .neck { g.sprite(L.personX, top + p.neckBottom, p.neck, lit) }
        s.outfit.back?(&g, left, top)
        for look in s.looks.person { look.draw(&g, L.personX, top, s) }
    }
}

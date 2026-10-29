/// 창턱 화분, large 의 선반, 책상과 책·머그, 스탠드
enum RoomPainter {
    static func draw(_ g: inout DotGrid, _ L: RoomLayout, _ s: DotScene) {
        let colors = Sprites.colors(lightOn: s.lightOn), looks = s.looks.room
        if let sill = looks.first(where: { $0.spot == .sill }) {
            sill.draw(&g, L, s)
        } else {
            g.ink { $0.sprite(L.sillX(s.catState) + 1, L.sill, Sprites.plant, colors) }
        }
        if L.H > 80 { g.ink { drawShelf(&$0, L.x1 + 6, L.W - 6, jsRound(Double(L.H) * 0.38)) } }

        // 책상: 윗면은 불빛(낮에는 창) 가까울수록 밝다. 트리가 있으면 그 앞에서 끝난다.
        let deskRight = L.tree ? L.treeX - 11 : L.W
        let litX = s.lightOn ? L.light.x : Double(L.x0 + L.x1) / 2
        let deskLit = LofiPalette.color("desk-lit"), woodLight = LofiPalette.color("wood-light")
        g.ink { t in
            for x in 0..<deskRight {
                t.set(x, L.deskTop, blend(deskLit, woodLight, abs(Double(x) - litX) / (Double(L.W) * 0.5), x, L.deskTop))
            }
            t.rect(0, L.deskTop + 1, deskRight, L.H - L.deskTop - 1, LofiPalette.color("wood"))
        }
        // 밥 먹는 동안은 책·머그와 밥이 아닌 책상 물건(달력)을 치우고 그 자리에 밥을 놓는다.
        if let dish = L.catSpot(s.catState).dish {
            if let food = looks.lazy.compactMap({ $0 as? DeskItem }).first(where: \.food) {
                food.place(&g, dish, L)
            } else {
                g.ink { $0.sprite(dish, L.deskTop + 1, Array(Sprites.rice[1...]), ["w": "hanbok-collar", "B": "hanbok-jade"]) }
                g.sprite(dish, L.deskTop - 2, Array(Sprites.rice[..<1]), ["t": "steam"])
            }
        } else {
            g.ink { $0.sprite(L.personX - 14, L.deskTop + 1, Sprites.books, colors) }
            drawMug(&g, L.personX - 8, L.deskTop + 1, colors)
            for look in looks where look.spot == .desk { look.draw(&g, L, s) }
        }
        if let lamp = looks.first(where: { $0.spot == .lamp }) {
            lamp.draw(&g, L, s)
        } else {
            g.ink { $0.sprite(L.lampX, L.deskTop + 1, Sprites.lamp, colors) }
        }
        for look in looks where look.spot == .wall { look.draw(&g, L, s) }
    }

    /// 김은 성긴 점이라 윤곽선을 두르면 검은 덩어리가 된다. 잔만 두른다.
    static func drawMug(_ g: inout DotGrid, _ x: Int, _ bottom: Int, _ colors: [Character: String]) {
        g.ink { $0.sprite(x, bottom, Array(Sprites.mug[4...]), colors) }
        g.sprite(x, bottom - 5, Array(Sprites.mug[..<4]), colors)
    }

    /// large 의 빈 벽에 둔 선반: 세워 둔 책과 늘어진 화분
    static func drawShelf(_ g: inout DotGrid, _ x0: Int, _ x1: Int, _ y: Int) {
        g.rect(x0, y, x1 - x0, 1, LofiPalette.color("wood-light"))
        g.rect(x0 + 1, y + 1, x1 - x0 - 2, 1, LofiPalette.color("wood-dark"))
        var books = SeededRandom(seed: 19)
        for i in 0..<6 {
            let h = books.int(5, 8)
            g.rect(x0 + 2 + i * 2, y - h, 2, h, LofiPalette.color("book-\(i % 3 + 1)"))
        }
        let px = x1 - 5
        g.sprite(px, y, Sprites.plant, Sprites.colors)
        let plant = LofiPalette.color("plant"), plantDark = LofiPalette.color("plant-dark")
        for (dx, length) in [(-2, 9), (0, 15), (2, 6)] {
            for j in 0..<length { g.set(px + dx + (j % 4 == 3 ? 1 : 0), y + 2 + j, j % 2 == 1 ? plantDark : plant) }
        }
    }
}

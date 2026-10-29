import Foundation

/// 방 안 모양은 자리를 바꾸거나(창턱 화분 자리, 스탠드 자리) 더한다(책상 위, 벽).
enum RoomSpot {
    case sill, lamp, desk, wall
}

/// 윤곽선은 모양이 스스로 정한다(거미줄 같은 가는 선은 두르지 않는다).
protocol RoomLook: Sendable {
    var spot: RoomSpot { get }
    func draw(_ g: inout DotGrid, _ L: RoomLayout, _ s: DotScene)
}

/// 책상 위 사람 왼쪽에 두는 물건. 책상 위 고양이(곁에서 보기·쓰다듬기)와 그 곁 물건보다 왼쪽이다.
/// food 면 밥 먹는 시각에 사람 몫 밥 대신 놓는다.
struct DeskItem: RoomLook {
    let rows: [String]
    let colors: [Character: String]
    var food = false
    var spot: RoomSpot { .desk }

    func draw(_ g: inout DotGrid, _ L: RoomLayout, _ s: DotScene) {
        place(&g, L.personX - 30, L)
    }

    func place(_ g: inout DotGrid, _ x: Int, _ L: RoomLayout) {
        g.ink { $0.sprite(x, L.deskTop + 1, rows, colors) }
    }

    static let tteokguk = DeskItem(rows: [".t.t.", "cgccc", "BBBBB", ".BBB."], colors: ["t": "steam", "c": "hanbok-collar", "g": "summer-1", "B": "pouch-knot"], food: true)
    /// 새해 첫날 탁상 달력: 고리, 1월 빨간 머리띠, 날짜 칸(일요일 빨강·토요일 파랑), 받침. 연하장은 일본 넨가조로 읽혀서 쓰지 않는다.
    static let calendar = DeskItem(rows: [".k..k.", "PPPPPP", "rWWWWb", "rWWWWb", "MMMMMM"],
                                   colors: ["k": "clock-hand", "P": "pouch", "r": "santa", "W": "hanbok-collar", "b": "pouch-knot", "M": "mug-dark"])
    static let bureom = DeskItem(rows: [".nNn.", "NnNnN", "BBBBB", ".BBB."], colors: ["n": "wood-light", "N": "branch", "B": "mug-dark"], food: true)
    static let songpyeon = DeskItem(rows: [".pWg.", "pWgWp", "MMMMM"], colors: ["p": "hanbok", "W": "hanbok-collar", "g": "summer-1", "M": "mug"], food: true)
}

/// 창턱 화분 자리를 차지하는 물건. lit 은 불을 켰을 때만 바꾸는 색이다.
struct SillItem: RoomLook {
    let rows: [String]
    let colors: [Character: String]
    var lit: [Character: String] = [:]
    var dx = 0
    var spot: RoomSpot { .sill }

    func draw(_ g: inout DotGrid, _ L: RoomLayout, _ s: DotScene) {
        let colors = s.lightOn ? colors.merging(lit) { $1 } : colors
        g.ink { $0.sprite(L.sillX(s.catState) + dx, L.sill, rows, colors) }
    }

    static let lotusBowl = SillItem(rows: [".P.P.", "PpPpP", "lllll", ".BBB."], colors: ["P": "spring-1", "p": "spring-2", "l": "plant", "B": "pouch-knot"])
    static let pumpkin = SillItem(rows: [
        "....s....",
        ".ooosooo.",
        "oOYoooYOo",
        "oOYYoYYOo",
        "oOooYooOo",
        "oOYYYYYOo",
        ".ooooooo.",
    ], colors: ["s": "plant-dark", "o": "pumpkin", "O": "pumpkin-dark", "Y": "pumpkin-dark"], lit: ["Y": "lamp-light"], dx: -1)
}

/// 방 오른쪽 위 구석의 거미줄: 구석에서 뻗는 바퀴살과 둥근 줄
struct Cobweb: RoomLook {
    var spot: RoomSpot { .wall }

    func draw(_ g: inout DotGrid, _ L: RoomLayout, _ s: DotScene) {
        let cx = Double(L.W) - 0.5, cy = 0.0, c = LofiPalette.color("star-dim")
        func set(_ deg: Double, _ r: Double) {
            g.set(cx + cos(deg * Double.pi / 180) * r, cy + sin(deg * Double.pi / 180) * r, c)
        }
        for deg in [95.0, 125, 150, 175] {
            for r in stride(from: 0.0, through: 11, by: 0.5) { set(deg, r) }
        }
        // 고리 사이를 3칸 넘게 띄워야 도트로 줄었을 때 뭉쳐 보이지 않는다. 각도는 시안처럼 더해 가며 센다.
        for r in [4.0, 7.5, 11] {
            var deg = 95.0
            while deg <= 175 {
                set(deg, r)
                deg += 40 / r
            }
        }
    }
}

/// 스탠드 대신 방 구석에 둔 트리와 그 앞의 선물. 벽 불빛 중심과 사람·책상 자리도 트리에 맞춰 바뀐다(RoomLayout).
struct ChristmasTree: RoomLook {
    var spot: RoomSpot { .lamp }

    func draw(_ g: inout DotGrid, _ L: RoomLayout, _ s: DotScene) {
        g.ink { Self.drawTree(&$0, L.treeX, L.H) }
        g.ink { t in
            t.sprite(L.treeX - 7, L.H, ["RRgRR", "RRgRR", "ggggg", "RRgRR"], ["R": "santa", "g": "pouch-gold"])
            t.sprite(L.treeX + 6, L.H, ["GGrG", "rrrr", "GGrG"], ["G": "summer-1", "r": "santa-trim"])
        }
    }

    /// 크기와 관계없이 높이 40칸이다. 층마다 아래로 넓어지고, 층 아래 끝과 왼쪽은 그늘이다.
    static func drawTree(_ g: inout DotGrid, _ cx: Int, _ bottom: Int) {
        let top = bottom - 40, rows = 37
        func halfAt(_ r: Int) -> Int {
            let tier = min(2, r / 12)
            return jsRound(Double(1 + tier * 2) + Double(r - tier * 12) * 0.45)
        }
        let tree = LofiPalette.color("tree"), dark = LofiPalette.color("tree-dark")
        for r in 0..<rows {
            let half = halfAt(r), tierEnd = r % 12 == 11 || r == rows - 1
            for x in (cx - half)...(cx + half) {
                g.set(x, top + r, tierEnd || Double(x) < Double(cx) - Double(half) / 3 ? dark : tree)
            }
        }
        var lights = SeededRandom(seed: 23)
        let palette = ["bulb-1", "bulb-2", "bulb-3", "bulb-4", "lamp-light"]
        for _ in 0..<18 {
            let r = lights.int(3, rows - 2), half = halfAt(r)
            let x = cx + jsRound(lights(-0.8...0.8) * Double(half))
            g.set(x, top + r, LofiPalette.color(palette[lights.int(0, palette.count - 1)]))
        }
        let star = LofiPalette.color("lamp-light")
        g.rect(cx, top - 2, 1, 3, star)
        g.rect(cx - 1, top - 1, 3, 1, star)
        g.rect(cx - 3, top + rows, 7, bottom - top - rows, LofiPalette.color("pot"))
    }
}

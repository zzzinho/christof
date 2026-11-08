/// 구성 요소 자리. 격자 크기마다 따로 계산한다. 시안의 layout() 이다.
struct RoomLayout {
    let W: Int
    let H: Int
    let deskTop: Int
    let sill: Int
    let x0: Int
    let x1: Int
    let y0: Int
    let tree: Bool
    let treeX: Int
    let lampX: Int
    let personX: Int
    let personTop: Int
    let clock: (x: Int, y: Int)
    let cat: (x: Int, y: Int)
    /// 창 유리 [x, y, w, h]
    let view: (x: Int, y: Int, w: Int, h: Int)
    /// 벽을 데우는 불빛 중심
    let light: (x: Double, y: Double)
    let pets: Pets

    init(cols W: Int, rows H: Int, tree: Bool, pets: Pets = .cat) {
        self.pets = pets
        let wide = W > H
        self.W = W
        self.H = H
        self.tree = tree
        deskTop = H - 7
        sill = deskTop - 2
        x0 = jsRound(Double(W) * (wide ? 0.06 : 0.04))
        x1 = x0 + jsRound(Double(W) * (wide ? 0.5 : 0.6))
        y0 = jsRound(Double(H) * 0.1)
        treeX = W - 9
        lampX = jsRound(Double(W) * (wide ? 0.92 : 0.95))
        personX = jsRound(Double(W) * (wide ? (tree ? 0.72 : 0.74) : (tree ? 0.6 : 0.72)))
        personTop = H - PersonPainter.sprite.rows.count
        clock = (x1 + 7, y0 + 4)
        cat = (x0 + 9, sill)
        view = (x0 + 2, y0 + 2, x1 - x0 - 4, sill - y0 - 2)
        light = tree ? (Double(treeX), Double(H - 20)) : (Double(lampX - 2), Double(deskTop - 9))
    }

    /// 고양이 상태마다 자리. front 면 사람 앞에 그린다.
    /// item 은 곁에 두는 이벤트 물건 자리 [가운데, 바닥]이다. 어깨 위 고양이는 곁에 바닥이 없어 창턱 고양이 자리에 둔다.
    /// 창턱 화분 자리. 책상에 앉은 고양이가 창 오른쪽 끝 앞을 가리면(small·large 의 곁·쓰다듬기, medium·large 의 밥 먹기)
    /// 고양이와 책상 위 곁 물건보다 왼쪽으로 옮긴다.
    func sillX(_ state: DotScene.CatState) -> Int {
        let spot = catSpot(state), width = spot.pose.rows[0].count
        guard spot.front, spot.bottom > sill, spot.left <= x1 - 4, spot.left + width >= x1 - 10 else { return x1 - 7 }
        return min(spot.left, spot.item.y > sill ? spot.item.x - 3 : spot.left) - 4
    }

    func catSpot(_ state: DotScene.CatState) -> CatSpot {
        switch state {
        case .window: CatSpot(pose: pets.back, x: cat.x, bottom: sill, item: (cat.x + 9, sill))
        case .sleep: CatSpot(pose: pets.curled, x: x0 + 10, bottom: sill, item: (x0 + 20, sill))
        case .walk: CatSpot(pose: pets.walk, x: x0 + 12, bottom: sill, item: (x0 + 23, sill))
        case .pet:
            CatSpot(pose: pets.side, x: personX - 15, bottom: deskTop + 1, item: (personX - 24, deskTop + 1), front: true,
                    arm: ((personX - 6, personTop + 15), (personX - 12, deskTop - 10)))
        case .shoulder: CatSpot(pose: pets.curled, x: personX + 1, bottom: personTop + 18, item: (cat.x, sill), front: true)
        case .beside: CatSpot(pose: pets.back, x: personX - 14, bottom: deskTop + 1, item: (personX - 24, deskTop + 1), front: true)
        // small 은 고양이 왼쪽에 자리가 없어 물건을 창턱에 둔다.
        case .eat:
            CatSpot(pose: pets.eat, x: personX - 28, bottom: deskTop + 1, item: (cat.x, sill), front: true,
                    bowl: (personX - 20, deskTop + 1), dish: personX - 13)
        }
    }
}

struct CatSpot {
    let pose: CatPose
    let x: Int
    let bottom: Int
    let item: (x: Int, y: Int)
    var front = false
    /// 쓰다듬는 팔 [어깨, 손끝]
    var arm: (from: (x: Int, y: Int), to: (x: Int, y: Int))?
    /// 고양이 밥그릇
    var bowl: (x: Int, y: Int)?
    /// 사람 몫 밥 자리. 밥 먹는 동안은 책과 머그를 치우고 그 자리에 둔다.
    var dish: Int?

    var left: Int { jsRound(Double(x) - Double(pose.rows[0].count) / 2) }
    var head: (x: Double, y: Int) { (Double(left) + pose.head.x, bottom - pose.rows.count + pose.head.y) }
}

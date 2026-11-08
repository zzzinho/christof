import Foundation

/// 창밖, 창틀, 창턱, 왼쪽 얇은 커튼
enum WindowPainter {
    // 쌓는 순서. 조각구름이 달을 가리면 보름달도 초승달처럼 보여서 해·달을 구름 앞에 그린다.
    // 이벤트 모양은 sky, ground, glass 깊이에 끼운다.
    static let sky: [any OutsideEffect] = [SkyEffect(), StarEffect(), CloudEffect(), SunEffect(), MoonEffect()]
    static let weather: [any OutsideEffect] = [RainEffect(), SnowEffect(), FogEffect()]

    static func draw(_ g: inout DotGrid, _ L: RoomLayout, _ s: DotScene) {
        let (x0, x1, y0, sill) = (L.x0, L.x1, L.y0, L.sill)
        g.ink { t in
            let v = L.view
            t.within(v.x, v.y, v.w, v.h) { t in
                let looks = s.looks.window
                for effect in sky { effect.draw(&t, v.w, v.h, s) }
                for look in looks { look.sky(&t, v.w, v.h, s) }
                LightningEffect().draw(&t, v.w, v.h, s)
                s.theme.town.draw(&t, v.w, v.h, s)
                for look in looks { look.ground(&t, v.w, v.h, s) }
                for effect in weather { effect.draw(&t, v.w, v.h, s) }
                for look in looks { look.glass(&t, v.w, v.h, s) }
            }
            s.theme.frame.draw(&t, L)
            t.rect(x0 - 2, sill, x1 - x0 + 4, 2, LofiPalette.color("wood-light"))
        }
        let curtain = LofiPalette.color("curtain"), curtainDark = LofiPalette.color("curtain-dark")
        g.ink { t in
            for y in (y0 - 2)..<L.deskTop {
                let right = x0 + 3 + jsRound(sin(Double(y) * 0.4) * 0.7 + (Double(y) > Double(L.H) * 0.5 ? 1 : 0))
                for x in max(0, x0 - 4)..<max(max(0, x0 - 4), right) {
                    t.set(x, y, (x + 1) % 3 == 0 ? curtainDark : curtain)
                }
            }
        }
        for look in s.looks.window { look.frame(&g, L, s) }
    }
}

/// 창밖 효과 하나. 좌표는 유리 기준 칸이고 w×h 는 유리 크기다.
protocol OutsideEffect: Sendable {
    func draw(_ g: inout DotGrid, _ w: Int, _ h: Int, _ s: DotScene)
}

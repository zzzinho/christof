import SwiftUI


struct SunEffect: OutsideEffect {
    func draw(_ g: inout DotGrid, _ w: Int, _ h: Int, _ s: DotScene) {
        guard let (cx, cy, r) = Self.circle(s, w, h) else { return }
        g.ring(cx, cy, r, 2, s.color("sky-4"))
        g.disc(cx, cy, r, LofiPalette.color(s.sunAltitude < 10 ? "sun-low" : "sun-high"))
    }

    static func circle(_ s: DotScene, _ w: Int, _ h: Int) -> (Double, Double, Double)? {
        s.sunPoint.map { bodyCircle($0, w, h, radius: 9) }
    }
}

/// 해·달 원. 반지름은 pt 다. 지평선(고도 0°)은 뒷산 능선 꼭대기(drawMountains 의 base − 8pt)에, 고도 75° 는 유리 높이 10% 에 둔다.
/// 지평선을 유리 비율로 두었더니 medium·small 에서 능선이 하늘 절반을 덮어 고도 30° 보름달이 산 뒤에 숨었다.
func bodyCircle(_ point: CelestialPosition.Point, _ w: Int, _ h: Int, radius: Double) -> (Double, Double, Double) {
    let skyline = skyline(h)
    return ((point.x * Double(w)).rounded(.down) + 0.5, (skyline - point.rise * (skyline - Double(h) * 0.1)).rounded(.down) + 0.5, radius / DotGrid.dot + 0.3)
}

func skyline(_ h: Int) -> Double {
    Double(jsRound(Double(h) * 0.86)) - 60 / DotGrid.dot - Double(h) * 0.08
}

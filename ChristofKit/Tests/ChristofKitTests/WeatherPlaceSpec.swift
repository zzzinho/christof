import CoreLocation
import Foundation
import Testing
@testable import ChristofKit

private let registry = CountryRegistry.standard
private let seoul = registry.region(id: "KR.seoul")!
private let busan = registry.region(id: "KR.busan")!
private let henesys = registry.region(id: "KR.henesys")!
private let daejeon = CLLocation(latitude: 36.3504, longitude: 127.3845)
private let resolver = AutoRegionResolver(timeout: .milliseconds(50)) { registry.region(at: $0) }

@Suite("날씨는 내 위치에서")
struct WeatherPlaceSpec {
    @Test("어느 지역을 그리든 날씨는 내 위치에서 받는다")
    func myLocation() async {
        let app = await resolver.resolve(app: henesys, fallback: busan) { .location(daejeon) }
        let widget = await resolver.resolve(widget: seoul, fallback: busan) { .location(daejeon) }
        #expect(app.region == henesys)
        #expect(widget.region == seoul)
        #expect(app.weather == .location(latitude: 36.3504, longitude: 127.3845))
        #expect(widget.weather == app.weather)
    }

    @Test("위치 권한이 없으면 위치로 마지막에 고른 지역의 날씨를 받고, 권한이 없다고 남긴다")
    func denied() async {
        let result = await resolver.resolve(app: henesys, fallback: seoul) { .denied }
        #expect(result.weather == .denied(seoul))
        #expect(result.weather.latitude == seoul.latitude)
    }

    @Test("위치를 받지 못하면 위치로 마지막에 고른 지역의 날씨를 받고, 받지 못했다고 남긴다")
    func unavailable() async {
        let result = await resolver.resolve(widget: henesys, fallback: busan) { .unavailable }
        #expect(result.weather == .unavailable(busan))
    }

    @Test("위젯이 위치를 받지 못하면 지역을 골랐어도 그 사실과 날씨를 받은 지역을 남긴다")
    func widgetFailure() throws {
        let failures = try #require(WidgetFailures(region: AutoRegion(region: henesys, source: .widget, weather: .unavailable(busan)), weatherFailed: false, at: .now))
        #expect(failures.location == .unavailable)
        #expect(failures.region == busan)
        #expect(!failures.drewFallbackRegion)
    }
}

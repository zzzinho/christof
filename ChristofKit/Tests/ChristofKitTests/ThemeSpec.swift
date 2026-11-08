import Foundation
import Testing
@testable import ChristofKit

@Suite("디자인 고르기")
struct ThemeSpec {
    private let seoul = CountryRegistry.standard.region(id: "KR.seoul")!
    private let now = Date(timeIntervalSince1970: 1_790_000_000)

    private func theme(app: SceneSettings, widget: Theme? = nil) -> Theme {
        SceneContextFactory().context(now: now, region: seoul, realForecast: nil, settings: app, widgetTheme: widget).theme
    }

    @Test("디자인을 고른 적이 없으면 기본 디자인으로 그린다")
    func defaultTheme() {
        #expect(theme(app: .live) == .lofi)
    }

    @Test("디자인이 없던 버전이 저장한 설정도 기본 디자인으로 읽는다")
    func oldSettings() throws {
        let old = try JSONDecoder().decode(SceneSettings.self, from: Data(#"{"occasion":{"automatic":{}},"language":"ko"}"#.utf8))
        #expect(old.theme == .lofi)
    }

    @Test("앱에서 고른 디자인으로 위젯을 그린다")
    func appTheme() {
        #expect(theme(app: SceneSettings(theme: .henesys)) == .henesys)
    }

    @Test("위젯 편집에서 고른 디자인이 앱 설정보다 먼저다")
    func widgetTheme() {
        #expect(theme(app: SceneSettings(theme: .henesys), widget: .lofi) == .lofi)
        #expect(theme(app: .live, widget: .henesys) == .henesys)
    }

    @Test("목록에서 빠진 디자인은 기본 디자인이 된다")
    func removedTheme() {
        var settings = SceneSettings()
        settings.themeID = "gone"
        #expect(theme(app: settings) == .lofi)
    }

    @Test("디자인을 바꿔도 날씨·해달·이벤트는 고른 지역 기준이다")
    func regionDecidesTheScene() {
        let settings = SceneSettings(fixedDate: now, forcedWeather: .snow, occasion: .manual(occasionID: "KR.christmas"))
        let lofi = SceneContextFactory().context(now: now, region: seoul, realForecast: nil, settings: settings)
        let henesys = SceneContextFactory().context(now: now, region: seoul, realForecast: nil, settings: settings, widgetTheme: .henesys)
        #expect(henesys.weather == lofi.weather)
        #expect(henesys.sun.altitude == lofi.sun.altitude)
        #expect(henesys.occasions.map(\.id) == lofi.occasions.map(\.id))
    }
}

import Foundation
import Testing
@testable import ChristofKit

private let seoul = CountryRegistry.standard.region(id: "KR.seoul")!
private let busan = CountryRegistry.standard.region(id: "KR.busan")!
private let now = Date(timeIntervalSinceReferenceDate: 815_000_000)

@Suite("위치·날씨를 받지 못했을 때")
struct FallbackSpec {
    @Test("실제 예보를 받지 못하면 맑음으로 그린다")
    func clearWithoutForecast() {
        let context = SceneContextFactory().context(now: now, region: seoul, realForecast: nil, settings: .live)
        #expect(context.weather?.condition == .clear)
    }

    @Test("고른 시각이 예보 밖이면 맑음으로 그린다")
    func clearOutsideForecast() {
        let forecast = WeatherForecast(samples: [.forced(.rain, at: now)])
        let settings = SceneSettings(fixedDate: now.addingTimeInterval(-86_400))
        let context = SceneContextFactory().context(now: now, region: seoul, realForecast: forecast, settings: settings)
        #expect(context.weather?.condition == .clear)
    }

    @Test("위젯이 위치와 날씨를 모두 받으면 남길 실패가 없다")
    func nothingFailed() {
        #expect(WidgetFailures(region: AutoRegion(region: seoul, source: .location), weatherFailed: false, at: now) == nil)
    }

    @Test("위젯이 위치 권한이 없으면 그 사실과 대신 그린 지역을 남긴다")
    func locationDenied() throws {
        let failures = try #require(WidgetFailures(region: AutoRegion(region: busan, source: .denied), weatherFailed: false, at: now))
        #expect(failures.location == .denied)
        #expect(failures.region == busan)
        #expect(!failures.weather)
    }

    @Test("위젯이 날씨를 받지 못하면 그 사실을 남긴다")
    func weatherFailed() throws {
        let failures = try #require(WidgetFailures(region: AutoRegion(region: seoul, source: .location), weatherFailed: true, at: now))
        #expect(failures.weather)
        #expect(failures.location == nil)
        #expect(failures.at == now)
    }

    @Test("앱이나 위젯 편집에서 고른 지역은 위치를 보지 않으니 위치 실패가 아니다")
    func chosenRegionIsNotLocationFailure() {
        #expect(WidgetFailures(region: AutoRegion(region: busan, source: .app), weatherFailed: false, at: now) == nil)
        #expect(WidgetFailures(region: AutoRegion(region: busan, source: .widget), weatherFailed: false, at: now) == nil)
    }

    @Test("위젯이 남긴 실패를 앱이 읽고, 다음에 모두 받으면 지워진다")
    func storeRoundTrip() {
        let suite = "christof.tests.\(UUID().uuidString)"
        defer { UserDefaults.standard.removePersistentDomain(forName: suite) }
        let store = SceneSettingsStore(suiteName: suite)
        let failures = WidgetFailures(region: AutoRegion(region: busan, source: .unavailable), weatherFailed: true, at: now)
        store.saveWidgetFailures(failures)
        #expect(store.loadWidgetFailures() == failures)
        store.saveWidgetFailures(nil)
        #expect(store.loadWidgetFailures() == nil)
    }
}

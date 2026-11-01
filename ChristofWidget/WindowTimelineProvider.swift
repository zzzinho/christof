import ChristofKit
import os
import WidgetKit

struct WindowEntry: TimelineEntry {
    let date: Date
    let context: SceneContext
    let language: AppLanguage
}

struct WindowTimelineProvider: AppIntentTimelineProvider {
    var weather: any WeatherProviding = .standard
    var factory = SceneContextFactory()
    var store = SceneSettingsStore()

    func placeholder(in context: Context) -> WindowEntry {
        entry(at: .now, region: store.loadLocatedRegion(), forecast: nil, settings: .live)
    }

    // 위젯 갤러리·편집 화면은 바로 떠야 하므로 네트워크를 기다리지 않는다.
    func snapshot(for configuration: SelectRegionIntent, in context: Context) async -> WindowEntry {
        entry(at: .now, region: configuration.chosenRegion ?? store.loadLocatedRegion(), forecast: nil, settings: store.load())
    }

    func timeline(for configuration: SelectRegionIntent, in context: Context) async -> Timeline<WindowEntry> {
        let region = await region(for: configuration)
        let readAt = Date.now
        let settings = store.load()
        defer { store.markApplied(readAt: readAt) }
        let now = Date.now
        // 예보 실패(오프라인 등)는 날씨 없는 장면으로 그리고, 30분 뒤 다시 시도한다(하루 48회, 리로드 예산 40~70회 안).
        let forecast: WeatherForecast?
        do {
            forecast = try await weather.forecast(for: region)
        } catch {
            Self.logger.error("예보 실패 \(region.id, privacy: .public): \(error.localizedDescription, privacy: .public)")
            forecast = nil
        }
        // 시계 분침이 5분 눈금이라 5분 경계마다 다시 그린다.
        let step = 5.0 * 60
        let start = Date(timeIntervalSinceReferenceDate: (now.timeIntervalSinceReferenceDate / step).rounded(.down) * step)
        // 리로드는 1시간 뒤 요청하지만 시스템이 미룰 수 있어, 엔트리를 3시간치 만들어 그동안 시계가 멈추지 않게 한다.
        // 시각을 고정했으면 장면이 바뀌지 않으므로 하나면 된다.
        // chronod 는 타임라인 아카이브가 너무 크면 리로드를 통째로 버리고 placeholder 를 띄운다. 엔트리 하나가 크게(Canvas 도트)에서
        // 약 65KB 라, 1분 간격 180개(약 11MB)는 거부되고 36개(약 2.4MB)는 받아들여졌다. 한도 값은 공개되어 있지 않다.
        let count = settings.fixedDate == nil ? 36 : 1
        let entries = (0..<count).map { i in
            entry(at: start.addingTimeInterval(Double(i) * step), region: region, forecast: forecast, settings: settings)
        }
        let policy: TimelineReloadPolicy = .after(now.addingTimeInterval((forecast == nil ? 30 : 60) * 60))
        return Timeline(entries: entries, policy: policy)
    }

    private static let logger = Logger(subsystem: "com.christof.Christof", category: "widget")

    // "자동"이면 위젯이 위치를 직접 봐서, 앱을 열지 않아도 도시를 옮기면 바뀐다. 위치를 못 보면 앱이나 위젯이 마지막에 고른 지역을 쓴다.
    private func region(for configuration: SelectRegionIntent) async -> Region {
        if let chosen = configuration.chosenRegion { return chosen }
        let auto = await AutoRegionResolver().resolve(fallback: store.loadLocatedRegion()) {
            await WidgetLocation.current().map(LocationReading.location) ?? .unavailable
        }
        Self.logger.info("자동 지역 \(auto.region.id, privacy: .public): \(String(describing: auto.source), privacy: .public)")
        if auto.source == .location { store.saveLocatedRegion(auto.region) }
        return auto.region
    }

    private func entry(at date: Date, region: Region, forecast: WeatherForecast?, settings: SceneSettings) -> WindowEntry {
        WindowEntry(date: date, context: factory.context(now: date, region: region, realForecast: forecast, settings: settings), language: settings.language)
    }
}

import ChristofKit
import os
import SwiftUI
import WidgetKit

struct PreviewScreen: View {
    private let store = SceneSettingsStore()
    @State private var saved: SceneSettings
    @State private var settings: PreviewSettings
    @State private var realForecast: Result<WeatherForecast, any Error>?
    @State private var located: Region
    @State private var autoSource: AutoRegion.Source?
    @State private var savedAt: Date?
    @State private var applyStatus: WidgetApplyStatus?
    @State private var widgetFailures: WidgetFailures?
    @State private var reloads = 0
    private let weather: any WeatherProviding = .standard
    #if os(macOS)
    @Environment(AppUpdater.self) private var updater: AppUpdater?
    #endif
    private let factory = SceneContextFactory()

    init() {
        let store = SceneSettingsStore()
        let saved = store.load()
        _saved = State(initialValue: saved)
        _settings = State(initialValue: PreviewSettings(saved: saved))
        _located = State(initialValue: store.loadLocatedRegion())
        _widgetFailures = State(initialValue: store.loadWidgetFailures())
    }

    private var region: Region { settings.region ?? located }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SettingsPanel(settings: $settings, located: located, autoSource: autoSource, widgetFailures: widgetFailures, forecastStatus: forecastStatus)
                SaveBar(hasChanges: settings.sceneSettings != saved, status: applyStatus, save: save, refresh: refresh)
                TimelineView(.everyMinute) { timeline in
                    // 실패는 위 상태 문구로 보여 주고, 장면은 맑음으로 그린다(SceneContextFactory).
                    let context = factory.context(now: timeline.date, region: region, realForecast: try? realForecast?.get(), settings: settings.sceneSettings)
                    WindowPreviews(context: context)
                }
                WidgetGuide()
                #if os(macOS)
                if let updater { UpdatePanel(updater: updater) }
                #endif
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        // 화면 문구(String Catalog)와 날짜 형식이 저장 전에도 고른 언어를 따른다.
        .environment(\.locale, settings.language.locale)
        // 위젯의 "자동" 지역은 앱을 열 때 위치로 고른다. 위치를 못 받으면 마지막에 고른 지역을 덮지 않고 그 이유를 보여 준다.
        .task(id: reloads) {
            let auto = await AutoRegionResolver().resolve(fallback: located) { await DeviceLocation.current() }
            autoSource = auto.source
            Self.logger.info("자동 지역 \(auto.region.id, privacy: .public): \(String(describing: auto.source), privacy: .public)")
            guard auto.source == .location else { return }
            store.saveLocatedRegion(auto.region)
            if auto.region != located {
                located = auto.region
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
        .task(id: savedAt) {
            guard let savedAt else { return }
            let placedWidgets = (try? await WidgetCenter.shared.currentConfigurations())?.count
            // 위젯은 앱에 알릴 길이 없어, 위젯이 남긴 시각을 1초마다 본다.
            while !Task.isCancelled {
                let status = WidgetApplyStatus(savedAt: savedAt, appliedAt: store.loadAppliedAt(), placedWidgets: placedWidgets)
                applyStatus = status
                widgetFailures = store.loadWidgetFailures()
                if status != .applying { return }
                try? await Task.sleep(for: .seconds(1))
            }
        }
        .task(id: ForecastRequest(region: region, reload: reloads)) {
            realForecast = nil
            let result: Result<WeatherForecast, any Error>
            do {
                result = .success(try await weather.forecast(for: region))
            } catch {
                Self.weatherLogger.error("예보 실패 \(region.id, privacy: .public): \(error.localizedDescription, privacy: .public)")
                result = .failure(error)
            }
            // 지역이 바뀌어 취소된 요청이 새 지역의 상태를 덮지 않게 한다.
            if !Task.isCancelled { realForecast = result }
        }
    }

    private static let logger = Logger(subsystem: "com.christof.Christof", category: "location")
    private static let weatherLogger = Logger(subsystem: "com.christof.Christof", category: "weather")

    private struct ForecastRequest: Hashable {
        let region: Region
        let reload: Int
    }

    private func save() {
        saved = settings.sceneSettings
        store.save(saved)
        // 저장한 뒤의 시각이어야, 저장 전에 옛 설정을 읽은 리로드를 적용으로 보지 않는다.
        savedAt = .now
        WidgetCenter.shared.reloadAllTimelines()
    }

    // 앱의 위치·예보를 다시 받고 위젯도 다시 그린다. 위젯이 다시 읽으면 저장할 때처럼 적용 상태와 위젯 실패를 새로 읽는다.
    private func refresh() {
        reloads += 1
        savedAt = .now
        WidgetCenter.shared.reloadAllTimelines()
    }

    private var forecastStatus: Text {
        switch realForecast {
        case nil: Text("Loading the real forecast…")
        case .success(let forecast): status(of: forecast)
        case .failure: Text("Couldn't load the weather, so the scene shows Clear.")
        }
    }

    private func status(of forecast: WeatherForecast) -> Text {
        guard let first = forecast.samples.first, let last = forecast.samples.last else { return Text("The real forecast is empty, so the scene shows Clear.") }
        let format = Date.FormatStyle(date: .abbreviated, time: .shortened, locale: settings.language.locale, timeZone: region.timeZone)
        let range = Text("Real forecast: \(first.time.formatted(format)) to \(last.time.formatted(format))")
        guard !settings.usesCurrentTime, forecast.sample(at: settings.customDate) == nil else { return range }
        return range + Text(verbatim: "\n") + Text("The chosen time is outside the forecast, so the scene shows Clear. Choose the weather yourself.")
    }
}

private struct SettingsPanel: View {
    @Binding var settings: PreviewSettings
    let located: Region
    let autoSource: AutoRegion.Source?
    let widgetFailures: WidgetFailures?
    let forecastStatus: Text

    private static let occasions = CountryRegistry.standard.profiles.flatMap(\.occasions)

    var body: some View {
        let language = settings.language
        let region = settings.region ?? located
        VStack(alignment: .leading, spacing: 12) {
            LabeledContent("Language") {
                Picker("Language", selection: $settings.language) {
                    // 언어 이름은 그 언어로 쓴다.
                    ForEach(AppLanguage.allCases, id: \.self) { Text(verbatim: $0.locale.localizedString(forLanguageCode: $0.rawValue) ?? $0.rawValue).tag($0) }
                }
                .labelsHidden()
            }
            LabeledContent("Region") {
                Picker("Region", selection: $settings.region) {
                    Text("Auto (\(located.name[language]))").tag(Region?.none)
                    ForEach(CountryRegistry.standard.regions) { Text($0.name[language]).tag(Optional($0)) }
                }
                .labelsHidden()
            }
            if settings.region == nil, let reason = autoRegionReason(language: language) {
                reason
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            if let widgetLocation = widgetLocationFailure(language: language) {
                widgetLocation
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            LabeledContent("Time") {
                Picker("Time", selection: $settings.usesCurrentTime) {
                    Text("Auto").tag(true)
                    Text("Custom").tag(false)
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .fixedSize()
            }
            if !settings.usesCurrentTime {
                // 지역 시간대로 보여줘야 "서울 저녁 7시" 처럼 고를 수 있다.
                DatePicker("Time in \(region.name[language])", selection: $settings.customDate)
                    .environment(\.timeZone, region.timeZone)
            }
            LabeledContent("Weather") {
                Picker("Weather", selection: $settings.forcedCondition) {
                    Text("Auto").tag(WeatherCondition?.none)
                    ForEach(WeatherCondition.allCases, id: \.self) { Text($0.name[language]).tag(Optional($0)) }
                }
                .labelsHidden()
            }
            if settings.forcedCondition == nil {
                forecastStatus
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                if let widgetFailures, widgetFailures.weather {
                    Text("On \(Self.time(widgetFailures.at, language: language)), the widget couldn't load the weather, so it showed Clear.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            LabeledContent("Event") {
                Picker("Event", selection: $settings.occasion) {
                    Text("Auto").tag(OccasionSelection.automatic)
                    ForEach(Self.occasions) { Text($0.name[language]).tag(OccasionSelection.manual(occasionID: $0.id)) }
                }
                .labelsHidden()
            }
            if settings.occasion != .automatic {
                Text("Shows the chosen holiday whatever the date. Sunrise, sunset, and full moon stay automatic.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func autoRegionReason(language: AppLanguage) -> Text? {
        let name = located.name[language]
        switch autoSource {
        case .denied: return Text("Location access is off, so Auto uses \(name). Allow location access for Christof in Settings.")
        case .unavailable: return Text("Couldn't get your location, so Auto uses \(name).")
        case .location, .widget, .app, nil: return nil
        }
    }

    private func widgetLocationFailure(language: AppLanguage) -> Text? {
        guard let widgetFailures, let location = widgetFailures.location else { return nil }
        let time = Self.time(widgetFailures.at, language: language)
        let name = widgetFailures.region?.name[language] ?? widgetFailures.regionID
        return switch location {
        case .denied: Text("On \(time), the widget had no location access, so it showed \(name).")
        case .unavailable: Text("On \(time), the widget couldn't get your location, so it showed \(name).")
        }
    }

    // 위젯이 실패한 때는 기기 시각으로 보인다. 어제 일일 수 있어 날짜도 붙인다.
    private static func time(_ date: Date, language: AppLanguage) -> String {
        date.formatted(Date.FormatStyle(locale: language.locale).month(.abbreviated).day().hour().minute())
    }
}

private struct SaveBar: View {
    let hasChanges: Bool
    let status: WidgetApplyStatus?
    let save: () -> Void
    let refresh: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button("Save", action: save)
                .buttonStyle(.borderedProminent)
            Button("Refresh", systemImage: "arrow.clockwise", action: refresh)
            if !hasChanges, status == .applying {
                ProgressView()
                    .controlSize(.small)
            }
            message
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var message: Text {
        if hasChanges {
            return Text("Save to apply these settings to the widget. A widget given its own region in Edit Widget keeps that region.")
        }
        switch status {
        case .applying: return Text("Applying to the widget…")
        case .applied: return Text("Applied to the widget.")
        case .noWidget: return Text("Saved. No widget is placed yet.")
        case nil: return Text("These settings are on the widget.")
        }
    }
}

private struct WindowPreviews: View {
    let context: SceneContext
    @Environment(\.locale) private var locale

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(summary)
                .font(.footnote)
                .foregroundStyle(.secondary)
            ForEach(WindowSize.allCases, id: \.self) { preview(style: $0) }
        }
    }

    // 위젯 VoiceOver 가 읽는 문장 앞에 날짜를 붙인다.
    private var summary: String {
        let date = context.date.formatted(Date.FormatStyle(date: .abbreviated, time: .omitted, locale: locale, timeZone: context.region.timeZone))
        return "\(date) · \(WindowView.accessibilityLabel(context, locale: locale))"
    }

    private func preview(style: WindowSize) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(Self.title(of: style))
                .font(.caption)
                .foregroundStyle(.secondary)
            WindowView(context: context)
                .frame(width: style.referenceSize.width, height: style.referenceSize.height)
                .clipShape(.rect(cornerRadius: 22))
        }
    }

    private static func title(of style: WindowSize) -> LocalizedStringKey {
        switch style {
        case .compact: "Small"
        case .regular: "Medium"
        case .expanded: "Large"
        }
    }
}

#if os(macOS)
private struct UpdatePanel: View {
    @Bindable var updater: AppUpdater

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Updates")
                .font(.headline)
            Toggle("Install updates automatically", isOn: $updater.installsAutomatically)
            switch updater.notice {
            case .none:
                EmptyView()
            case .upToDate:
                Text("Christof is up to date.")
            case .available(let version):
                HStack(spacing: 12) {
                    Text("Version \(version) is available.")
                    Button("Update", action: updater.update)
                }
            case .installsOnQuit(let version):
                HStack(spacing: 12) {
                    Text("Version \(version) installs when you close the app.")
                    Button("Update", action: updater.update)
                }
            }
            Text("Checks for a new version each time the app opens.")
                .foregroundStyle(.secondary)
        }
        .font(.callout)
    }
}
#endif

private struct WidgetGuide: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Adding the widget")
                .font(.headline)
            #if os(macOS)
            Text("Right-click the desktop → Edit Widgets → find Christof and place it on the desktop.")
            Text("To give one widget its own region, right-click it → Edit Widget.")
            #else
            Text("Touch and hold the Home Screen → Edit → Add Widget → choose Christof.")
            Text("To give one widget its own region, touch and hold it → Edit Widget.")
            #endif
            Text("Selecting the widget opens this app. Change the region, language, time, weather, or event here and save to apply them to the widget.")
            Text("Version \(Self.info("CFBundleShortVersionString")) (\(Self.info("CFBundleVersion")))")
                .foregroundStyle(.secondary)
        }
        .font(.callout)
    }

    private static func info(_ key: String) -> String {
        Bundle.main.object(forInfoDictionaryKey: key) as? String ?? "?"
    }
}

import ChristofKit
import SwiftUI
import WidgetKit

struct PreviewScreen: View {
    private let store = SceneSettingsStore()
    @State private var saved: SceneSettings
    @State private var settings: PreviewSettings
    @State private var realForecast: Result<WeatherForecast, any Error>?
    @State private var located: Region
    private let weather: any WeatherProviding = .standard
    private let factory = SceneContextFactory()

    init() {
        let store = SceneSettingsStore()
        let saved = store.load()
        _saved = State(initialValue: saved)
        _settings = State(initialValue: PreviewSettings(saved: saved))
        _located = State(initialValue: store.loadLocatedRegion())
    }

    private var region: Region { settings.region ?? located }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SettingsPanel(settings: $settings, located: located, forecastStatus: forecastStatus)
                SaveBar(hasChanges: settings.sceneSettings != saved, save: save)
                TimelineView(.everyMinute) { timeline in
                    // 실패는 위 상태 문구로 보여주고, 장면은 날씨 없이 그린다.
                    let context = factory.context(now: timeline.date, region: region, realForecast: try? realForecast?.get(), settings: settings.sceneSettings)
                    WindowPreviews(context: context)
                }
                WidgetGuide()
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        // 화면 문구(String Catalog)와 날짜 형식이 저장 전에도 고른 언어를 따른다.
        .environment(\.locale, settings.language.locale)
        // 위젯의 "자동" 지역은 앱을 열 때 위치로 고른다.
        .task {
            let here = await RegionGeocoder().region(at: await DeviceLocation.current())
            store.saveLocatedRegion(here)
            if here != located {
                located = here
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
        .task(id: region) {
            realForecast = nil
            let result: Result<WeatherForecast, any Error>
            do {
                result = .success(try await weather.forecast(for: region))
            } catch {
                result = .failure(error)
            }
            // 지역이 바뀌어 취소된 요청이 새 지역의 상태를 덮지 않게 한다.
            if !Task.isCancelled { realForecast = result }
        }
    }

    private func save() {
        saved = settings.sceneSettings
        store.save(saved)
        WidgetCenter.shared.reloadAllTimelines()
    }

    private var forecastStatus: Text {
        switch realForecast {
        case nil: Text("Loading the real forecast…")
        case .success(let forecast): status(of: forecast)
        case .failure(let error): Text("Couldn't load the real forecast: \(error.localizedDescription)")
        }
    }

    private func status(of forecast: WeatherForecast) -> Text {
        guard let first = forecast.samples.first, let last = forecast.samples.last else { return Text("The real forecast is empty.") }
        let format = Date.FormatStyle(date: .abbreviated, time: .shortened, locale: settings.language.locale, timeZone: region.timeZone)
        let range = Text("Real forecast: \(first.time.formatted(format)) to \(last.time.formatted(format))")
        guard !settings.usesCurrentTime, forecast.sample(at: settings.customDate) == nil else { return range }
        return range + Text(verbatim: "\n") + Text("The chosen time is outside the forecast, so the scene has no weather. Choose the weather yourself.")
    }
}

private struct SettingsPanel: View {
    @Binding var settings: PreviewSettings
    let located: Region
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
}

private struct SaveBar: View {
    let hasChanges: Bool
    let save: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button("Save", action: save)
                .buttonStyle(.borderedProminent)
            (hasChanges
                ? Text("Save to apply the language, time, weather, and event to the widget. Each widget picks its region in Edit Widget.")
                : Text("These settings are on the widget."))
                .font(.footnote)
                .foregroundStyle(.secondary)
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

private struct WidgetGuide: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Adding the widget")
                .font(.headline)
            #if os(macOS)
            Text("Right-click the desktop → Edit Widgets → find Christof and place it on the desktop.")
            Text("To choose the region, right-click the widget → Edit Widget.")
            #else
            Text("Touch and hold the Home Screen → Edit → Add Widget → choose Christof.")
            Text("To choose the region, touch and hold the widget → Edit Widget.")
            #endif
            Text("Selecting the widget opens this app. Change the language, time, weather, or event here and save to apply them to the widget.")
            Text("Version \(Self.info("CFBundleShortVersionString")) (\(Self.info("CFBundleVersion")))")
                .foregroundStyle(.secondary)
        }
        .font(.callout)
    }

    private static func info(_ key: String) -> String {
        Bundle.main.object(forInfoDictionaryKey: key) as? String ?? "?"
    }
}

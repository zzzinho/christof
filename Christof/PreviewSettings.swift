import ChristofKit
import Foundation

/// 화면에서 편집 중인 값. 저장하면 위젯에 반영된다.
struct PreviewSettings: Equatable {
    var region: Region?
    var usesCurrentTime: Bool
    var customDate: Date
    var forcedCondition: WeatherCondition?
    var occasion: OccasionSelection
    var language: AppLanguage

    init(saved: SceneSettings) {
        region = saved.region
        usesCurrentTime = saved.fixedDate == nil
        customDate = saved.fixedDate ?? .now
        forcedCondition = saved.forcedWeather
        occasion = saved.occasion
        language = saved.language
    }

    var sceneSettings: SceneSettings {
        SceneSettings(region: region, fixedDate: usesCurrentTime ? nil : customDate, forcedWeather: forcedCondition, occasion: occasion, language: language)
    }
}

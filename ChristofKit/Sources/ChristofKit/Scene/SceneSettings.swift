import Foundation

/// 사용자가 앱에서 지정해 위젯에 저장하는 값. nil 은 실제 값(지금 시각, 실제 날씨)을 쓴다는 뜻이다.
public struct SceneSettings: Hashable, Sendable, Codable {
    /// nil 은 "자동"(위치로 고른 지역)이다. 위젯 편집에서 지역을 고른 위젯은 이 값을 쓰지 않는다.
    public var regionID: String?
    public var fixedDate: Date?
    public var forcedWeather: WeatherCondition?
    public var occasion: OccasionSelection
    public var language: AppLanguage

    public init(region: Region? = nil, fixedDate: Date? = nil, forcedWeather: WeatherCondition? = nil, occasion: OccasionSelection = .automatic, language: AppLanguage = .english) {
        self.regionID = region?.id
        self.fixedDate = fixedDate
        self.forcedWeather = forcedWeather
        self.occasion = occasion
        self.language = language
    }

    // 언어·지역이 없던 버전이 저장한 값도 읽는다.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            fixedDate: try container.decodeIfPresent(Date.self, forKey: .fixedDate),
            forcedWeather: try container.decodeIfPresent(WeatherCondition.self, forKey: .forcedWeather),
            occasion: try container.decode(OccasionSelection.self, forKey: .occasion),
            language: try container.decodeIfPresent(AppLanguage.self, forKey: .language) ?? .english)
        regionID = try container.decodeIfPresent(String.self, forKey: .regionID)
    }

    /// 목록에서 빠진 지역(예전 버전의 대구 등)은 nil 이라 "자동"이 된다.
    public var region: Region? {
        regionID.flatMap { CountryRegistry.standard.region(id: $0) }
    }

    public static let live = SceneSettings()
}

import Foundation

/// 순수 값이라 위젯 타임라인 엔트리에 그대로 담는다.
public struct SceneContext: Sendable {
    public let date: Date
    public let region: Region
    public let weather: WeatherSample?
    public let sun: SunState
    public let moon: MoonState
    public let season: Season
    public let occasions: [Occasion]

    public var theme: Theme { region.looks.theme }

    public init(date: Date, region: Region, weather: WeatherSample?, sun: SunState, moon: MoonState, season: Season, occasions: [Occasion]) {
        self.date = date
        self.region = region
        self.weather = weather
        self.sun = sun
        self.moon = moon
        self.season = season
        self.occasions = occasions
    }
}

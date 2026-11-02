import Foundation

public struct SceneContextFactory: Sendable {
    private let countries: CountryRegistry
    private let universalOccasions: [Occasion]

    public init(countries: CountryRegistry = .standard, universalOccasions: [Occasion] = CelestialOccasions.all) {
        self.countries = countries
        self.universalOccasions = universalOccasions
    }

    public func context(now: Date, region: Region, realForecast: WeatherForecast?, settings: SceneSettings) -> SceneContext {
        let date = settings.fixedDate ?? now
        let forecast = settings.forcedWeather.map { WeatherForecast(samples: [.forced($0, at: date)]) } ?? realForecast
        return context(at: date, region: region, forecast: forecast, selection: settings.occasion)
    }

    /// 수동 선택은 국가 이벤트만 바꾸고, 해·달 이벤트는 늘 날짜로 판정한다.
    public func context(at date: Date, region: Region, forecast: WeatherForecast?, selection: OccasionSelection = .automatic) -> SceneContext {
        let profile = countries.profile(for: region.countryCode)
        return SceneContext(
            date: date,
            region: region,
            // 예보를 받지 못했거나 고른 시각이 예보 밖이면 맑음으로 그린다.
            weather: forecast?.sample(at: date) ?? .forced(.clear, at: date),
            sun: SolarCalculator.state(at: date, latitude: region.latitude, longitude: region.longitude, timeZone: region.timeZone),
            moon: MoonCalculator.state(at: date, latitude: region.latitude, longitude: region.longitude),
            season: profile?.season(at: date, in: region) ?? .meteorological(at: date, in: region),
            occasions: selection.pick(from: profile?.occasions ?? [], at: date, in: region)
                + universalOccasions.filter { $0.isActive(at: date, in: region) }
        )
    }
}

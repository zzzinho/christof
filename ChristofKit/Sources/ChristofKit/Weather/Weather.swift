import Foundation

public enum WeatherCondition: Sendable, Hashable, CaseIterable, Codable {
    case clear, partlyCloudy, overcast, fog, drizzle, rain, snow, thunderstorm

    public var name: LocalizedName {
        switch self {
        case .clear: LocalizedName(en: "Clear", ko: "맑음")
        case .partlyCloudy: LocalizedName(en: "Partly Cloudy", ko: "구름 조금")
        case .overcast: LocalizedName(en: "Overcast", ko: "흐림")
        case .fog: LocalizedName(en: "Fog", ko: "안개")
        case .drizzle: LocalizedName(en: "Drizzle", ko: "이슬비")
        case .rain: LocalizedName(en: "Rain", ko: "비")
        case .snow: LocalizedName(en: "Snow", ko: "눈")
        case .thunderstorm: LocalizedName(en: "Thunderstorm", ko: "뇌우")
        }
    }
}

public struct WeatherSample: Sendable, Hashable {
    public let time: Date
    public let condition: WeatherCondition
    /// 강수·안개·뇌우의 세기, 0...1.
    public let intensity: Double
    /// 0...1.
    public let cloudCover: Double
    public let temperatureCelsius: Double

    public init(time: Date, condition: WeatherCondition, intensity: Double, cloudCover: Double, temperatureCelsius: Double) {
        self.time = time
        self.condition = condition
        self.intensity = intensity
        self.cloudCover = cloudCover
        self.temperatureCelsius = temperatureCelsius
    }
}

public struct WeatherForecast: Sendable, Hashable {
    public let samples: [WeatherSample]

    public init(samples: [WeatherSample]) {
        self.samples = samples.sorted { $0.time < $1.time }
    }

    public func sample(at date: Date, maxAge: TimeInterval = 2 * 3600) -> WeatherSample? {
        guard let latest = samples.last(where: { $0.time <= date }) else { return nil }
        return date.timeIntervalSince(latest.time) <= maxAge ? latest : nil
    }
}

public protocol WeatherProviding: Sendable {
    func forecast(latitude: Double, longitude: Double) async throws -> WeatherForecast
}

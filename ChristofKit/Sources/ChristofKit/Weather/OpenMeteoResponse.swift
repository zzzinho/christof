import Foundation

enum OpenMeteoResponse {
    static func forecast(from data: Data) throws -> WeatherForecast {
        let body = try JSONDecoder().decode(Body.self, from: data)
        let hourly = body.hourly
        let counts = [hourly.temperature2m.count, hourly.weatherCode.count, hourly.cloudCover.count]
        guard counts.allSatisfy({ $0 == hourly.time.count }) else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "hourly 배열 길이가 서로 다르다: \(hourly.time.count), \(counts)"))
        }
        let current = sample(time: body.current.time, code: body.current.weatherCode, cloudCover: body.current.cloudCover, temperature: body.current.temperature2m)
        let hourlySamples = hourly.time.indices.compactMap { i in
            sample(time: hourly.time[i], code: hourly.weatherCode[i], cloudCover: hourly.cloudCover[i], temperature: hourly.temperature2m[i])
        }
        // 같은 시각이면 관측에 가까운 current 만 남긴다.
        return WeatherForecast(samples: hourlySamples.filter { $0.time != current?.time } + [current].compactMap { $0 })
    }

    // Open-Meteo 는 모델에 값이 없는 시각을 null 로 준다. 그 시각만 건너뛴다.
    private static func sample(time: TimeInterval, code: Int?, cloudCover: Double?, temperature: Double?) -> WeatherSample? {
        guard let code, let cloudCover, let temperature else { return nil }
        let weather = WMOWeatherCode.interpret(code)
        return WeatherSample(
            time: Date(timeIntervalSince1970: time),
            condition: weather.condition,
            intensity: weather.intensity,
            cloudCover: min(max(cloudCover / 100, 0), 1),
            temperatureCelsius: temperature
        )
    }

    private struct Body: Decodable {
        // convertFromSnakeCase 는 "temperature_2m" 을 temperature2m 으로 바꾸지 않아 키를 직접 적는다.
        enum Keys: String, CodingKey {
            case time, temperature2m = "temperature_2m", weatherCode = "weather_code", cloudCover = "cloud_cover"
        }

        struct Current: Decodable {
            typealias CodingKeys = Keys
            let time: TimeInterval
            let temperature2m: Double?
            let weatherCode: Int?
            let cloudCover: Double?
        }

        struct Hourly: Decodable {
            typealias CodingKeys = Keys
            let time: [TimeInterval]
            let temperature2m: [Double?]
            let weatherCode: [Int?]
            let cloudCover: [Double?]
        }

        let current: Current
        let hourly: Hourly
    }
}

import Foundation

public struct OpenMeteoWeatherProvider: WeatherProviding {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func forecast(latitude: Double, longitude: Double) async throws -> WeatherForecast {
        let (data, response) = try await session.data(from: OpenMeteoRequest.url(latitude: latitude, longitude: longitude))
        // ponytail: 상태 코드를 버린다. 재시도·백오프를 상태별로 나눌 때 상태 코드를 담은 에러 타입을 만든다.
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try OpenMeteoResponse.forecast(from: data)
    }
}

// 앱 미리보기와 위젯이 같은 출처를 쓰도록 기본값을 여기 한 곳에 둔다.
extension WeatherProviding where Self == OpenMeteoWeatherProvider {
    public static var standard: Self { .init() }
}

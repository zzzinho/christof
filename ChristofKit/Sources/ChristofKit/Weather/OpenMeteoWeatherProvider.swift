import Foundation

public struct OpenMeteoWeatherProvider: WeatherProviding {
    private let session: URLSession
    private let timeout: Duration

    // 위젯 리로드는 30초쯤 넘으면 시스템이 끊는다(Watchdog provision violated). 위치(10초 시한) 뒤에 예보가 와도 그 안에 끝나게 10초로 둔다.
    public init(session: URLSession = .shared, timeout: Duration = .seconds(10)) {
        self.session = session
        self.timeout = timeout
    }

    public func forecast(latitude: Double, longitude: Double) async throws -> WeatherForecast {
        let request = URLRequest(url: OpenMeteoRequest.url(latitude: latitude, longitude: longitude), timeoutInterval: Double(timeout.components.seconds) + Double(timeout.components.attoseconds) / 1e18)
        let (data, response) = try await session.data(for: request)
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

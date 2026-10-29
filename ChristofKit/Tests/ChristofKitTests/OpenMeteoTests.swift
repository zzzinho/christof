import Foundation
import Synchronization
import Testing
@testable import ChristofKit

/// 2026-10-18 서울(37.5665, 126.978) 실제 응답에서 hourly 를 3개(UTC 04:00·05:00·06:00)만 남겼다.
private let seoulFixture = Data("""
{"latitude":37.55,"longitude":127.0,"generationtime_ms":0.07462501525878906,"utc_offset_seconds":0,"timezone":"GMT","timezone_abbreviation":"GMT","elevation":34.0,\
"current_units":{"time":"unixtime","interval":"seconds","temperature_2m":"°C","weather_code":"wmo code","cloud_cover":"%"},\
"current":{"time":1792298700,"interval":900,"temperature_2m":20.8,"weather_code":65,"cloud_cover":97},\
"hourly_units":{"time":"unixtime","temperature_2m":"°C","weather_code":"wmo code","cloud_cover":"%"},\
"hourly":{"time":[1792296000,1792299600,1792303200],"temperature_2m":[19.9,21.0,20.9],"weather_code":[63,65,65],"cloud_cover":[85,100,88]}}
""".utf8)

private func seoul(latitude: Double = 37.5665) -> Region {
    Region(id: "KR.seoul", name: LocalizedName(en: "Seoul", ko: "서울"), countryCode: "KR", latitude: latitude, longitude: 126.978, timeZone: TimeZone(identifier: "Asia/Seoul")!)
}

@Test func requestURLAsksForCurrentAndTwoDaysOfHourlyInUnixTime() throws {
    let url = OpenMeteoRequest.url(for: seoul())
    let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
    #expect(components.host == "api.open-meteo.com")
    #expect(components.path == "/v1/forecast")
    let query = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value) })
    #expect(query == [
        "latitude": "37.5665",
        "longitude": "126.978",
        "current": "temperature_2m,weather_code,cloud_cover",
        "hourly": "temperature_2m,weather_code,cloud_cover",
        "timeformat": "unixtime",
        "forecast_days": "2",
    ])
}

@Test func fixtureDecodesCurrentAndHourlyIntoTimeOrderedSamples() throws {
    let samples = try OpenMeteoResponse.forecast(from: seoulFixture).samples
    #expect(samples == [
        WeatherSample(time: Date(timeIntervalSince1970: 1792296000), condition: .rain, intensity: 2.0 / 3, cloudCover: 0.85, temperatureCelsius: 19.9),
        WeatherSample(time: Date(timeIntervalSince1970: 1792298700), condition: .rain, intensity: 1, cloudCover: 0.97, temperatureCelsius: 20.8),
        WeatherSample(time: Date(timeIntervalSince1970: 1792299600), condition: .rain, intensity: 1, cloudCover: 1, temperatureCelsius: 21.0),
        WeatherSample(time: Date(timeIntervalSince1970: 1792303200), condition: .rain, intensity: 1, cloudCover: 0.88, temperatureCelsius: 20.9),
    ])
}

@Test func responseWithMismatchedHourlyArraysIsRejected() {
    let broken = Data(String(decoding: seoulFixture, as: UTF8.self).replacingOccurrences(of: "[85,100,88]", with: "[85,100]").utf8)
    let error = #expect(throws: DecodingError.self) { try OpenMeteoResponse.forecast(from: broken) }
    guard case .dataCorrupted = error else {
        Issue.record("길이 검사가 아닌 다른 이유로 실패했다: \(String(describing: error))")
        return
    }
}

@Test func nullValuesSkipOnlyThatTime() throws {
    let text = String(decoding: seoulFixture, as: UTF8.self)
        .replacingOccurrences(of: "[85,100,88]", with: "[85,null,88]")
        .replacingOccurrences(of: "\"cloud_cover\":97", with: "\"cloud_cover\":null")
    let samples = try OpenMeteoResponse.forecast(from: Data(text.utf8)).samples
    #expect(samples.map(\.time.timeIntervalSince1970) == [1792296000, 1792303200])
}

private let light = 1.0 / 3, moderate = 2.0 / 3, heavy = 1.0

@Test(arguments: [
    (0, WeatherCondition.clear, 0.0), (1, .partlyCloudy, 0), (2, .partlyCloudy, 0), (3, .overcast, 0),
    (45, .fog, moderate), (48, .fog, moderate),
    // 이슬비 약/중/강, 어는 이슬비 약/강
    (51, .drizzle, light), (53, .drizzle, moderate), (55, .drizzle, heavy), (56, .drizzle, light), (57, .drizzle, heavy),
    // 비 약/중/강, 어는 비 약/강, 소나기 약/중/강
    (61, .rain, light), (63, .rain, moderate), (65, .rain, heavy), (66, .rain, light), (67, .rain, heavy),
    (80, .rain, light), (81, .rain, moderate), (82, .rain, heavy),
    // 눈 약/중/강, 싸락눈은 약, 눈 소나기 약/강
    (71, .snow, light), (73, .snow, moderate), (75, .snow, heavy), (77, .snow, light), (85, .snow, light), (86, .snow, heavy),
    // 뇌우는 보통, 우박 동반 뇌우는 강
    (95, .thunderstorm, moderate), (96, .thunderstorm, heavy), (99, .thunderstorm, heavy),
    // WMO 표에 없는 코드는 흐림으로 본다
    (4, .overcast, 0), (100, .overcast, 0), (-1, .overcast, 0),
] as [(Int, WeatherCondition, Double)])
func wmoCodeMapsToConditionAndIntensity(code: Int, condition: WeatherCondition, intensity: Double) {
    let result = WMOWeatherCode.interpret(code)
    #expect(result.condition == condition)
    #expect(result.intensity == intensity)
}

@Test(arguments: [
    ("current 시각에는 current 를 쓴다", 1792298700.0, 20.8 as Double?),
    ("current 와 다음 정시 사이에는 current 를 쓴다", 1792299000, 20.8),
    ("current 이전에는 직전 정시 hourly 를 쓴다", 1792297800, 19.9),
    ("current 이후 정시에는 그 hourly 를 쓴다", 1792299600, 21.0),
    ("마지막 샘플에서 2시간까지는 그 샘플을 쓴다", 1792303200 + 7200, 20.9),
    ("마지막 샘플에서 2시간이 넘으면 없다", 1792303200 + 7201, nil),
    ("첫 샘플보다 이르면 없다", 1792295999, nil),
])
func sampleAtPicksLatestCurrentOrHourlySample(rule: String, time: TimeInterval, temperature: Double?) throws {
    let forecast = try OpenMeteoResponse.forecast(from: seoulFixture)
    #expect(forecast.sample(at: Date(timeIntervalSince1970: time))?.temperatureCelsius == temperature, "\(rule)")
}

/// 응답을 요청 URL별로 나누어 병렬 테스트끼리 섞이지 않는다.
private final class StubURLProtocol: URLProtocol {
    static let responses = Mutex<[URL: (status: Int, body: Data)]>([:])

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func stopLoading() {}

    override func startLoading() {
        guard let url = request.url, let stub = Self.responses.withLock({ $0[url] }),
              let response = HTTPURLResponse(url: url, statusCode: stub.status, httpVersion: nil, headerFields: nil) else {
            client?.urlProtocol(self, didFailWithError: URLError(.resourceUnavailable))
            return
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: stub.body)
        client?.urlProtocolDidFinishLoading(self)
    }
}

private func stubbedProvider(region: Region, status: Int, body: Data) -> OpenMeteoWeatherProvider {
    StubURLProtocol.responses.withLock { $0[OpenMeteoRequest.url(for: region)] = (status, body) }
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [StubURLProtocol.self]
    return OpenMeteoWeatherProvider(session: URLSession(configuration: configuration))
}

@Test func http200ReturnsDecodedForecast() async throws {
    let region = seoul(latitude: 1)
    let forecast = try await stubbedProvider(region: region, status: 200, body: seoulFixture).forecast(for: region)
    #expect(forecast == (try OpenMeteoResponse.forecast(from: seoulFixture)))
}

// 본문이 정상 예보여도 상태 코드로 거른다. 실제 오류 본문은 {"error":true,"reason":"Latitude must be in range of -90 to 90°. Given: 137.5."} 꼴이다.
@Test(arguments: [400, 404, 429, 500, 503])
func nonOKStatusThrowsBadServerResponse(status: Int) async {
    let region = seoul(latitude: Double(status) / 10)
    let provider = stubbedProvider(region: region, status: status, body: seoulFixture)
    await #expect(throws: URLError(.badServerResponse)) { try await provider.forecast(for: region) }
}

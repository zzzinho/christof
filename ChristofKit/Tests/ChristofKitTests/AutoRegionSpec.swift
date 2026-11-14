import CoreLocation
import Testing
@testable import ChristofKit

private let registry = CountryRegistry.standard
private let seoul = registry.region(id: "KR.seoul")!
private let busan = registry.region(id: "KR.busan")!
private let cityHall = CLLocation(latitude: 37.5665, longitude: 126.9780)
private let here = WeatherPlace.location(latitude: 37.5665, longitude: 126.9780)
// 역지오코딩은 네트워크를 타서, 같은 판정을 하는 반지름 원으로 바꿔 끼운다.
private let resolver = AutoRegionResolver(timeout: .milliseconds(50)) { RegionGeocoder.region(at: $0, address: nil, registry: registry) }
private let daejeon = CLLocation(latitude: 36.3504, longitude: 127.3845)

@Suite("자동 지역")
struct AutoRegionSpec {
    @Test("위치가 서울 안이면 서울이고, 위치로 골랐다고 남긴다")
    func located() async {
        let result = await resolver.resolve(fallback: busan) { .location(cityHall) }
        #expect(result == AutoRegion(region: seoul, source: .location, weather: here))
    }

    @Test("서울·부산 안이면 그 도시를 그린다")
    func listedCity() {
        let address = RegionGeocoder.Address(cities: ["Gijang-gun", "Busan"], city: "Busan", countryCode: "KR")
        #expect(RegionGeocoder.region(at: cityHall, address: address, registry: registry) == registry.region(id: "KR.busan")!)
    }

    @Test("목록의 도시 밖이면 내 위치를 그 도시 이름과 기본 그림으로 그린다")
    func myLocation() {
        let address = RegionGeocoder.Address(cities: ["Yuseong-gu", "Daejeon"], city: "Daejeon", countryCode: "KR")
        let here = RegionGeocoder.region(at: daejeon, address: address, registry: registry)
        #expect(here.name.en == "Daejeon")
        #expect(here.latitude == 36.3504 && here.longitude == 127.3845)
        #expect(here.countryCode == "KR")
        #expect(here.timeZone == .current)
        #expect(here.looks.theme == .lofi)
    }

    @Test("역지오코딩이 안 되면 서울·부산 반지름 원으로 어림하고, 원 밖이면 이름 없는 내 위치다")
    func offline() {
        #expect(RegionGeocoder.region(at: cityHall, address: nil, registry: registry) == seoul)
        let here = RegionGeocoder.region(at: daejeon, address: nil, registry: registry)
        #expect(here.name == LocalizedName(en: "My Location", ko: "내 위치"))
        #expect(here.latitude == 36.3504)
    }

    @Test("위치 권한이 없으면 마지막에 고른 지역을 쓰고, 권한이 없다고 남긴다")
    func denied() async {
        let result = await resolver.resolve(fallback: seoul) { .denied }
        #expect(result == AutoRegion(region: seoul, source: .denied, weather: .denied(seoul)))
    }

    @Test("위치가 시한 안에 오지 않으면 마지막에 고른 지역을 쓰고, 받지 못했다고 남긴다")
    func timedOut() async {
        // macOS 위치 서비스가 앱 등록을 끝내지 않으면 위치 요청이 끝나지도 않는다.
        let result = await resolver.resolve(fallback: busan) {
            try? await Task.sleep(for: .seconds(3600))
            return .location(cityHall)
        }
        #expect(result == AutoRegion(region: busan, source: .unavailable, weather: .unavailable(busan)))
    }

    @Test("위치 서비스가 오류를 내면 마지막에 고른 지역을 쓰고, 받지 못했다고 남긴다")
    func unavailable() async {
        let result = await resolver.resolve(fallback: seoul) { .unavailable }
        #expect(result == AutoRegion(region: seoul, source: .unavailable, weather: .unavailable(seoul)))
    }

    @Test("위젯이 '자동'이고 앱에서 지역을 저장했으면, 위치와 상관없이 그 지역을 쓴다")
    func appRegion() async {
        let result = await resolver.resolve(app: busan, fallback: seoul) { .location(cityHall) }
        #expect(result == AutoRegion(region: busan, source: .app, weather: here))
    }

    @Test("위젯 편집에서 지역을 골랐으면 앱에서 저장한 지역보다 먼저다")
    func widgetRegion() async {
        let result = await resolver.resolve(widget: seoul, app: busan, fallback: busan) { .unavailable }
        #expect(result == AutoRegion(region: seoul, source: .widget, weather: .unavailable(busan)))
    }
}

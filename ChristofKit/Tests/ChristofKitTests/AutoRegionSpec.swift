import CoreLocation
import Testing
@testable import ChristofKit

private let registry = CountryRegistry.standard
private let seoul = registry.region(id: "KR.seoul")!
private let busan = registry.region(id: "KR.busan")!
private let cityHall = CLLocation(latitude: 37.5665, longitude: 126.9780)
// 역지오코딩은 네트워크를 타서, 같은 판정을 하는 반지름 원으로 바꿔 끼운다.
private let resolver = AutoRegionResolver(timeout: .milliseconds(50)) { registry.region(at: $0) }

@Suite("자동 지역")
struct AutoRegionSpec {
    @Test("위치가 서울 안이면 서울이고, 위치로 골랐다고 남긴다")
    func located() async {
        let result = await resolver.resolve(fallback: busan) { .location(cityHall) }
        #expect(result == AutoRegion(region: seoul, source: .location))
    }

    @Test("위치 권한이 없으면 마지막에 고른 지역을 쓰고, 권한이 없다고 남긴다")
    func denied() async {
        let result = await resolver.resolve(fallback: seoul) { .denied }
        #expect(result == AutoRegion(region: seoul, source: .denied))
    }

    @Test("위치가 시한 안에 오지 않으면 마지막에 고른 지역을 쓰고, 받지 못했다고 남긴다")
    func timedOut() async {
        // macOS 위치 서비스가 앱 등록을 끝내지 않으면 위치 요청이 끝나지도 않는다.
        let result = await resolver.resolve(fallback: busan) {
            try? await Task.sleep(for: .seconds(3600))
            return .location(cityHall)
        }
        #expect(result == AutoRegion(region: busan, source: .unavailable))
    }

    @Test("위치 서비스가 오류를 내면 마지막에 고른 지역을 쓰고, 받지 못했다고 남긴다")
    func unavailable() async {
        let result = await resolver.resolve(fallback: seoul) { .unavailable }
        #expect(result == AutoRegion(region: seoul, source: .unavailable))
    }
}

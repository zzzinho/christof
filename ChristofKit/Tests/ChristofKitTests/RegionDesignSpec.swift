import CoreLocation
import Foundation
import Testing
@testable import ChristofKit

private let registry = CountryRegistry.standard
private let seoul = registry.region(id: "KR.seoul")!
private let busan = registry.region(id: "KR.busan")!
private let henesys = registry.region(id: "KR.henesys")!
private let christmas = Date(timeIntervalSince1970: 1_798_160_400) // 2026-12-25 10:00 KST

@Suite("지역이 그림까지 정한다")
struct RegionDesignSpec {
    @Test("서울·부산은 기본 그림으로 그린다")
    func realCities() {
        #expect(SceneContextFactory().context(at: christmas, region: seoul, forecast: nil).theme == .lofi)
        #expect(SceneContextFactory().context(at: christmas, region: busan, forecast: nil).theme == .lofi)
    }

    @Test("헤네시스를 고르면 헤네시스 그림으로 그린다")
    func henesysDesign() {
        #expect(SceneContextFactory().context(at: christmas, region: henesys, forecast: nil).theme == .henesys)
    }

    @Test("헤네시스에도 한국 명절·기념일이 온다")
    func henesysOccasions() {
        let context = SceneContextFactory().context(at: christmas, region: henesys, forecast: nil)
        #expect(context.occasions.map(\.id).contains("KR.christmas"))
    }

    @Test("'자동'은 위치로 헤네시스를 고르지 않는다")
    func autoNeverPicksHenesys() {
        let there = CLLocation(latitude: henesys.latitude, longitude: henesys.longitude)
        #expect(RegionGeocoder.region(at: there, address: nil, registry: registry) != henesys)
        #expect(RegionGeocoder.region(at: there, address: .init(cities: ["Henesys"], city: "Henesys", countryCode: "KR"), registry: registry) != henesys)
    }

    @Test("디자인을 따로 고르던 버전이 저장한 설정도 읽는다")
    func settingsWithDesign() throws {
        let old = try JSONDecoder().decode(SceneSettings.self, from: Data(#"{"occasion":{"automatic":{}},"language":"ko","themeID":"henesys"}"#.utf8))
        #expect(old.region == nil)
        #expect(old.language == .korean)
    }
}

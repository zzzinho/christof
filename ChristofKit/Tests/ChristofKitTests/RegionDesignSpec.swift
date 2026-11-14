import CoreLocation
import Foundation
import Testing
@testable import ChristofKit

private let registry = CountryRegistry.standard
private let seoul = registry.region(id: "KR.seoul")!
private let busan = registry.region(id: "KR.busan")!
private let christmas = Date(timeIntervalSince1970: 1_798_160_400) // 2026-12-25 10:00 KST

// 실제 자리가 없는 지역(게임 마을 같은 디자인). 반지름 0 이고 부산 중심에 둔다.
private struct VirtualTowns: CountryProfile {
    let countryCode = "KR"
    let regions = [Region(id: "test.town", name: LocalizedName(en: "Town", ko: "마을"), countryCode: "KR", latitude: busan.latitude, longitude: busan.longitude, timeZone: busan.timeZone)]
    var occasions: [Occasion] { [] }
    func season(at date: Date, in region: Region) -> Season { .meteorological(at: date, in: region) }
}

@Suite("지역이 그림까지 정한다")
struct RegionDesignSpec {
    @Test("서울·부산은 기본 그림으로 그린다")
    func realCities() {
        #expect(SceneContextFactory().context(at: christmas, region: seoul, forecast: nil).theme == .lofi)
        #expect(SceneContextFactory().context(at: christmas, region: busan, forecast: nil).theme == .lofi)
    }

    @Test("실제 자리가 없는 지역은 '자동'이 위치로 고르지 않는다")
    func autoNeverPicksVirtualTown() {
        let towns = CountryRegistry(profiles: [VirtualTowns()])
        let there = CLLocation(latitude: busan.latitude, longitude: busan.longitude)
        #expect(RegionGeocoder.region(at: there, address: nil, registry: towns).id == Region.hereID)
        #expect(RegionGeocoder.region(at: there, address: .init(cities: ["Town"], city: "Town", countryCode: "KR"), registry: towns).id == Region.hereID)
    }

    @Test("디자인을 따로 고르던 버전이 저장한 설정도 읽는다")
    func settingsWithDesign() throws {
        let old = try JSONDecoder().decode(SceneSettings.self, from: Data(#"{"occasion":{"automatic":{}},"language":"ko","themeID":"henesys"}"#.utf8))
        #expect(old.region == nil)
        #expect(old.language == .korean)
    }

    @Test("목록에서 빠진 헤네시스를 골랐던 설정은 '자동'이 된다")
    func removedHenesys() throws {
        let old = try JSONDecoder().decode(SceneSettings.self, from: Data(#"{"occasion":{"automatic":{}},"regionID":"KR.henesys"}"#.utf8))
        #expect(old.region == nil)
    }
}

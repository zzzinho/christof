import CoreLocation
import Foundation
import Testing
@testable import ChristofKit

private let seoulTimeZone = TimeZone(identifier: "Asia/Seoul")!

private func kst(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12, _ minute: Int = 0) -> Date {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = seoulTimeZone
    return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
}

private func occasion(_ id: String) throws -> Occasion {
    try #require(KoreaProfile().occasions.first { $0.id == id })
}

private let seoul = KoreaRegions.all[0]

// 날짜는 Calendar(identifier: .dangi) 로 다시 계산해 확인했다.
@Test("명절은 그날 2주 전부터 연휴 마지막 날까지 진행 중", arguments: [
    ("KR.seollal", kst(2025, 1, 29), kst(2025, 1, 30)),
    ("KR.seollal", kst(2026, 2, 17), kst(2026, 2, 18)),
    ("KR.seollal", kst(2027, 2, 7), kst(2027, 2, 8)),
    ("KR.chuseok", kst(2025, 10, 6), kst(2025, 10, 7)), // 윤6월이 있는 해
    ("KR.chuseok", kst(2026, 9, 25), kst(2026, 9, 26)),
    ("KR.chuseok", kst(2027, 9, 15), kst(2027, 9, 16)),
    ("KR.buddhasBirthday", kst(2025, 5, 5), kst(2025, 5, 5)),
    ("KR.buddhasBirthday", kst(2026, 5, 24), kst(2026, 5, 24)),
    ("KR.jeongwolDaeboreum", kst(2026, 3, 3), kst(2026, 3, 3)),
    ("KR.christmas", kst(2026, 12, 25), kst(2026, 12, 25)),
])
func holidaySpan(_ id: String, _ day: Date, _ last: Date) throws {
    let holiday = try occasion(id)
    let oneDay: TimeInterval = 24 * 3600
    let first = day - 14 * oneDay
    #expect(!holiday.isActive(at: first - oneDay, in: seoul), "기간 전날")
    for date in stride(from: first, through: last, by: oneDay) {
        #expect(holiday.isActive(at: date, in: seoul), "\(date)")
    }
    #expect(!holiday.isActive(at: last + oneDay, in: seoul), "연휴 다음 날")
}

@Test("추석 연휴는 마지막 날 23:59 KST 까지", arguments: [
    (kst(2026, 9, 26, 23, 59), true),
    (kst(2026, 9, 27, 0, 0), false),
])
func chuseokEndsAtMidnight(_ date: Date, _ expected: Bool) throws {
    #expect(try occasion("KR.chuseok").isActive(at: date, in: seoul) == expected)
}

@Test("같은 순간이라도 지역 시간대의 날짜로 판정한다", arguments: [
    (kst(2026, 9, 27, 0, 30), false, true), // UTC 로는 9/26 15:30, 아직 연휴
    (kst(2026, 9, 11, 0, 30), true, false), // UTC 로는 9/10 15:30, 아직 기간 전
])
func judgesInRegionTimeZone(_ date: Date, _ inSeoul: Bool, _ inUTC: Bool) throws {
    let utcRegion = Region(id: "test.utc", name: LocalizedName(en: "UTC", ko: "UTC"), countryCode: "KR", latitude: seoul.latitude, longitude: seoul.longitude, timeZone: TimeZone(identifier: "UTC")!)
    let chuseok = try occasion("KR.chuseok")
    #expect(chuseok.isActive(at: date, in: seoul) == inSeoul)
    #expect(chuseok.isActive(at: date, in: utcRegion) == inUTC)
}

@Test("한국 지역은 id 가 고유하고 한국 안에 있으며 부산이 기본 지역이다")
func koreaRegions() {
    let regions = KoreaProfile().regions
    #expect(Set(regions.map(\.id)).count == regions.count)
    for region in regions {
        #expect(region.id.hasPrefix("KR.") && region.countryCode == "KR", "\(region.id)")
        #expect(region.timeZone.identifier == "Asia/Seoul", "\(region.id)")
        // 남한 범위: 마라도 33.1°N ~ 강원 북단 38.6°N, 서해 124.6°E ~ 독도 131.9°E
        #expect((33.0...38.7).contains(region.latitude) && (124.5...132.0).contains(region.longitude), "\(region.id)")
    }
    #expect(CountryRegistry.standard.defaultRegion.id == "KR.busan")
}

@Test("한국 이벤트 id 는 고유하다")
func koreaOccasionIDs() {
    let ids = KoreaProfile().occasions.map(\.id)
    #expect(Set(ids).count == ids.count)
    #expect(ids.allSatisfy { $0.hasPrefix("KR.") })
}

@Test("서울 안이면 서울, 그 밖이나 위치를 모르면 부산이다", arguments: [
    (37.566, 126.978, "KR.seoul"),   // 서울시청
    (37.498, 127.028, "KR.seoul"),   // 강남역
    (37.654, 127.056, "KR.seoul"),   // 노원
    (35.163, 129.164, "KR.busan"),   // 해운대
    (36.351, 127.385, "KR.busan"),   // 대전
    (37.263, 127.029, "KR.busan"),   // 수원
    (40.713, -74.006, "KR.busan"),   // 뉴욕
])
func regionAtLocation(_ latitude: Double, _ longitude: Double, _ expected: String) {
    #expect(CountryRegistry.standard.region(at: CLLocation(latitude: latitude, longitude: longitude)).id == expected)
    #expect(CountryRegistry.standard.region(at: nil).id == "KR.busan")
}

@Test("역지오코딩한 도시가 서울이면 서울, 부산(구·군 포함)이면 부산, 그 밖은 기본 지역이다", arguments: [
    (["Seoul"], "KR.seoul"),
    (["Gijang-gun", "Busan"], "KR.busan"),
    (["Seongnam-si", "Gyeonggi-do"], "KR.busan"),
    (["Daejeon"], "KR.busan"),
])
func regionInGeocodedCities(_ cities: [String], _ expected: String) {
    #expect(CountryRegistry.standard.region(inCities: cities).id == expected)
}

import Foundation

public struct Region: Hashable, Sendable, Identifiable {
    /// 위젯 설정에 저장되는 키라 바꾸지 않는다.
    public let id: String
    public let name: LocalizedName
    public let countryCode: String
    public let latitude: Double
    public let longitude: Double
    public let timeZone: TimeZone
    /// 위치로 지역을 고를 때 중심에서 이 거리(미터) 안이면 이 지역이다. 0 이면 위치로 고르지 않는다.
    public let radius: Double
    public let looks: RegionLooks

    public init(id: String, name: LocalizedName, countryCode: String, latitude: Double, longitude: Double, timeZone: TimeZone, radius: Double = 0, looks: RegionLooks = .none) {
        self.id = id
        self.name = name
        self.countryCode = countryCode
        self.latitude = latitude
        self.longitude = longitude
        self.timeZone = timeZone
        self.radius = radius
        self.looks = looks
    }

    // 지역은 id 로 구분한다. 모양은 비교하지 않는다.
    public static func == (a: Region, b: Region) -> Bool { a.id == b.id }
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

/// 지역마다 다른 그림. 테마가 창밖 마을·창틀·동물·평소 옷을 정하고, 기본 테마 마을의 먼 풍경은 지역마다 다르다.
/// 새 디자인은 테마를 만들어 지역 목록에 그 테마를 단 지역 하나로 더한다.
public struct RegionLooks: Sendable {
    var far: any FarView = ApartmentView()
    var theme: Theme = .lofi

    public static let none = RegionLooks()
}

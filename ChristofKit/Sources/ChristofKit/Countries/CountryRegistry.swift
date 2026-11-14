import CoreLocation

public struct CountryRegistry: Sendable {
    public let profiles: [any CountryProfile]

    public init(profiles: [any CountryProfile]) {
        self.profiles = profiles
    }

    public static let standard = CountryRegistry(profiles: [KoreaProfile()])

    public func profile(for countryCode: String) -> (any CountryProfile)? {
        profiles.first { $0.countryCode == countryCode }
    }

    public var regions: [Region] {
        profiles.flatMap(\.regions)
    }

    public func region(id: String) -> Region? {
        regions.first { $0.id == id }
    }

    public var defaultRegion: Region {
        regions[0]
    }

    // 반지름이 0 인 지역(헤네시스처럼 실제 자리가 없는 곳)은 위치로 고르지 않는다.
    private var locatable: [Region] {
        regions.filter { $0.radius > 0 }
    }

    /// 역지오코딩한 도시 이름(영어)에 든 지역.
    public func region(inCities cities: [String]) -> Region? {
        locatable.first { cities.contains($0.name.en) }
    }

    /// 반지름 원으로 어림한 지역.
    public func region(at location: CLLocation) -> Region? {
        locatable.first { location.distance(from: CLLocation(latitude: $0.latitude, longitude: $0.longitude)) <= $0.radius }
    }
}

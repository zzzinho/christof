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

    /// 역지오코딩한 도시 이름(영어)에 든 지역. 없으면 기본 지역이다.
    public func region(inCities cities: [String]) -> Region {
        regions.first { cities.contains($0.name.en) } ?? defaultRegion
    }

    /// 반지름 원으로 어림한 지역. 위치를 모르거나 어느 원에도 들지 않으면 기본 지역이다.
    public func region(at location: CLLocation?) -> Region {
        guard let location else { return defaultRegion }
        return regions.first { location.distance(from: CLLocation(latitude: $0.latitude, longitude: $0.longitude)) <= $0.radius } ?? defaultRegion
    }
}

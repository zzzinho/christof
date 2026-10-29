import MapKit

/// 위치가 어느 지역인지 역지오코딩한 도시 이름으로 고른다. 역지오코딩이 실패하면(오프라인 등) 반지름 원으로 어림한다.
public struct RegionGeocoder: Sendable {
    private let registry: CountryRegistry

    public init(registry: CountryRegistry = .standard) {
        self.registry = registry
    }

    public func region(at location: CLLocation?) async -> Region {
        guard let location else { return registry.defaultRegion }
        guard let cities = await Self.cities(at: location) else { return registry.region(at: location) }
        return registry.region(inCities: cities)
    }

    // 지역의 영어 이름과 견주려고 영어로 받는다. 구·군이 도시 앞에 붙어 오기도 한다("Gijang-gun, Busan").
    @MainActor
    private static func cities(at location: CLLocation) async -> [String]? {
        guard let request = MKReverseGeocodingRequest(location: location) else { return nil }
        request.preferredLocale = Locale(identifier: "en_US")
        guard let city = try? await request.mapItems.first?.addressRepresentations?.cityWithContext else { return nil }
        return city.components(separatedBy: ", ")
    }
}

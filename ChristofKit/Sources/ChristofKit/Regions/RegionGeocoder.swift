import MapKit

/// 위치가 어느 지역인지 역지오코딩한 도시 이름으로 고른다. 역지오코딩이 실패하면(오프라인 등) 반지름 원으로 어림한다.
public struct RegionGeocoder: Sendable {
    struct Address {
        /// 구·군이 도시 앞에 붙어 오기도 한다("Gijang-gun, Busan").
        let cities: [String]
        let city: String?
        let countryCode: String?
    }

    private let registry: CountryRegistry

    public init(registry: CountryRegistry = .standard) {
        self.registry = registry
    }

    public func region(at location: CLLocation) async -> Region {
        Self.region(at: location, address: await Self.address(at: location), registry: registry)
    }

    /// 목록의 도시 안이면 그 도시, 밖이면 그 자리(내 위치)다.
    static func region(at location: CLLocation, address: Address?, registry: CountryRegistry) -> Region {
        let listed = if let address { registry.region(inCities: address.cities) } else { registry.region(at: location) }
        // ponytail: 역지오코딩이 안 되면 나라를 기기 지역 설정으로 어림한다. 해외에서 오프라인이면 틀릴 수 있다.
        return listed ?? .here(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, city: address?.city,
                               countryCode: address?.countryCode ?? Locale.current.region?.identifier ?? "KR")
    }

    // 지역의 영어 이름과 견주려고 영어로 받는다.
    @MainActor
    private static func address(at location: CLLocation) async -> Address? {
        guard let request = MKReverseGeocodingRequest(location: location) else { return nil }
        request.preferredLocale = Locale(identifier: "en_US")
        guard let address = try? await request.mapItems.first?.addressRepresentations, let city = address.cityWithContext else { return nil }
        return Address(cities: city.components(separatedBy: ", "), city: address.cityName, countryCode: address.region?.identifier)
    }
}

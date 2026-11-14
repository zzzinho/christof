import CoreLocation
import Synchronization

public enum LocationReading: Sendable {
    case location(CLLocation)
    case denied
    case unavailable
}

/// 날씨를 받는 자리. 그리는 지역과 상관없이 내 위치다(헤네시스처럼 실제 자리가 없는 지역도 있다).
/// 위치를 못 받으면 위치로 마지막에 고른 지역에서 받는다.
public enum WeatherPlace: Equatable, Sendable {
    case location(latitude: Double, longitude: Double)
    case denied(Region)
    case unavailable(Region)

    /// 위치 대신 쓴 지역.
    public var fallback: Region? {
        switch self {
        case .location: nil
        case .denied(let region), .unavailable(let region): region
        }
    }

    public var latitude: Double {
        switch self {
        case .location(let latitude, _): latitude
        case .denied(let region), .unavailable(let region): region.latitude
        }
    }

    public var longitude: Double {
        switch self {
        case .location(_, let longitude): longitude
        case .denied(let region), .unavailable(let region): region.longitude
        }
    }
}

/// 위젯이 그릴 지역과 그 출처, 날씨를 받을 자리. 위치를 못 받았으면(`denied`, `unavailable`) 마지막에 고른 지역을 그대로 쓴다.
public struct AutoRegion: Equatable, Sendable {
    public enum Source: Equatable, Sendable {
        case widget, app, location, denied, unavailable
    }

    public let region: Region
    public let source: Source
    public let weather: WeatherPlace

    public init(region: Region, source: Source, weather: WeatherPlace) {
        self.region = region
        self.source = source
        self.weather = weather
    }
}

public struct AutoRegionResolver: Sendable {
    private let timeout: Duration
    private let regionAt: @Sendable (CLLocation) async -> Region

    public init(timeout: Duration = .seconds(10), regionAt: @escaping @Sendable (CLLocation) async -> Region = { await RegionGeocoder().region(at: $0) }) {
        self.timeout = timeout
        self.regionAt = regionAt
    }

    /// 지역은 위젯 편집에서 고른 지역, 앱에서 저장한 지역, 위치 순으로 고른다. 날씨 자리 때문에 위치는 늘 본다.
    public func resolve(widget: Region? = nil, app: Region? = nil, fallback: Region, locate: @escaping @Sendable () async -> LocationReading) async -> AutoRegion {
        let reading = await Self.first(within: timeout, locate) ?? .unavailable
        let weather: WeatherPlace = switch reading {
        case .location(let location): .location(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        case .denied: .denied(fallback)
        case .unavailable: .unavailable(fallback)
        }
        if let widget { return AutoRegion(region: widget, source: .widget, weather: weather) }
        if let app { return AutoRegion(region: app, source: .app, weather: weather) }
        return switch reading {
        case .location(let location): AutoRegion(region: await regionAt(location), source: .location, weather: weather)
        case .denied: AutoRegion(region: fallback, source: .denied, weather: weather)
        case .unavailable: AutoRegion(region: fallback, source: .unavailable, weather: weather)
        }
    }

    // macOS 위치 서비스가 앱 등록을 끝내지 않으면(서명 신원이 바뀐 빌드 등) 위치 요청이 끝나지도, 취소에 응하지도 않는다.
    // 그래서 작업이 끝나기를 기다리지 않고 시한에 먼저 돌아온다.
    private static func first<T: Sendable>(within timeout: Duration, _ operation: @escaping @Sendable () async -> T) async -> T? {
        await withCheckedContinuation { continuation in
            let pending = Mutex<CheckedContinuation<T?, Never>?>(continuation)
            let resume: @Sendable (T?) -> Void = { value in
                pending.withLock { $0.take() }?.resume(returning: value)
            }
            let work = Task { resume(await operation()) }
            Task {
                try? await Task.sleep(for: timeout)
                work.cancel()
                resume(nil)
            }
        }
    }
}

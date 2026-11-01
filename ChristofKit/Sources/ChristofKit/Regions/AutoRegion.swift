import CoreLocation
import Synchronization

public enum LocationReading: Sendable {
    case location(CLLocation)
    case denied
    case unavailable
}

/// 위젯이 그릴 지역과 그 출처. 위치를 못 받았으면(`denied`, `unavailable`) 마지막에 고른 지역을 그대로 쓴다.
public struct AutoRegion: Equatable, Sendable {
    public enum Source: Equatable, Sendable {
        case widget, app, location, denied, unavailable
    }

    public let region: Region
    public let source: Source

    public init(region: Region, source: Source) {
        self.region = region
        self.source = source
    }
}

public struct AutoRegionResolver: Sendable {
    private let timeout: Duration
    private let regionAt: @Sendable (CLLocation) async -> Region

    public init(timeout: Duration = .seconds(10), regionAt: @escaping @Sendable (CLLocation) async -> Region = { await RegionGeocoder().region(at: $0) }) {
        self.timeout = timeout
        self.regionAt = regionAt
    }

    /// 위젯 편집에서 고른 지역, 앱에서 저장한 지역, 위치 순으로 고른다.
    public func resolve(widget: Region? = nil, app: Region? = nil, fallback: Region, locate: @escaping @Sendable () async -> LocationReading) async -> AutoRegion {
        if let widget { return AutoRegion(region: widget, source: .widget) }
        if let app { return AutoRegion(region: app, source: .app) }
        return switch await Self.first(within: timeout, locate) {
        case .location(let location)?: AutoRegion(region: await regionAt(location), source: .location)
        case .denied?: AutoRegion(region: fallback, source: .denied)
        case .unavailable?, nil: AutoRegion(region: fallback, source: .unavailable)
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

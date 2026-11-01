import CoreLocation
import Synchronization

public enum LocationReading: Sendable {
    case location(CLLocation)
    case denied
    case unavailable
}

/// "자동" 지역과, 그 지역을 위치로 골랐는지 아니면 못 골라 마지막 지역을 그대로 쓰는지.
public struct AutoRegion: Equatable, Sendable {
    public enum Source: Equatable, Sendable {
        case location, denied, unavailable
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

    public func resolve(fallback: Region, locate: @escaping @Sendable () async -> LocationReading) async -> AutoRegion {
        switch await Self.first(within: timeout, locate) {
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

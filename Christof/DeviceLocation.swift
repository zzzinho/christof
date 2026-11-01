import ChristofKit
import CoreLocation

@MainActor
enum DeviceLocation {
    // CLServiceSession 은 macOS 에 없어 두 플랫폼 모두 CLLocationManager 로 권한을 묻는다. 물음이 떠 있는 동안 살아 있어야 해서 붙잡아 둔다.
    private static let manager = CLLocationManager()

    /// 위치 한 번. 끝나지 않을 수 있어 `AutoRegionResolver` 의 시한 안에서 부른다.
    static func current() async -> LocationReading {
        manager.requestWhenInUseAuthorization()
        do {
            for try await update in CLLocationUpdate.liveUpdates() {
                if let location = update.location { return .location(location) }
                if update.authorizationDenied || update.authorizationDeniedGlobally || update.authorizationRestricted { return .denied }
            }
        } catch {}
        return .unavailable
    }
}

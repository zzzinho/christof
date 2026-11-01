import CoreLocation

/// 위젯은 앱이 받은 위치 권한으로 위치를 본다(Info.plist 의 NSWidgetWantsLocation).
/// 위젯은 화면에 "사용 중"인 앱이 아니라 CLLocationUpdate.liveUpdates 가 위치를 주지 않을 수 있어, 한 번 묻는 requestLocation 을 쓴다.
/// 권한이 넘어오지 않으면 isAuthorizedForWidgetUpdates 가 false 라 앱이 고른 지역으로 돌아간다(macOS 위젯에서 넘어오는 것은 0.7.1 에서 확인했다).
@MainActor
final class WidgetLocation: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocation?, Never>?

    static func current() async -> CLLocation? {
        await WidgetLocation().locate()
    }

    private func locate() async -> CLLocation? {
        guard manager.isAuthorizedForWidgetUpdates else { return nil }
        // 도시만 가리면 된다. 타임라인을 오래 붙잡지 않도록 10초 안에 오지 않으면 포기한다.
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        manager.delegate = self
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            manager.requestLocation()
            Task {
                try? await Task.sleep(for: .seconds(10))
                self.finish(nil)
            }
        }
    }

    private func finish(_ location: CLLocation?) {
        continuation?.resume(returning: location)
        continuation = nil
    }

    // 델리게이트는 매니저를 만든 메인 스레드에서 불린다.
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last
        MainActor.assumeIsolated { finish(location) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        MainActor.assumeIsolated { finish(nil) }
    }
}

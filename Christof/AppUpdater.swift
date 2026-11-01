#if os(macOS)
import ChristofKit
import Sparkle
import SwiftUI

/// 새 버전 확인은 늘 자동이다. "자동 설치"가 꺼져 있으면(기본) 설정 화면의 버튼으로만 설치한다.
@MainActor @Observable
final class AppUpdater: NSObject, SPUUpdaterDelegate, SPUStandardUserDriverDelegate {
    private(set) var availableVersion: String?
    private(set) var checked = false
    var installsAutomatically = false {
        didSet { controller.updater.automaticallyDownloadsUpdates = installsAutomatically }
    }
    @ObservationIgnored private var installNow: (() -> Void)?
    @ObservationIgnored private var controller: SPUStandardUpdaterController!

    override init() {
        super.init()
        controller = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: self, userDriverDelegate: self)
        installsAutomatically = controller.updater.automaticallyDownloadsUpdates
        // 앱은 위젯을 눌러 열 때만 떠 있어, 하루 주기 검사를 기다리지 않고 열 때마다 확인한다.
        controller.updater.checkForUpdatesInBackground()
    }

    var notice: UpdateNotice {
        UpdateNotice(checked: checked, newVersion: availableVersion, installsAutomatically: installsAutomatically)
    }

    /// 자동 설치로 이미 받아 두었으면 바로 설치하고, 아니면 Sparkle 의 설치 창을 띄운다.
    func update() {
        if let installNow { installNow() } else { controller.updater.checkForUpdates() }
    }

    nonisolated func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        let version = item.displayVersionString
        MainActor.assumeIsolated {
            availableVersion = version
            checked = true
        }
    }

    nonisolated func updaterDidNotFindUpdate(_ updater: SPUUpdater) {
        MainActor.assumeIsolated {
            availableVersion = nil
            checked = true
        }
    }

    // 자동 설치는 받아 둔 업데이트를 앱이 끝날 때(창을 닫을 때) 설치한다. 그 전에 버튼으로 바로 설치할 수 있게 남겨 둔다.
    nonisolated func updater(_ updater: SPUUpdater, willInstallUpdateOnQuit item: SUAppcastItem, immediateInstallationBlock: @escaping () -> Void) -> Bool {
        nonisolated(unsafe) let install = immediateInstallationBlock
        MainActor.assumeIsolated { installNow = install }
        return true
    }

    // 확인으로 찾은 새 버전은 Sparkle 알림 창 대신 설정 화면에 띄운다. 버튼을 누르면 checkForUpdates 가 설치 창을 연다.
    nonisolated var supportsGentleScheduledUpdateReminders: Bool { true }

    nonisolated func standardUserDriverShouldHandleShowingScheduledUpdate(_ update: SUAppcastItem, andInImmediateFocus immediateFocus: Bool) -> Bool {
        false
    }
}
#endif

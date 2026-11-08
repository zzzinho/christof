import Testing
@testable import ChristofKit

@Suite("설정 화면의 업데이트 알림")
struct UpdateNoticeSpec {
    @Test("확인을 마치기 전에는 아무것도 알리지 않는다")
    func notChecked() {
        #expect(UpdateNotice(checked: false, newVersion: nil, downloaded: false) == .none)
    }

    @Test("새 버전이 없으면 최신 버전이라고 알린다")
    func upToDate() {
        #expect(UpdateNotice(checked: true, newVersion: nil, downloaded: false) == .upToDate)
    }

    @Test("새 버전을 받기 전이면 자동 설치를 켜 두었어도 새 버전이 있다고 알리고, 사용자가 업데이트를 누를 수 있다")
    func available() {
        #expect(UpdateNotice(checked: true, newVersion: "0.7.1", downloaded: false) == .available("0.7.1"))
    }

    @Test("새 버전을 받아 두었으면 앱을 닫을 때 설치된다고 알린다")
    func installsOnQuit() {
        #expect(UpdateNotice(checked: true, newVersion: "0.7.1", downloaded: true) == .installsOnQuit("0.7.1"))
    }

    @Test("새 버전이 있다고 알리는 중에 자동 설치를 켜면 바로 받는다", arguments: [
        (UpdateNotice.available("0.7.1"), true),
        (.installsOnQuit("0.7.1"), false),
        (.upToDate, false),
        (.none, false),
    ])
    func downloadsWhenAutomaticInstallTurnsOn(notice: UpdateNotice, downloads: Bool) {
        #expect(notice.downloadsWhenAutomaticInstallTurnsOn == downloads)
    }
}

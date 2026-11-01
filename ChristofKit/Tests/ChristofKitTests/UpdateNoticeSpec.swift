import Testing
@testable import ChristofKit

@Suite("설정 화면의 업데이트 알림")
struct UpdateNoticeSpec {
    @Test("확인을 마치기 전에는 아무것도 알리지 않는다")
    func notChecked() {
        #expect(UpdateNotice(checked: false, newVersion: nil, installsAutomatically: false) == .none)
    }

    @Test("새 버전이 없으면 최신 버전이라고 알린다")
    func upToDate() {
        #expect(UpdateNotice(checked: true, newVersion: nil, installsAutomatically: false) == .upToDate)
    }

    @Test("수동 설치면 새 버전이 있다고 알리고, 사용자가 업데이트를 누른다")
    func manual() {
        #expect(UpdateNotice(checked: true, newVersion: "0.7.1", installsAutomatically: false) == .available("0.7.1"))
    }

    @Test("자동 설치면 앱을 닫을 때 새 버전이 설치된다고 알린다")
    func automatic() {
        #expect(UpdateNotice(checked: true, newVersion: "0.7.1", installsAutomatically: true) == .installsOnQuit("0.7.1"))
    }
}

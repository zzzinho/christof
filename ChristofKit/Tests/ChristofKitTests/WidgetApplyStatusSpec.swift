import Foundation
import Testing
@testable import ChristofKit

private let savedAt = Date(timeIntervalSinceReferenceDate: 1_000)

@Suite("저장한 설정의 위젯 적용 상태")
struct WidgetApplyStatusSpec {
    @Test("저장한 뒤 위젯이 아직 설정을 읽지 않았으면 적용 중이다")
    func applying() {
        #expect(WidgetApplyStatus(savedAt: savedAt, appliedAt: nil, placedWidgets: 1) == .applying)
    }

    @Test("위젯이 저장한 뒤에 설정을 읽었으면 적용 완료다")
    func applied() {
        #expect(WidgetApplyStatus(savedAt: savedAt, appliedAt: savedAt.addingTimeInterval(2), placedWidgets: 1) == .applied)
    }

    @Test("저장하기 전에 옛 설정을 읽은 리로드는 적용 완료로 치지 않는다")
    func staleReload() {
        #expect(WidgetApplyStatus(savedAt: savedAt, appliedAt: savedAt.addingTimeInterval(-1), placedWidgets: 1) == .applying)
    }

    @Test("놓인 위젯이 없으면 그렇다고 알린다")
    func noWidget() {
        #expect(WidgetApplyStatus(savedAt: savedAt, appliedAt: nil, placedWidgets: 0) == .noWidget)
    }

    @Test("놓인 위젯 수를 알 수 없으면 적용을 기다린다")
    func unknownWidgets() {
        #expect(WidgetApplyStatus(savedAt: savedAt, appliedAt: nil, placedWidgets: nil) == .applying)
    }
}

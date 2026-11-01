import Foundation

/// WidgetKit 은 리로드가 끝났다고 알려 주지 않아, 위젯이 설정을 읽은 시각(`SceneSettingsStore.loadAppliedAt`)을 저장 시각과 견준다.
public enum WidgetApplyStatus: Equatable, Sendable {
    case applying, applied, noWidget

    /// `placedWidgets` 가 nil 이면 놓인 위젯 수를 알 수 없다(조회 실패).
    public init(savedAt: Date, appliedAt: Date?, placedWidgets: Int?) {
        if placedWidgets == 0 {
            self = .noWidget
        } else if let appliedAt, appliedAt >= savedAt {
            self = .applied
        } else {
            self = .applying
        }
    }
}

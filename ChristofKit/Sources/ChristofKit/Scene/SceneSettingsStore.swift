import Foundation

/// 앱에서 저장하고 위젯 익스텐션이 읽으므로 둘이 함께 여는 설정 도메인에 둔다.
public struct SceneSettingsStore: Sendable {
    #if os(macOS)
    // macOS 는 개발 팀 서명 없이 App Group 을 쓸 수 없어, 샌드박스 예외 권한
    // (Config/Christof-macOS.entitlements)으로 여는 공용 설정 도메인을 쓴다. 앱스토어 배포 전에는 App Group 으로 바꾼다.
    public static let sharedSuite = "com.christof.shared"
    #else
    public static let sharedSuite = "group.com.christof.Christof"
    #endif
    private static let key = "sceneSettings"
    private static let locatedRegionKey = "locatedRegionID"
    private static let appliedAtKey = "appliedAt"

    private let suiteName: String

    public init(suiteName: String = SceneSettingsStore.sharedSuite) {
        self.suiteName = suiteName
    }

    // UserDefaults 는 Sendable 이 아니라 이름만 들고 매번 연다.
    private var defaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }

    public func load() -> SceneSettings {
        guard let data = defaults.data(forKey: Self.key),
              let settings = try? JSONDecoder().decode(SceneSettings.self, from: data)
        else { return .live }
        return settings
    }

    public func save(_ settings: SceneSettings) {
        defaults.set(try? JSONEncoder().encode(settings), forKey: Self.key)
    }

    /// 앱이 위치로 마지막에 고른 지역. 고른 적이 없으면 기본 지역이다.
    public func loadLocatedRegion(from registry: CountryRegistry = .standard) -> Region {
        defaults.string(forKey: Self.locatedRegionKey).flatMap(registry.region(id:)) ?? registry.defaultRegion
    }

    public func saveLocatedRegion(_ region: Region) {
        defaults.set(region.id, forKey: Self.locatedRegionKey)
    }

    /// 위젯이 타임라인을 만들며 설정을 읽은 가장 늦은 시각. WidgetKit 은 리로드가 끝났다고 알려 주지 않아, 앱은 이 값이 저장 시각을 넘으면 적용됐다고 본다.
    /// ponytail: 타임라인을 다 만든 때이고 화면에 그려진 때는 아니다. 그리기는 그 뒤 바로 이어진다.
    public func loadAppliedAt() -> Date? {
        defaults.object(forKey: Self.appliedAtKey) as? Date
    }

    // 위젯이 여럿이면 늦게 끝난 옛 리로드가 새 값을 덮지 않게 더 늦은 시각만 남긴다.
    public func markApplied(readAt date: Date) {
        if let applied = loadAppliedAt(), applied >= date { return }
        defaults.set(date, forKey: Self.appliedAtKey)
    }
}

import AppIntents
import ChristofKit
import WidgetKit

struct SelectRegionIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Choose Region"
    static let description = IntentDescription("Choose the region and design to show outside the window.")

    @Parameter(title: "Region")
    var region: RegionEntity?

    @Parameter(title: "Design")
    var theme: ThemeEntity?

    /// 고른 지역. "자동"과 목록에서 빠진 지역(예전 버전의 대구 등)은 nil 이고, 위치로 고른다.
    var chosenRegion: Region? {
        region.flatMap { CountryRegistry.standard.region(id: $0.id) }
    }

    /// 고른 테마. "앱 설정 따르기"와 목록에서 빠진 테마는 nil 이고, 앱 설정을 쓴다.
    var chosenTheme: Theme? {
        theme.flatMap { id in Theme.all.first { $0.id == id.id } }
    }
}

struct ThemeEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Design"
    static let defaultQuery = ThemeQuery()
    static let app = ThemeEntity(id: "app")

    let id: String

    var displayRepresentation: DisplayRepresentation {
        guard let theme = Theme.all.first(where: { $0.id == id }) else { return DisplayRepresentation(title: "Same as App") }
        return DisplayRepresentation(title: "\(theme.name[AppLanguage(.current)])")
    }
}

struct ThemeQuery: EntityQuery {
    private static var all: [ThemeEntity] {
        [.app] + Theme.all.map { ThemeEntity(id: $0.id) }
    }

    func entities(for identifiers: [String]) async throws -> [ThemeEntity] {
        Self.all.filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [ThemeEntity] {
        Self.all
    }

    func defaultResult() async -> ThemeEntity? {
        .app
    }
}

struct RegionEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Region"
    static let defaultQuery = RegionQuery()
    static let automatic = RegionEntity(id: "auto")

    let id: String

    var displayRepresentation: DisplayRepresentation {
        guard let region = CountryRegistry.standard.region(id: id) else { return DisplayRepresentation(title: "Auto") }
        // 위젯 편집은 시스템 화면이라 둘레 문구처럼 시스템 언어를 따른다.
        return DisplayRepresentation(title: "\(region.name[AppLanguage(.current)])")
    }
}

struct RegionQuery: EntityQuery {
    private static var all: [RegionEntity] {
        [.automatic] + CountryRegistry.standard.regions.map { RegionEntity(id: $0.id) }
    }

    func entities(for identifiers: [String]) async throws -> [RegionEntity] {
        Self.all.filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [RegionEntity] {
        Self.all
    }

    func defaultResult() async -> RegionEntity? {
        .automatic
    }
}

import AppIntents
import ChristofKit
import WidgetKit

struct SelectRegionIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Choose Region"
    static let description = IntentDescription("Choose the region to show outside the window.")

    @Parameter(title: "Region")
    var region: RegionEntity?

    /// 고른 지역. "자동"과 목록에서 빠진 지역(예전 버전의 대구 등)은 nil 이고, 위치로 고른다.
    var chosenRegion: Region? {
        region.flatMap { CountryRegistry.standard.region(id: $0.id) }
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

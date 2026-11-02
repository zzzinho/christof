import Foundation

/// 위젯이 마지막으로 장면을 만들 때 받지 못한 것. 위젯 안에는 글자를 두지 않아(design/DESIGN.md) 앱 설정 화면이 보여 준다.
public struct WidgetFailures: Codable, Equatable, Sendable {
    public enum Location: String, Codable, Sendable {
        case denied, unavailable
    }

    public let location: Location?
    public let weather: Bool
    /// 대신 그린 지역.
    public let regionID: String
    public let at: Date

    /// 받지 못한 것이 없으면 nil 이다.
    public init?(region: AutoRegion, weatherFailed: Bool, at: Date) {
        let location: Location? = switch region.source {
        case .denied: .denied
        case .unavailable: .unavailable
        case .widget, .app, .location: nil
        }
        guard location != nil || weatherFailed else { return nil }
        self.location = location
        self.weather = weatherFailed
        self.regionID = region.region.id
        self.at = at
    }

    public var region: Region? {
        CountryRegistry.standard.region(id: regionID)
    }
}

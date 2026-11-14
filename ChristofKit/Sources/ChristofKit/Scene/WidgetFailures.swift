import Foundation

/// 위젯이 마지막으로 장면을 만들 때 받지 못한 것. 위젯 안에는 글자를 두지 않아(design/DESIGN.md) 앱 설정 화면이 보여 준다.
public struct WidgetFailures: Codable, Equatable, Sendable {
    public enum Location: String, Codable, Sendable {
        case denied, unavailable
    }

    /// 날씨는 늘 내 위치에서 받아서, 지역을 골랐어도 위치를 받지 못하면 남긴다.
    public let location: Location?
    public let weather: Bool
    /// 위치 대신 날씨를 받은 지역. 위치를 받았으면 그린 지역이다. 내 위치일 수 있어 이름으로 남긴다.
    public let regionName: LocalizedName
    /// 위젯이 "자동"이라 위치 대신 regionName 지역을 그렸다.
    public let drewFallbackRegion: Bool
    public let at: Date

    /// 받지 못한 것이 없으면 nil 이다.
    public init?(region: AutoRegion, weatherFailed: Bool, at: Date) {
        let location: Location? = switch region.weather {
        case .denied: .denied
        case .unavailable: .unavailable
        case .location: nil
        }
        guard location != nil || weatherFailed else { return nil }
        self.location = location
        self.weather = weatherFailed
        self.regionName = (region.weather.fallback ?? region.region).name
        self.drewFallbackRegion = region.source == .denied || region.source == .unavailable
        self.at = at
    }
}

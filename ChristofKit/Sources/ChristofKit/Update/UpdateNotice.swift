public enum UpdateNotice: Equatable, Sendable {
    case none
    case upToDate
    case available(String)
    case installsOnQuit(String)

    // "닫을 때 설치"는 자동 설치를 켰다는 사실이 아니라 받아 두었다는 사실로 정한다. 켠 것만으로는 닫아도 설치되지 않는다.
    public init(checked: Bool, newVersion: String?, downloaded: Bool) {
        switch (checked, newVersion) {
        case (false, _): self = .none
        case (true, nil): self = .upToDate
        case (true, let version?): self = downloaded ? .installsOnQuit(version) : .available(version)
        }
    }

    public var downloadsWhenAutomaticInstallTurnsOn: Bool {
        if case .available = self { true } else { false }
    }
}

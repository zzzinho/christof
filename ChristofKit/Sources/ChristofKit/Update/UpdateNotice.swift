public enum UpdateNotice: Equatable, Sendable {
    case none
    case upToDate
    case available(String)
    case installsOnQuit(String)

    public init(checked: Bool, newVersion: String?, installsAutomatically: Bool) {
        switch (checked, newVersion) {
        case (false, _): self = .none
        case (true, nil): self = .upToDate
        case (true, let version?): self = installsAutomatically ? .installsOnQuit(version) : .available(version)
        }
    }
}

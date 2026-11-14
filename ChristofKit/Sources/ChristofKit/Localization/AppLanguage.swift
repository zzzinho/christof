import Foundation

public enum AppLanguage: String, CaseIterable, Codable, Sendable {
    case english = "en"
    case korean = "ko"

    public var locale: Locale { Locale(identifier: rawValue) }

    /// 고를 수 없는 언어는 영어로 둔다.
    public init(_ locale: Locale) {
        self = Self.allCases.first { $0.locale.language.languageCode == locale.language.languageCode } ?? .english
    }
}

/// 지역·이벤트·날씨처럼 데이터에 딸린 이름. 앱 화면 문구는 앱의 String Catalog 가 맡지만, 이 이름들은 국가 프로필과 함께 두어
/// 새 국가가 앱 카탈로그를 고치지 않게 한다. 언어를 늘리면 필드를 더해, 번역이 빠진 이름을 컴파일러가 찾게 한다.
public struct LocalizedName: Hashable, Sendable, Codable {
    public let en: String
    public let ko: String

    public init(en: String, ko: String) {
        self.en = en
        self.ko = ko
    }

    public subscript(language: AppLanguage) -> String {
        switch language {
        case .english: en
        case .korean: ko
        }
    }
}

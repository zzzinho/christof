import Foundation

/// 부산이 첫 지역이라 기본 지역이 된다.
public enum KoreaRegions {
    // 좌표는 Open-Meteo 지오코딩(GeoNames) 의 도시 중심점. 반지름은 중심에서 시 경계까지의 대략 거리로,
    // 역지오코딩이 실패할 때(오프라인 등)만 쓴다. 원 어림이라 경계 근처(성남·고양 일부 등)는 틀릴 수 있다.
    public static let all: [Region] = [
        region("busan", LocalizedName(en: "Busan", ko: "부산"), 35.10168, 129.03004, radius: 30_000, RegionLooks(far: BusanView())),
        region("seoul", LocalizedName(en: "Seoul", ko: "서울"), 37.566, 126.9784, radius: 20_000, RegionLooks(far: SeoulView())),
        // 메이플스토리 마을이라 실제 자리가 없어 위치로 고르지 않는다(반지름 0). 이벤트·계절·시간대는 한국, 해·달은 기본 지역(부산) 좌표로 계산한다.
        // 날씨는 어느 지역이든 내 위치에서 받는다(WeatherPlace).
        region("henesys", LocalizedName(en: "Henesys", ko: "헤네시스"), 35.10168, 129.03004, radius: 0, RegionLooks(theme: .henesys)),
    ]

    private static func region(_ key: String, _ name: LocalizedName, _ latitude: Double, _ longitude: Double, radius: Double, _ looks: RegionLooks) -> Region {
        // 고정 식별자라 실패하지 않는다.
        Region(id: "KR.\(key)", name: name, countryCode: "KR", latitude: latitude, longitude: longitude, timeZone: TimeZone(identifier: "Asia/Seoul")!, radius: radius, looks: looks)
    }
}

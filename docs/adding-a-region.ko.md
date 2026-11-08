# 지역 추가하기

[English](adding-a-region.md) | 한국어

지역은 앱에서 더할 수 없습니다. 시안과 코드를 고친 뒤 앱을 직접 빌드합니다. 지금 지역은 서울과 부산 둘입니다.

지역마다 창밖 먼 풍경에 랜드마크가 하나 있습니다. 나머지(방 안, 사람, 고양이, 이벤트)는 모든 지역이 같습니다.

## 1. 먼 풍경 디자인

시안은 [`design/`](../design/) 폴더에 있습니다. 평범한 HTML 이라 그 폴더에서 아무 정적 서버(예: `python3 -m http.server`, [hunsu](https://github.com/zzzinho/hunsu))로 엽니다.

1. `design/00-base.html` 의 `FAR_VIEWS` 에 그리는 함수를 하나 더하고, `REGION_VIEWS` 에 지역의 한국어 이름과 그 함수를 잇습니다. `REGION_VIEWS` 에 없는 지역은 기본 풍경(뒷산과 아파트 단지)으로 그려집니다.
2. `design/01-busan.html` 을 `design/NN-<지역>.html` 로 복사하고 `REGION`(이름과 디자인 의도)만 바꿉니다. 이 페이지는 그리기 코드를 `00-base.html` 에서 받아 오므로, 파일로 열지 말고 서버로 엽니다.
3. `design/DESIGN.md` 의 "지역별 먼 풍경" 표에 한 줄을 더합니다. 어떤 랜드마크를 왜 골랐는지 적습니다. 랜드마크는 지역마다 하나만 그립니다. 위젯이 작아서 둘을 넣으면 둘 다 알아보기 어렵습니다.

## 2. 앱으로 옮기기

`ChristofKit` 의 그리기 코드는 시안의 JavaScript 를 같은 이름·순서로 옮긴 것이라, 같은 칸을 칠합니다.

1. 그리는 함수를 `ChristofKit/Sources/ChristofKit/Rendering/Layers/FarViews.swift` 에 `FarView` 타입 하나로 옮깁니다.
2. `ChristofKit/Sources/ChristofKit/Countries/Korea/KoreaRegions.swift` 의 `KoreaRegions.all` 에 지역을 더합니다.

   ```swift
   region("daegu", LocalizedName(en: "Daegu", ko: "대구"), 35.87028, 128.59111, radius: 15_000, RegionLooks(far: DaeguView())),
   ```

   - id(`KR.daegu`)는 위젯 설정에 저장됩니다. 한 번 릴리스한 뒤에는 바꾸지 않습니다.
   - 한국어 이름은 `REGION_VIEWS` 의 키와 같아야 합니다. 시안 비교가 이 이름으로 먼 풍경을 고릅니다.
   - 좌표는 도시 중심점이고, 날씨를 이 지점으로 받습니다. 지금 지역들은 [Open-Meteo 지오코딩](https://open-meteo.com/en/docs/geocoding-api)의 중심점을 씁니다.
   - 위젯 지역이 "자동"이면 앱과 위젯이 기기 위치의 도시를 Apple 역지오코딩으로 영어로 찾아, 영어 이름이 같은 지역을 고릅니다. 그래서 영어 이름은 Apple 지도가 쓰는 도시 이름과 같아야 합니다. 어느 지역에도 들지 않으면 기본 지역을 씁니다.
   - `radius` 는 중심에서 시 경계까지의 대략 거리(미터)입니다. 오프라인처럼 역지오코딩이 실패할 때만 씁니다.
   - 목록의 첫 지역이 기본 지역입니다.

위젯의 지역 목록과 앱의 지역 선택은 `CountryRegistry` 에서 지역을 읽으므로, 다른 코드는 고치지 않습니다.

## 3. 확인

새 먼 풍경을 시안과 견주려면 `ChristofKit/Sources/ChristofSnapshots/main.swift` 의 `scenarios` 에 새 지역의 장면을 하나 더합니다. 그리고 다음을 실행합니다.

```sh
swift test --package-path ChristofKit
swift run --package-path ChristofKit ChristofSnapshots /tmp/christof-snapshots
node ChristofKit/Scripts/compare-design.mjs /tmp/christof-snapshots design/00-base.html
```

비교 스크립트는 모든 스냅샷을 시안의 JavaScript 로 다시 그려 견줍니다. 팔레트와 모든 격자가 같아야 합니다. 스냅샷 폴더의 PNG 도 열어서 눈으로 확인합니다.

앱은 다음 명령으로 빌드합니다.

```sh
xcodebuild -project Christof.xcodeproj -scheme Christof -destination 'platform=macOS' build
```

## 나라 추가하기

1. `ChristofKit/Sources/ChristofKit/Countries/<나라>/` 폴더를 만들고 `CountryProfile` 을 따르는 타입을 둡니다. 국가 코드, 지역, 명절(`occasions`), 계절을 정합니다.
2. 그 프로필을 `CountryRegistry.standard` 에 등록합니다. 공용 코드는 고치지 않습니다.

명절 하나는 `Occasion` 값 하나입니다. 날짜 규칙(`OccasionRule`)과 장면의 구성 요소별 모양을 함께 정합니다. 예시는 `Countries/Korea/KoreaOccasions.swift` 에 있습니다. 나라마다 그 나라의 풍경과 풍속으로 그려서, 다른 나라로 읽히지 않게 합니다. 규칙은 `design/DESIGN.md` 에 있습니다.

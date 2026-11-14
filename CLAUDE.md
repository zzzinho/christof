# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트

macOS·iOS용 위젯. 위젯은 창문 모양이고, 사용자가 고른 지역의 창밖 풍경에 내 위치의 날씨와 그 지역의 시간·이벤트를 보여준다. 이름은 트루먼 쇼에서 가상 세계를 연출하는 감독 Christof에서 따왔다. 이 창문이 가상의 창문이라는 뜻이다.

- 사용자가 지역을 앱에서 골라 저장하면 위젯에 반영된다. 위젯마다 다르게 하려면 위젯 편집에서 고르고, 그 값이 앱 설정보다 먼저다. 둘 다 "자동"이면 위치로 고른 지역을 쓴다(서울 안이면 서울, 그 밖이거나 위치를 모르면 부산). 앱은 열 때, 위젯은 리로드할 때 위치를 보고, 위젯이 위치를 못 보면 앱이 마지막에 고른 지역을 쓴다. 로그인·계정은 없고, 사용자 로그인이 필요한 기능이나 서비스는 들이지 않는다.
- 디자인(테마): 지역이 하나씩 단 그림 세계(`RegionLooks.theme`: 서울·부산은 기본, 헤네시스는 헤네시스). 따로 고르는 디자인 설정은 없고, 새 디자인은 테마와 그 테마를 단 지역 하나로 더한다(`docs/adding-a-region.md`). 테마는 창밖 마을·창틀·고양이 자리 동물·평소 옷만 바꾸고, 시각·해달·이벤트 판정과 이벤트 모양은 지역 기준이다. 헤네시스처럼 실제 자리가 없는 지역은 반지름 0 이라 "자동"이 고르지 않는다.
- 날씨: Open-Meteo (API 키 없음). WeatherKit은 유료 개발자 계정이 필요해서 쓰지 않는다. 고른 지역과 상관없이 기기 위치에서 받고(`WeatherPlace`), 위치를 못 받으면 위치로 마지막에 고른 지역에서 받는다. 그래서 앱·위젯은 지역을 골랐어도 위치를 늘 본다.
- 이벤트: 해당 국가의 명절·기념일(설날, 추석, 크리스마스, 할로윈 등)과 해·달 이벤트(일출·일몰·보름달). 캘린더 일정 같은 개인 데이터는 다루지 않는다. 한국부터 만든다.
- 언어: 기본은 영어이고 앱 설정에서 한국어를 고른다(`SceneSettings.language`, 위젯 VoiceOver 도 따른다). 화면 문구는 앱·위젯의 `Localizable.xcstrings`(영어 원문, 한국어 번역)에, 지역·이벤트·날씨 이름은 `LocalizedName` 으로 데이터에 둔다. 위젯 갤러리·위젯 편집 문구는 시스템 언어를 따른다.
- 확인: 사용자는 macOS 의 `/Applications` 릴리스 앱과 데스크톱 위젯을 쓴다. 기능은 릴리스해 설치한 macOS 앱에서 확인한다("완료 기준"). iOS 는 코드 서명 인증서가 없어 시뮬레이터로만 실행을 확인한다.

## 명령

- 패키지 테스트: `swift test --package-path ChristofKit`
- 일부 테스트만: `swift test --package-path ChristofKit --filter <테스트 파일 이름 또는 함수 이름>` (예: `--filter OccasionTests`)
- 장면 스냅샷 PNG: `swift run --package-path ChristofKit ChristofSnapshots <출력 폴더>`. 실제 지역·날짜를 `SceneContextFactory` 에 넣고 날씨만 가짜로 준다. 그리기를 바꾸면 PNG를 직접 열어 확인한다.
- 앱 아이콘·README GIF: `swift run --package-path ChristofKit ChristofAssets`(레포 루트에서). 앱과 같은 그리기 코드로 `Christof/AppIcon.icon/Assets/scene.png` 와 `docs/images/*.gif` 를 다시 쓴다. 시안(`design/`)은 읽지 않는다. 그리기를 바꿨으면 다시 만들어 함께 커밋한다.
- 시안과 칸 단위 비교: 스냅샷을 뽑은 뒤 `node ChristofKit/Scripts/compare-design.mjs <출력 폴더> <시안 html>`. 스냅샷 도구가 함께 쓴 격자(`.grid`)와 장면 입력(`scenes.json`)을 시안의 그리기 JS 로 다시 그려 견주고, 시안 옆 `design.css` 의 `--lofi-*` 색과 `LofiPalette` 도 견준다. 그리기를 옮기거나 고치면 팔레트와 모든 격자가 같아야 한다. 코드는 시안 위치를 들고 있지 않는다. 시안 경로는 디자인 세션이 넘길 때 알린다(지금은 `design/00-base.html`).
- 앱·위젯 빌드: `xcodebuild -project Christof.xcodeproj -scheme Christof -destination 'generic/platform=iOS Simulator' build`, macOS는 `-destination 'platform=macOS'`. 개발 팀 없이 Sign to Run Locally로 서명하므로 서명 옵션을 덮어쓰지 않는다.
- 시뮬레이터: 이 Mac에는 iOS 26.5 런타임만 있다(배포 타깃 26.0).
- macOS 위젯은 LaunchServices에 등록된 앱 사본에서 뜬다. macOS 앱을 임시 `-derivedDataPath` 로 빌드하면 그 사본이 등록되어 데스크톱에 옛 위젯이 뜰 수 있다. macOS 빌드는 기본 DerivedData(Xcode와 같은 곳)로 하고, `pluginkit -m -v -p com.apple.widgetkit-extension` 으로 등록 경로를 확인한다.
- 릴리스를 `/Applications` 에 설치해 두면 개발 빌드와 번들 id 가 같아서, 둘 다 등록돼 있을 때 chronod 가 어느 쪽 위젯을 띄울지 정해져 있지 않다(pluginkit 이 보여 주는 쪽과 다를 수 있다). 실제로 뜬 쪽은 `pgrep -lf ChristofWidgetExtension` 으로 본다. 한쪽만 쓰려면 다른 쪽을 `lsregister -u <앱 경로>` 로 등록 해제하고, 쓰려는 앱을 `lsregister -f` 하면 위젯이 다시 불린다. 로컬에서 macOS 를 빌드하면 DerivedData 사본의 위젯이 등록돼 chronod 가 설치한 앱 위젯의 리로드를 "bad extension" 으로 막을 수 있으니, 빌드한 뒤 DerivedData 사본을 `lsregister -u`(위젯은 `pluginkit -r <appex>`) 하고 `/Applications/Christof.app` 을 `lsregister -f` 한다.
- 위젯이 갱신되지 않으면 chronod 로그를 본다(zsh 에서는 `log` 가 내장 명령이라 `/usr/bin/log` 로 부른다): `/usr/bin/log show --last 2h --style compact --predicate 'process == "chronod" AND eventMessage CONTAINS[c] "christof" AND eventMessage CONTAINS "reload"'`. `reload: failed` 면 그 줄에 이유(예: `too large timeline archive`)가 나오고, 그동안 위젯은 placeholder 에 멈춘다.
- 배포: 버전 태그 `git tag v0.2.0 && git push origin v0.2.0` (`vMAJOR.MINOR.PATCH` 만 받는다). `.github/workflows/release.yml` 이 GitHub 러너(`xcode-27`)에서 테스트하고 macOS 앱을 Release 로 빌드해 zip 을 릴리스에 올린다. 앱 버전은 태그, 빌드 번호는 실행 번호로 빌드할 때 넣는다(프로젝트의 `MARKETING_VERSION` 은 로컬 빌드에만 쓰인다). macOS 앱은 Sparkle 로 스스로 업데이트한다: 워크플로가 zip 을 EdDSA 키(secret `SPARKLE_PRIVATE_KEY`, 원본은 키를 만든 Mac 의 로그인 키체인 계정 `christof`)로 서명하고 `appcast.xml` 을 함께 올리면, 앱이 `releases/latest/download/appcast.xml` 을 읽는다. 업데이트는 릴리스 빌드에서만 켜진다. 키를 잃으면 기존 앱이 더는 업데이트되지 않는다. 워크플로는 앱과 위젯을 번들 id 신원(`designated => identifier …`)으로 다시 서명한다. ad-hoc 기본 신원(cdhash)은 빌드마다 바뀌어, 위치 서비스(`/var/db/locationd/clients.plist`)가 옛 cdhash 로 기억한 앱의 위치 요청 등록을 끝내지 않기 때문이다. 설치·삭제는 루트의 `install.sh`(버전 인자로 특정 버전)·`uninstall.sh` 를 README 처럼 main 브랜치에서 받아 실행하므로, 스크립트를 고치면 main 에 올라가야 반영된다. iOS 는 유료 개발자 계정 없이 배포할 수 없어 빠져 있다. 버전은 설정이 호환되지 않게 바뀌면 MAJOR, 이벤트·지역·장면처럼 보이는 것이 늘면 MINOR, 고친 것만 있으면 PATCH 를 올린다.

## 코드 규칙: SRP·OCP

목적은 이벤트를 쉽게 추가·제거·수정하고, 국가별로 확장할 수 있게 하는 것이다.

- 이벤트 하나 = `Occasion` 값 하나. 언제(`OccasionRule`)와 구성 요소별 모양·옷(`OccasionLooks`)을 함께 정의한다. 이벤트 추가·제거·수정은 국가 프로필의 `occasions` 목록에서 그 값만 건드린다.
- 국가 하나 = `CountryProfile` 타입 하나 (지역 목록, 이벤트, 계절). 새 국가는 `Countries/<국가>/` 에 프로필을 만들고 `CountryRegistry.standard` 에 등록만 한다. 공용 코드는 고치지 않는다.
- 날짜 규칙 종류, 창밖 효과, 구성 요소, 모양 종류는 각각 타입 하나씩 둔다 (`OccasionRule`, `OutsideEffect`, `…Painter`, `WindowLook` 등). 같은 종류의 모양은 값으로 늘린다(`DeskItem.tteokguk`). 새 종류는 새 타입으로 추가하고, 종류별로 분기하는 `switch` 를 여러 곳에 늘리지 않는다.
- 데이터 가져오기(날씨·천문·이벤트 판정), 장면 정보 조립(`SceneContextFactory`), 그리기(레이어)는 서로 다른 타입이 맡는다.

## 주석

- 코드로 알 수 없는 것만 주석으로 남긴다: 왜 그렇게 했는지, 외부 제약(API·플랫폼 동작), 의도한 단순화와 그 한계.
- 이름·타입·코드로 드러나는 내용(무엇을 하는지, 매개변수 설명, 예시 값)은 주석으로 되풀이하지 않는다. 공개 API라고 해서 doc 주석을 꼭 달지 않는다.

## 세션

디자인 세션과 개발 세션을 나눠 쓴다. 세션을 열고 첫 입력으로 스킬을 불러 범위를 정한다.

- 디자인: `claude -n 디자인` 으로 열고 `/design`. 시안(`design/`)만 고친다.
- 개발: `claude -n 개발` 로 열고 `/dev`. 앱·위젯 코드만 고친다.
- 두 세션은 같은 작업 트리를 쓴다. 커밋할 때 자기 범위 파일만 경로를 적어 올린다.
- 범위와 확인 방법은 `.claude/skills/design/SKILL.md`, `.claude/skills/dev/SKILL.md` 에 있다.

## 작업 방식

- git으로 관리한다. 빌드·테스트가 통과한 단위로 커밋한다.

## 테스트는 설명서

- 기능을 만들거나 고치면 먼저 그 동작을 `@Suite("<기능>")` 아래 사용자 관점 문장의 `@Test("…")` 로 적어 실패를 보고, 그다음 통과시킨다. `swift test --package-path ChristofKit --filter <Suite 타입>` 출력이 그 기능의 설명서다(예: `AutoRegionSpec`, `WidgetApplyStatusSpec`, `UpdateNoticeSpec`).
- 화면(SwiftUI)과 위젯 코드에는 판단을 두지 않는다. 무엇을 보여 줄지는 ChristofKit 의 값 타입이 정하고 화면은 그 값을 그린다.
- 위치·네트워크·시계처럼 바깥에 기대는 것은 주입받아 실패 경로(권한 없음, 응답 없음, 오류)도 문장으로 남긴다.
- 테스트가 대신하지 못하는 것(OS 권한·서명·위젯 리로드, 예보 데이터 품질)은 아래 완료 기준으로 확인한다.

## UX

흐름·상태·문구에 대해 정한 것과 그 이유는 @docs/UX.md 에 있다.

- 사용자가 대화로 흐름·상태·문구를 정하면 UX.md "결정"에 한 줄을 더한다(날짜, 결정, 왜, 버린 안). 이유를 모르면 지어내지 않고 사용자에게 묻는다.
- 지시가 기존 결정과 부딪히면 고치기 전에 사용자에게 알린다.
- 판단이 있는 결정은 설명서 문장을 먼저 쓰고 결정 줄에 Suite 이름을 단다. 결정·테스트·코드는 한 커밋에 넣는다. 완료 기준의 확인 문장은 그 결정에서 가져온다.

## 완료 기준

빌드·테스트·스냅샷 통과는 완료가 아니다. 사용자가 지시한 동작을 사용자가 쓰는 환경(설치한 macOS 앱과 위젯)에서 직접 확인해야 완료다.

- 시작할 때 지시를 확인할 수 있는 문장 하나로 적는다(예: "서울에서 지역이 '자동'이면 위젯이 서울을 그린다"). 끝낼 때 그 문장을 설치한 앱에서 확인한다.
- 확인 수단: 앱·위젯이 주고받는 값은 공용 설정(`~/Library/Preferences/com.christof.shared.plist`), 앱 자체 설정은 컨테이너(`~/Library/Containers/com.christof.Christof/Data/Library/Preferences/`), 위치·위젯 리로드 같은 시스템 동작은 `/usr/bin/log show`, 버튼 누르기는 `osascript`(System Events)로 본다.
- 외부에 기대는 기능(위치, 날씨, 업데이트, 위젯 리로드)은 성공 경로와 실패 경로를 모두 확인한다. 실패는 `docs/UX.md` 원칙 2대로 화면과 `Logger` 에 남아야 한다.
- 확인하지 못한 것은 완료라고 보고하지 않는다. 무엇을 왜 확인하지 못했는지 먼저 쓰고, 사용자가 확인할 방법을 구체적으로 알린다.
- 같은 기능이 다시 안 된다는 보고를 받으면 증상부터 고치지 않는다. 앞선 수정이 왜 부족했는지, 무엇을 확인하지 않았는지부터 찾는다.

## 구조

- `ChristofKit/`: 로직과 그리기를 모두 담은 로컬 Swift 패키지. 앱과 위젯이 함께 쓴다.
  - 흐름: `Region` + 날짜 + `WeatherForecast` → `SceneContextFactory` → `SceneContext` (순수 값, 타임라인 엔트리에 담김) → `SceneComposer` 가 `DotScene`(때·시드 변화)과 `RoomLayout`(자리)으로 구성 요소를 정해진 순서로 3pt 도트 격자(`DotGrid`)에 칠한다 → `WindowView` 가 격자를 Canvas 사각형으로 그린다.
  - 그리기는 시안(`design/00-base.html`)의 JS 를 같은 이름·순서로 옮긴 것이다. 반올림·hypot·난수도 JS 와 같게 계산해서 같은 칸이 나온다.
  - `Occasions/`: 이벤트 모델과 날짜 규칙 타입. 음력 명절은 `Calendar(identifier: .dangi)` 로 계산한다.
  - `Countries/`: 국가 프로필과 레지스트리. 국가와 무관한 하늘 이벤트는 `CelestialOccasions`.
  - `Rendering/Components`: 구성 요소(벽, 시계, 창문, 고양이, 방 안, 사람). `Rendering/Layers`: 창밖 효과. `Rendering/Looks`: 구성 요소별 이벤트 모양(시안의 `*_LOOKS`). `LofiPalette` 는 design.css 의 `--lofi-*` 색이다. `Rendering/Themes`: 테마(시안의 `THEMES`)와 테마별 창밖·창틀·동물.
- `Christof/`: 컨테이너 앱. `ChristofWidget/`: 위젯 익스텐션. 둘 다 iOS·macOS 멀티플랫폼 타깃이다.
- `design/`(`DESIGN.md`, `design.css`, `*.html`): hunsu(`design/` 에서 `hunsu` 실행)로 만드는 위젯 시안. 디자인 세션이 고치고, 고른 시안은 개발 세션이 `Rendering/` 에 옮긴다.

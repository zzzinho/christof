# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트

macOS·iOS용 위젯. 위젯은 창문 모양이고, 사용자가 고른 지역의 날씨·시간·이벤트를 창밖 풍경으로 보여준다. 이름은 트루먼 쇼에서 가상 세계를 연출하는 감독 Christof에서 따왔다. 이 창문이 가상의 창문이라는 뜻이다.

- 사용자가 지역을 위젯 설정(위젯 편집)에서 고른다. 기본은 "자동"으로, 앱을 열 때 위치로 고른 지역을 쓴다(서울 안이면 서울, 그 밖이거나 위치를 모르면 부산). 위젯은 위치를 직접 보지 않는다. 로그인·계정은 없고, 사용자 로그인이 필요한 기능이나 서비스는 들이지 않는다.
- 날씨: Open-Meteo (API 키 없음). WeatherKit은 유료 개발자 계정이 필요해서 쓰지 않는다.
- 이벤트: 해당 국가의 명절·기념일(설날, 추석, 크리스마스, 할로윈 등)과 해·달 이벤트(일출·일몰·보름달). 캘린더 일정 같은 개인 데이터는 다루지 않는다. 한국부터 만든다.
- 언어: 기본은 영어이고 앱 설정에서 한국어를 고른다(`SceneSettings.language`, 위젯 VoiceOver 도 따른다). 화면 문구는 앱·위젯의 `Localizable.xcstrings`(영어 원문, 한국어 번역)에, 지역·이벤트·날씨 이름은 `LocalizedName` 으로 데이터에 둔다. 위젯 갤러리·위젯 편집 문구는 시스템 언어를 따른다.
- 테스트: 코드 서명 인증서가 없어서 iOS 시뮬레이터로 실행을 확인한다. macOS 타깃은 빌드까지만 검증한다.

## 명령

- 패키지 테스트: `swift test --package-path ChristofKit`
- 일부 테스트만: `swift test --package-path ChristofKit --filter <테스트 파일 이름 또는 함수 이름>` (예: `--filter OccasionTests`)
- 장면 스냅샷 PNG: `swift run --package-path ChristofKit ChristofSnapshots <출력 폴더>`. 실제 지역·날짜를 `SceneContextFactory` 에 넣고 날씨만 가짜로 준다. 그리기를 바꾸면 PNG를 직접 열어 확인한다.
- 시안과 칸 단위 비교: 스냅샷을 뽑은 뒤 `node ChristofKit/Scripts/compare-design.mjs <출력 폴더> <시안 html>`. 스냅샷 도구가 함께 쓴 격자(`.grid`)와 장면 입력(`scenes.json`)을 시안의 그리기 JS 로 다시 그려 견주고, 시안 옆 `design.css` 의 `--lofi-*` 색과 `LofiPalette` 도 견준다. 그리기를 옮기거나 고치면 팔레트와 모든 격자가 같아야 한다. 코드는 시안 위치를 들고 있지 않는다. 시안 경로는 디자인 세션이 넘길 때 알린다(지금은 `design/00-base.html`).
- 앱·위젯 빌드: `xcodebuild -project Christof.xcodeproj -scheme Christof -destination 'generic/platform=iOS Simulator' build`, macOS는 `-destination 'platform=macOS'`. 개발 팀 없이 Sign to Run Locally로 서명하므로 서명 옵션을 덮어쓰지 않는다.
- 시뮬레이터: 이 Mac에는 iOS 26.5 런타임만 있다(배포 타깃 26.0).
- macOS 위젯은 LaunchServices에 등록된 앱 사본에서 뜬다. macOS 앱을 임시 `-derivedDataPath` 로 빌드하면 그 사본이 등록되어 데스크톱에 옛 위젯이 뜰 수 있다. macOS 빌드는 기본 DerivedData(Xcode와 같은 곳)로 하고, `pluginkit -m -v -p com.apple.widgetkit-extension` 으로 등록 경로를 확인한다.
- 릴리스를 `/Applications` 에 설치해 두면 개발 빌드와 번들 id 가 같아서, 둘 다 등록돼 있을 때 chronod 가 어느 쪽 위젯을 띄울지 정해져 있지 않다(pluginkit 이 보여 주는 쪽과 다를 수 있다). 실제로 뜬 쪽은 `pgrep -lf ChristofWidgetExtension` 으로 본다. 한쪽만 쓰려면 다른 쪽을 `lsregister -u <앱 경로>` 로 등록 해제하고, 쓰려는 앱을 `lsregister -f` 하면 위젯이 다시 불린다.
- 위젯이 갱신되지 않으면 chronod 로그를 본다(zsh 에서는 `log` 가 내장 명령이라 `/usr/bin/log` 로 부른다): `/usr/bin/log show --last 2h --style compact --predicate 'process == "chronod" AND eventMessage CONTAINS[c] "christof" AND eventMessage CONTAINS "reload"'`. `reload: failed` 면 그 줄에 이유(예: `too large timeline archive`)가 나오고, 그동안 위젯은 placeholder 에 멈춘다.
- 배포: 버전 태그 `git tag v0.2.0 && git push origin v0.2.0` (`vMAJOR.MINOR.PATCH` 만 받는다). `.github/workflows/release.yml` 이 GitHub 러너(`xcode-27`)에서 테스트하고 macOS 앱을 Release 로 빌드해 zip 을 릴리스에 올린다. 앱 버전은 태그, 빌드 번호는 실행 번호로 빌드할 때 넣는다(프로젝트의 `MARKETING_VERSION` 은 로컬 빌드에만 쓰인다). macOS 앱은 Sparkle 로 스스로 업데이트한다: 워크플로가 zip 을 EdDSA 키(secret `SPARKLE_PRIVATE_KEY`, 원본은 키를 만든 Mac 의 로그인 키체인 계정 `christof`)로 서명하고 `appcast.xml` 을 함께 올리면, 앱이 `releases/latest/download/appcast.xml` 을 읽는다. 업데이트는 릴리스 빌드에서만 켜진다. 키를 잃으면 기존 앱이 더는 업데이트되지 않는다. 설치·삭제는 루트의 `install.sh`(버전 인자로 특정 버전)·`uninstall.sh` 를 README 처럼 main 브랜치에서 받아 실행하므로, 스크립트를 고치면 main 에 올라가야 반영된다. iOS 는 유료 개발자 계정 없이 배포할 수 없어 빠져 있다. 버전은 설정이 호환되지 않게 바뀌면 MAJOR, 이벤트·지역·장면처럼 보이는 것이 늘면 MINOR, 고친 것만 있으면 PATCH 를 올린다.

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

## 구조

- `ChristofKit/`: 로직과 그리기를 모두 담은 로컬 Swift 패키지. 앱과 위젯이 함께 쓴다.
  - 흐름: `Region` + 날짜 + `WeatherForecast` → `SceneContextFactory` → `SceneContext` (순수 값, 타임라인 엔트리에 담김) → `SceneComposer` 가 `DotScene`(때·시드 변화)과 `RoomLayout`(자리)으로 구성 요소를 정해진 순서로 3pt 도트 격자(`DotGrid`)에 칠한다 → `WindowView` 가 격자를 Canvas 사각형으로 그린다.
  - 그리기는 시안(`design/00-base.html`)의 JS 를 같은 이름·순서로 옮긴 것이다. 반올림·hypot·난수도 JS 와 같게 계산해서 같은 칸이 나온다.
  - `Occasions/`: 이벤트 모델과 날짜 규칙 타입. 음력 명절은 `Calendar(identifier: .dangi)` 로 계산한다.
  - `Countries/`: 국가 프로필과 레지스트리. 국가와 무관한 하늘 이벤트는 `CelestialOccasions`.
  - `Rendering/Components`: 구성 요소(벽, 시계, 창문, 고양이, 방 안, 사람). `Rendering/Layers`: 창밖 효과. `Rendering/Looks`: 구성 요소별 이벤트 모양(시안의 `*_LOOKS`). `LofiPalette` 는 design.css 의 `--lofi-*` 색이다.
- `Christof/`: 컨테이너 앱. `ChristofWidget/`: 위젯 익스텐션. 둘 다 iOS·macOS 멀티플랫폼 타깃이다.
- `design/`(`DESIGN.md`, `design.css`, `*.html`): hunsu(`design/` 에서 `hunsu` 실행)로 만드는 위젯 시안. 디자인 세션이 고치고, 고른 시안은 개발 세션이 `Rendering/` 에 옮긴다.

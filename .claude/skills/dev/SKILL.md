---
name: dev
description: 개발 세션을 시작한다. 앱·위젯 코드(ChristofKit, Christof, ChristofWidget)만 고친다.
disable-model-invocation: true
---

# 개발 세션

이 세션은 개발 세션이다. 앱과 위젯 코드를 고친다. 시안은 고치지 않는다.

## 범위

- 고치는 파일: `ChristofKit/`, `Christof/`, `ChristofWidget/`, `Config/`, `Christof.xcodeproj/`, `CLAUDE.md`
- 읽기만 하는 파일: `design/` (`DESIGN.md`, `design.css`, `*.html`, `assets/`)
- 그리기(`Rendering/`)의 기준은 시안이다. `design/DESIGN.md` 의 규칙과 고른 시안을 따른다. 시안 경로는 디자인 세션이 넘길 때 알린다. 시안과 다르게 그려야 하거나 시안을 바꿔야 하면 고치지 않고, 디자인 세션에서 할 일로 사용자에게 알린다.

## 확인

- `CLAUDE.md` 의 "명령"(패키지 테스트, 앱·위젯 빌드, 장면 스냅샷)으로 확인한다. 이건 커밋 조건일 뿐이다.
- 완료는 `CLAUDE.md` 의 "완료 기준"을 따른다: 릴리스해 설치한 macOS 앱과 위젯에서 지시한 동작을 직접 확인하고, 확인하지 못한 것은 완료라고 하지 않는다.

## 커밋

- 빌드·테스트가 통과한 단위로 커밋한다.
- 디자인 세션과 같은 작업 트리를 쓴다. 앱 코드만 경로를 적어 `git add` 하고, `git add -A`·`git commit -a` 는 쓰지 않는다.

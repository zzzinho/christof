---
name: design
description: 디자인 세션을 시작한다. 위젯 시안(design/ 의 DESIGN.md, design.css, *.html)만 고친다.
disable-model-invocation: true
---

# 디자인 세션

이 세션은 디자인 세션이다. 위젯 시안을 만들고 고른다. 앱 코드는 고치지 않는다.

먼저 `design/DESIGN.md` 를 읽는다. 시안의 규칙과 지금까지 정한 것이 모두 거기 있다.

## 범위

- 고치는 파일: `design/` (`DESIGN.md`, `design.css`, `*.html`, `assets/`)
- 읽기만 하는 파일: `Christof/`, `ChristofKit/`, `ChristofWidget/`, `Config/`, `Christof.xcodeproj/`, `CLAUDE.md`, `docs/UX.md`
- 앱 코드를 바꿔야 하는 일(시안을 `Rendering/` 에 옮기기 등)은 고치지 않고, 개발 세션에서 할 일로 사용자에게 알린다.

## 확인

- 시안은 hunsu 로 본다. `design/` 에서 `hunsu` 를 실행하면 http://127.0.0.1:<포트>/p/<파일> 로 열린다. 포트는 hunsu 가 폴더마다 정하므로 실행할 때 나온 주소를 쓴다. hunsu 는 페이지와 `design.css` 만 서빙하므로 스크립트는 페이지 안에 담는다.
- 그림을 바꾸면 페이지를 캡처해 직접 본다. 전체 화면 캡처는 하지 않는다.
  `"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=2 --window-size=1200,1300 --virtual-time-budget=10000 --screenshot=<png> "http://127.0.0.1:<포트>/p/<파일>"`
- 고를 것이 있으면 비교안을 나란히 그려 보이고 사용자가 고르게 한다.

## 커밋

- 렌더를 확인한 단위로 커밋한다.
- 개발 세션과 같은 작업 트리를 쓴다. 디자인 파일만 경로를 적어 `git add` 하고, `git add -A`·`git commit -a` 는 쓰지 않는다.

# 표지 SNS 시안 (2026-10-03)

Esel의 최신 디자인이다. 화면은 Claude Design 캔버스(`harness.json.activeDesign.canvas`, 비공개)에 있고, 이 폴더의 생성기로 만든다. 제품 기준과 결정 이력은 [앱 하네스](../../../../docs/ESEL_HARNESS.md)가 정한다.

## 캔버스 페이지

| 페이지 | 내용 |
| --- | --- |
| 00 무드보드 | 키워드·말투, 12색, Esel 문법 |
| 01 디자인 토큰 | 바탕색, 12색 물감, 글꼴, 간격, 모서리, 깊이, 움직임 곡선 |
| 02 컴포넌트 | 캡슐 메뉴, 로그인 바, 버튼, 선택, 입력, 작은 표지, 정보 줄 |
| 03 화면 · 표지 SNS | C1–C8: 표지 피드, 어두운 사진, 펼침면, 가판대, 서가(표지/책등), 오늘 호 만들기, 스크롤, 같은 색 발행 전 |
| 03 화면 · 로그인 · 창간 | J1–J7: 비로그인 표지 → 로그인 → 창간(색·촬영·제호·얼굴) → 창간호 |
| 04 모션 | 적용된 동작 4개와 제안 7개, 반복 재생 견본 |
| 보관 · … | 이전 탐색(미니멀, 아틀리에, 피드 시안 20장) |

## 폴더

| 경로 | 내용 |
| --- | --- |
| `generator/lib.mjs` | 12색(`PAINT`), 예시 인물 27명(`PEOPLE`, Vision으로 잰 얼굴 위치), 로그인 예시 사용자(`ME`), 화면 조각(표지·물감 가리기·목 아래·제호 크기·글라스 캡슐) |
| `generator/scroll.mjs` | 제호 녹아들기와 로그인 바 스크롤 로직 |
| `generator/gen-cover2.mjs` · `gen-join.mjs` · `gen-boards.mjs` | C1–C8, J1–J7, 00·01·02·04 보드 생성. `--index`를 붙이면 `project/canvas.json`도 고침 |
| `generator/project/` | 생성된 `.dc.html`과 캔버스 색인 사본 |
| `generator/faces.swift` | macOS Vision 얼굴 상자 측정: `swift generator/faces.swift assets/models/*.jpg` |
| `generator/stretch.cjs` · `recolor.cjs` | 기존 물감 3색을 조금 길고 얇게 늘리고, 같은 모양으로 9색을 더 칠함 |
| `paint/` | 12색 물감 PNG(투명 배경, 1200×600) |
| `screenshots/` | 로컬 렌더 캡처(보드 4장, 화면 4장) |

## 다시 만들기

저장소 루트에서:

```bash
npm run design:build
npm run check:harness
```

`design:build`는 `generator/project/`만 다시 쓴다. 캔버스에 반영하려면 바뀐 `.dc.html`을 캔버스에 올려야 한다. 캔버스에서 사람이 직접 고친 파일이 있으면 먼저 캔버스에서 읽어 와 합친다. 업로드한 사진·물감은 캔버스 안에서 `/_blob/<id>`로 참조하므로, 새 이미지를 쓰려면 먼저 캔버스에 올리고 받은 id를 `lib.mjs`에 적는다.

예시 사진은 `assets/models/`(출처 [models-sources](../../../../assets/models-sources.md)), dana 표지는 `assets/demo/blue-city.jpg`다.

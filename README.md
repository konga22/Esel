# Esel

오늘의 색으로 입은 착장을 잡지 표지로 발행하는 패션 SNS를 설계하는 저장소다. 개인 피드는 짧은 잡지, 프로필은 서가, 가입은 창간이다.

이 저장소에는 시기가 다른 자료가 함께 있다. **아래 "지금 기준" 표에 있는 것만 최신**이고, "보관된 자료"는 비교와 기록용이다. 다른 AI와 작업할 때는 [AGENTS.md](AGENTS.md) → [앱 하네스](docs/ESEL_HARNESS.md) → [harness.json](harness.json) 순서로 읽게 한다.

## 지금 기준

| 보고 싶은 것 | 위치 |
|---|---|
| 최신 중간발표 PPT | [콘텐츠 3종·로컬 구현 반영본](docs/presentation/README.md): 9번 슬라이드와 발표자 노트 갱신 |
| 일·주·월 특집·주간 공개 참여·저장 보완 | [최신 로컬 콘텐츠 안내](docs/flutter/PERIOD_COLLECTIONS.md): 직접 선정·선정 이유·기간별 조회·서버 인계 범위 |
| 서버 없이 중간발표 시연 실행 | [Flutter 중간발표 안내](docs/flutter/MIDTERM_DEMO.md): 휴대폰 실행 명령·시연 순서·검증 범위 |
| 두 콘텐츠 로컬 시연·서버 전달안 | [주간 드레스코드 / 같은 옷, 다른 코디](docs/flutter/LOCAL_CONTENTS.md), [검증·목업 점검](docs/flutter/CONTENT_VALIDATION.md) |
| 디자인 보드 00~04와 화면 | [docs/design](docs/design/README.md): 캔버스 캡처와 값 표 |
| 기능 개발 가이드 | [docs/dev](docs/dev/README.md): 목업 → 앱·서버 개발 순서, [기능 목록](docs/dev/FEATURES.md), 목업 화면 그림 |
| 서버 | [server](server/README.md): 실행법, [AI 작업 규칙](server/AGENTS.md), [API 약속](server/api-contract.json), [배움 안내](server/docs/LEARN.md) |
| 눌러 보는 앱 목업 | [20261011-app-mockup](.codex/temp/prototype/20261011-app-mockup/README.md): 휴대폰에서 여는 비공개 링크 |
| 디자인 원본 | [20261003-cover-sns](.codex/temp/prototype/20261003-cover-sns/README.md): 비공개 Claude Design 캔버스와 그 생성기 |
| 제품 결정·계약·검증 | [앱 하네스](docs/ESEL_HARNESS.md), [harness.json](harness.json) |
| 같은 색 공개·트윈·복구 규칙과 테스트 | `20260906-minimal-gallery/src/*.js`, `tests/*.test.cjs` (규칙만 기준, 화면은 보관) |
| 잡지형 SNS 리서치 | [docs/research](docs/research/2026-10-03-magazine-sns/README.md): 근거 자료이며 결정이 아님 |

```bash
npm run check:harness   # 문서·경로·색·인물·계약 정합성
npm run test:rules      # 같은 색 공개·트윈·복구 규칙 테스트
npm run design:build    # 캔버스 화면 파일 다시 만들기
npm run design:capture  # docs/design 그림 다시 찍기
npm run mockup:build    # 앱 목업 다시 만들기
npm run dev:docs        # 기능 목록 표와 앱 디자인 토큰 다시 만들기
```

## 보관된 자료

최신 디자인이 아니다. 지우지 않고 남겨 두되, 결정의 근거나 작업 지시로 쓰지 않는다. 각 문서 맨 위에 보관 표시가 있고, 목록은 `harness.json.archive`에 있다.

| 위치 | 무엇이었나 | 대신 볼 것 |
|---|---|---|
| `.codex/temp/prototype/20260905-esel-gallery/` | 9월 5일 갤러리형 Expo 앱의 설계 기록과 웹 빌드 | 디자인 보드, 앱 목업 |
| `.codex/temp/prototype/20260906-art-directions/` | 9월 6일 미술관·아틀리에 방향 탐색 | 디자인 보드 |
| `.codex/temp/prototype/20260906-minimal-gallery/` 화면 | 9월 6일 미니멀 갤러리 시안 화면(`npm run preview:rules`). 규칙·테스트는 지금도 기준 | 디자인 보드, 앱 목업 |
| `.codex/temp/prototype/20260906-social-loop/` | 9월 6일 참여·색 기록 데모 | 앱 목업의 월간 색 기록·트윈 |
| `.codex/temp/prototype/20260906-paint-feed/` | 9월 6일 닉네임 옆 물감 표식 실험 | 디자인 보드 01의 12색 물감 |
| `.codex/temp/20260905-1803-feat-core-ux-workflow.md`, `.codex/temp/20260906-0210-feat-feed-chrome-ui-workflow.md` | 9월 작업 기록 | 앱 하네스의 결정 이력 |
| `assets/esel-app-icon-*.png` 중 `esel-app-icon-bg-F9F9FB.png`가 아닌 것 | 이전 아이콘 시안 | `assets/esel-app-icon-bg-F9F9FB.png`(사용자 선택본) |
| Claude Design 캔버스의 "보관 · …" 페이지 | 피드 시안 20장, 아틀리에, 미니멀 | 캔버스 00~04 페이지 |

## 갱신하지 않는 자료

| 위치 | 상태 |
|---|---|
| 피그마 파일(팀원 정리본, 2026-10-11 기준 60화면) | 이 저장소에서 고치지 않는 참고 자료다. 흐름과 문구는 앱 목업에 반영했고, 규칙이 다를 때는 하네스를 따른다 |

### Flutter 앱 실행

2026-10-15에 클라이언트를 Expo에서 Flutter로 바꿨다([하네스 §2](docs/ESEL_HARNESS.md)). 이전 Expo 앱(`app/`, `src/`, `tests/`)은 지웠고, 마지막 상태는 커밋 `bbdaf2d`에서 볼 수 있다.

```bash
cd flutter_app
flutter pub get
flutter devices
flutter run -d <기기ID> --dart-define=ESEL_API_MODE=mock   # Android 기기·에뮬레이터
flutter analyze
flutter test
```

`--dart-define=ESEL_API_MODE=mock`을 빼면 서버 모드라서, 서버 없이는 옛 기기 보관함 화면만 보인다. 시연 순서와 검증 범위는 [Flutter 중간발표 안내](docs/flutter/MIDTERM_DEMO.md)에 있다. iOS는 맥(Xcode)에서만 빌드할 수 있다.

직접 구축 서버는 NestJS·PostgreSQL·Prisma로 구성되어 있고, 현재 API 계약 61개가 모두 구현되어 있다. 인증·서버 디스크 사진 업로드·오늘의 캔버스 발행·피드·팔레트·친구·트윈·공유·신고·차단·호 삭제까지 서버 검증을 거쳤다. Flutter의 전체 화면이 모두 서버와 연결된 것은 아니며, 시연 모드의 기록은 기기에만 남는다(웹은 메모리). 자세한 실행법과 정책은 [서버 README](server/README.md)를 따른다. 사진 출처는 [demo-sources](assets/demo-sources.md)와 [models-sources](assets/models-sources.md)에 있고, 사진에 붙인 이름·숫자는 예시다.

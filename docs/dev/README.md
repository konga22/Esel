# Esel 기능 개발 가이드

앱 목업을 실제로 동작하는 앱(Flutter, `flutter_app/`)과 서버로 만드는 사람과 AI를 위한 안내다. 무엇을 만들지는 [기능 목록](FEATURES.md)에, 어떻게 만들고 언제 끝났다고 할지는 이 문서에 있다. 먼저 [AGENTS.md](../../AGENTS.md)와 [앱 하네스](../ESEL_HARNESS.md)를 읽는다.

## 1. 무엇이 기준인가

서로 다를 때는 위의 것이 이긴다.

| 순서 | 기준 | 정하는 것 | 위치 |
|---|---|---|---|
| 1 | 사용자의 최신 요청 | 모든 것 | 대화 |
| 2 | 제품 계약 P01~P18 | 공개 범위, 발행, 복원, 트윈, 제호, 숫자 공개 | [앱 하네스 §5](../ESEL_HARNESS.md) |
| 3 | 앱 목업 | 화면 구성, 흐름, 문구, 상태 | [목업 화면 그림](screens/), [목업 원본](../../.codex/temp/prototype/20261011-app-mockup/README.md) |
| 4 | 디자인 보드 | 색·글꼴·간격·모서리·그림자·움직임 값과 컴포넌트 치수 | [docs/design](../design/README.md), 생성 파일 `flutter_app/lib/core/design/tokens.g.dart` |
| 5 | 팀원 정리 피그마 | 참고 자료. 이 저장소에서 고치지 않는다 | 피그마 파일(링크는 하네스) |

예: 피그마 S2는 이름을 "2–20자"로 적었지만 계약 P14(영문 소문자 2~10자)가 이긴다.

## 2. 목업에서 그대로 옮길 것과 바꿀 것

목업은 화면 견본이다. 버튼이 다음 그림으로 넘어가도 실제 기능이 된 것은 아니다.

| 목업에 있는 것 | 실제 앱에서 |
|---|---|
| 화면 구성, 문구, 화면 사이 흐름, 움직임 값 | 그대로 옮긴다 |
| 예시 사람(selin, dana…), 날짜 2026-09-06, Nº 249, "같은 색 64명" 같은 숫자 | 로그인한 사람과 서버 데이터로 바꾼다 |
| 메모리 상태(새로고침하면 초기화) | 서버 저장. 앱에는 화면 상태만 둔다 |
| `시연` 표시 버튼(초대 수락, 게시 도착, 공개 동의) | 옮기지 않는다. 상대의 실제 행동을 서버가 확인하고 알림으로 넘긴다 |
| 공유 시트의 "메시지·다른 앱" 목록, `example.com` 링크 | 기기 공유 메뉴와 서버가 발급한 링크 |
| 촬영 화면의 예시 사진, "앨범에서 고르기" 안내 문구 | `image_picker`(카메라·앨범)의 실제 사진 |
| "목업이라 실제로 로그인하지 않아요", "미리보기 처음으로", "목업을 처음부터 다시 보기" | 지운다. 로그아웃·탈퇴 뒤에는 로그인 화면으로 |
| 393×852 고정 화면을 `zoom`으로 키우고 줄이는 방식 | Flutter 레이아웃과 `SafeArea`. 폭 360~430에서 깨지지 않게. 넓은 창(웹·데스크톱)은 `EselPhoneFrame`이 휴대폰 폭으로 묶는다 |
| 목업에 없는 로딩·빈 화면·오류 | 새로 만든다. 02 컴포넌트로 그리고, 문구는 "무엇이 잘못됐고 어떻게 하면 되는지"를 한 줄로 |

## 3. 구조

### 앱 (Flutter, `flutter_app/`)

2026-10-15에 Expo에서 Flutter로 바꿨다([앱 하네스 §2](../ESEL_HARNESS.md)). 팀원 실행 안내는 Android 기기·에뮬레이터 기준이고, iOS는 맥(Xcode)에서만 빌드한다.

```text
flutter_app/lib/app/                        시작(bootstrap), 의존성(service_locator), 화면 상태(routing/app_routes.dart), 하단 캡슐(app.dart)
flutter_app/lib/core/design/tokens.g.dart   생성 파일. harness.json에서 `npm run dev:docs`로 만든다. 손으로 고치지 않는다
flutter_app/lib/core/design/                글꼴(typography.dart)·테마. legacy_tokens.dart는 하네스 밖 값이라 정리 대상
flutter_app/lib/core/ui/                    02 컴포넌트: 버튼, 칩, 글라스(EselGlass), 작은 표지, 물감, 휴대폰 폭 프레임
flutter_app/lib/core/network/, storage/     서버 호출(http_client.dart)과 토큰 보안 저장
flutter_app/lib/core/time/                  서비스 날짜(Asia/Seoul)와 시계. 테스트에서 시간을 주입한다
flutter_app/lib/core/mock/                  mock 모드 예시 인물 데이터
flutter_app/lib/features/<기능>/domain/     화면·네트워크와 무관한 규칙(같은 색, 발행, 복원, 트윈, 제호). 순수 함수 + 테스트
flutter_app/lib/features/<기능>/data/       mock 소스·서버 소스·저장소. `--dart-define=ESEL_API_MODE` 하나로 바꾼다
flutter_app/lib/features/<기능>/presentation/  화면(screens)과 상태(controllers)
flutter_app/test/                           domain·data·위젯 테스트 (`flutter test`)
```

data 계층은 인증(`features/auth/data`), 기기 보관함(`features/drafts/data`), 피드·가판대·서가 소스(`features/{feed,stand,magazine}/data/sources`), 예시 표지(`features/issue/data`)에 있다. 피드·가판대·서가는 소스 인터페이스의 mock 구현을 읽고, 서버 구현은 아직 `NotImplementedFailure`다. 오늘의 색 후보(`features/today/domain/rules/daily_candidates.dart`)는 날짜만으로 정해지는 mock 규칙이다.

| 목업 경로 | 앱 위치(현재) | 화면 |
|---|---|---|
| `intro` | `features/intro/.../intro_screen.dart`, 로그인 `features/auth/.../login_sheet.dart` | J1, J1b, J2 |
| `join-color` … `join-done` | `features/onboarding/.../onboarding_screen.dart` | J3~J7 |
| `feed` | `features/feed/.../feed_screen.dart` | C1, C2, C7 |
| `stand`, `same` | `features/stand/.../stand_screen.dart` | C4, C8 |
| `me`, `reactions` | `features/magazine/.../my_magazine_screen.dart` | M1, A4 |
| `spread` | `features/issue/.../issue_bottom_sheet.dart` | C3 |
| `shelf` | `features/magazine/.../shelf_screen.dart` | C5 |
| `make` | `features/publishing/.../publish_screen.dart`, 편집 `features/drafts/.../cover_editor_screen.dart` | C6 |
| `record`, `day`, `restore`, `restored` | `features/records/.../monthly_record_screen.dart` | R1~R5 |
| `friends`, `friend`, `friend-added` | `features/friends/.../friends_screen.dart` | F1~F3 |
| `twin*` | `features/twin/.../twin_screen.dart` | T1~T10 |
| `settings`, `profile`, `notifications`, `account`, `logout`, `delete*` | `features/settings/.../settings_screen.dart` | S1~S6 |

화면 전환은 `app.dart`의 상태(`AppTab`, `ActiveScreen`)로 한다. 라우터 패키지는 승인 없이 추가하지 않는다. 하단 글라스 캡슐(오늘의 색·만들기·내 잡지)은 `app.dart`의 `_buildGlassBottomBar` 한 곳에 둔다. `features/drafts/presentation/device_home_screen.dart`는 서버 모드에서만 보이는 이전 기기 보관함 화면이다. 새 화면이 그 역할을 대체하면 같은 작업에서 정리한다.

### 서버 (`server/`)

2026-10-15에 팀원의 서버 기반([konga22/Esel#4](https://github.com/konga22/Esel/pull/4), NestJS·Prisma·PostgreSQL·Docker Compose)과 서버 하네스([konga22/Esel#7](https://github.com/konga22/Esel/pull/7))를 main에 합쳤다. 서버 작업은 [server/AGENTS.md](../../server/AGENTS.md)를 먼저 읽는다.

- **정본 관계**: 경로·권한·오류 코드는 [server/api-contract.json](../../server/api-contract.json), 요청·응답 데이터 모양은 Swagger(`/api/docs`, 코드의 DTO)다. [기능 목록](FEATURES.md)의 서버 줄은 요약이다.
- 만드는 방식은 [API 규칙](../../server/docs/API_RULES.md), 처음 배우는 사람의 순서는 [배움 안내](../../server/docs/LEARN.md), 리뷰 목록은 [리뷰 체크리스트](../../server/docs/REVIEW.md), 실행과 구조는 [서버 README](../../server/README.md)와 [ARCHITECTURE](../../server/ARCHITECTURE.md)에 있다.
- `controller → service → Prisma` 흐름을 지키고, 공개 권한과 발행 규칙은 `<모듈>.rules.ts`의 순수 함수로 두어 테스트한다.
- API 테스트는 `server/test/contracts/<모듈>.e2e-spec.ts`에 있다. `check:server`가 약속을 기능 목록·하네스 계약(P01~P18)·공개 금지 숫자와 대조하고, todo만 있는 API를 done으로 올리면 실패한다.
- 초기 스키마에 없는 데이터: 좋아요·스크랩, 독자 한 줄, 구독, 친구와 친구 요청, 트윈(초대·각자 게시·동의), 색 복원 기록, 알림 설정, 공유 링크, 프로필 소개. 각 기능을 만들 때 새 migration으로 추가한다.
- 클라이언트 잠금은 보안이 아니다. 피드·가판대·서가·공유 링크·이미지 URL 모두 서버가 같은 권한을 검사한다.

## 4. 기능 하나를 만드는 순서

2026-10-17 사용자 요청의 DEV-21·22는 [로컬 콘텐츠 안내](../flutter/LOCAL_CONTENTS.md)를 함께 따른다. 서버 연결 전 앱 단계까지만 검증하며 선행 기능 및 서버 전체를 done으로 올리지 않는다. 기존 domain/data/presentation·모드 선택·발행 경로를 재사용한다.

2026-10-18 확장한 DEV-23 일·주·월 표지 특집과 DEV-21 기기 내 공개 참여 목록은 [최신 기간 특집 계약](../flutter/PERIOD_COLLECTIONS.md)을 따른다. 로컬 직접 선정·선정 이유·저장 보완까지이며 서버 운영자의 공식 선정·실제 원격 참여·동기화 완료로 표시하지 않는다.

[기능 목록](FEATURES.md)은 단계 0(기반)부터 7(운영)까지 나뉘어 있다. 단계를 건너뛰지 않는다.

1. **고르기**: 선행 기능이 모두 `done`인 `todo` 하나를 고른다. [features.json](features.json)에서 상태를 `doing`으로 바꾸고 `npm run dev:docs`를 실행한다.
2. **보기**: 그 기능의 목업 화면 그림([screens/](screens/))을 본다. 움직임이나 흐름을 직접 눌러 보려면 `node .codex/temp/prototype/20261011-app-mockup/build.mjs --local`로 만든 `dist/_local.html`을 연다.
3. **테스트 먼저**: 기능의 "합격 기준"을 기능 목록의 "추가할 테스트" 경로에 테스트로 쓴다.
4. **만들기**: `features/<기능>/domain` → `data`(mock 소스·저장소) → 화면 → 서버 엔드포인트와 API 테스트(`server/`) → 서버 소스로 교체 순서로 만든다.
5. **비교**: 같은 상태의 목업 그림과 앱 화면을 393×852에서 나란히 보고, 다른 점과 이유를 작업 기록에 적는다.
6. **검사**: 아래 명령을 모두 돌리고, 실패하면 고친다. 돌리지 못한 것은 못 돌렸다고 적는다.
7. **마치기**: 상태를 `done`으로 바꾸고 `npm run dev:docs`. 커밋과 푸시는 사용자에게 매번 허락을 받는다.

```bash
npm run check:harness   # 하네스·기능 목록·생성 파일 정합성 (done 기능의 테스트 파일이 있는지도 확인)
npm run test:rules      # 기준 규칙 테스트
cd flutter_app && flutter analyze && flutter test   # 앱 정적 검사·테스트
cd server && npm run check:server && npm run lint && npm test && npm run build   # 서버 약속·정적 검사·단위 테스트
# 서버 API 테스트: PostgreSQL을 띄우고 npx prisma migrate deploy && npm run test:e2e (server/README.md)
```

PR을 올리면 [CI](../../.github/workflows/ci.yml)가 하네스·규칙 검사를 Ubuntu와 Windows에서, Flutter 검사(Flutter 3.44.0)를 Ubuntu에서 다시 돌린다. 서버가 바뀌면 [서버 CI](../../.github/workflows/server.yml)가 Node 24와 PostgreSQL로 서버 검사·API 테스트를 돌리고, Docker 구성을 실제로 띄워 본다. 내 PC에서만 통과하는 변경(절대 경로 링크, 줄바꿈 차이, SDK 차이)은 여기서 걸린다.

## 5. 완료 기준 (모든 기능 공통)

- 기능의 합격 기준이 테스트로 있고 통과한다. `done`인데 테스트 파일이 없으면 `check:harness`가 실패한다.
- 남의 표지·서가·피드 응답과 타입에 좋아요·구독자·독자 한 줄·스크랩 수가 없다(P18).
- 잠긴 같은 색 표지의 이름·사진·ID가 응답에 없다(P01).
- 누르는 곳은 48×48 이상, 스크린 리더 라벨이 있고, 글자 200%에서 겹치지 않는다.
- 색·글꼴·간격·움직임 값은 `tokens.g.dart`(와 `typography.dart`)에서만 가져온다. 오늘의 색 hex를 코드에 쓰지 않는다.
- 움직임 줄이기 설정에서 움직임 없이 바뀐다. 글라스는 투명도 줄이기·고대비에서 단색이다.
- 로딩·빈 화면·오류가 있다.
- `시연` 버튼, 예시 이름, 고정 날짜가 남아 있지 않다.
- 목업 그림과의 차이를 적었다.

## 6. 하지 말 것

- 계약 P01~P18을 화면 편의 때문에 약하게 만들지 않는다. 바꿔야 하면 사용자에게 묻는다.
- 새 라이브러리, BaaS(Supabase·Firebase 등), 외부 서비스를 사용자 승인 없이 추가하지 않는다. 팀은 직접 운영 서버를 택했다(PR #4).
- 피그마와 Claude Design 캔버스 원본을 고치지 않는다. [README의 보관 자료](../../README.md#보관된-자료)를 근거로 쓰지 않는다.
- 생성 파일(`docs/dev/FEATURES.md`, `flutter_app/lib/core/design/tokens.g.dart`, `docs/dev/screens/*`)을 손으로 고치지 않는다.
- `.env`와 비밀값을 커밋하지 않는다. 확인하지 않은 동작을 "완료"라고 쓰지 않는다.

## 7. 사용자에게 물어야 하는 것

기능 목록의 "사용자 결정이 필요한 것"을 만나면, 정해진 범위까지만 만들고 멈춰서 묻는다. 큰 것은 다음과 같다.

- 로그인 수단과 순서(이메일 먼저, Apple·Google 시점), 인증 메일 발송 서비스
- 이미지 저장소, 기기 얼굴 감지 방식
- 오늘의 후보 3색을 고르는 방식, 같은 색 미리보기 3장 기준, 미성년자 판별
- 푸시 알림 서비스, 공유 링크를 앱 없이 열었을 때의 웹 화면
- 제호 금칙어·변경 허용, 신고·차단·삭제 정책, 탈퇴 시 공동 트윈 처리

## 8. 생성과 갱신

| 명령 | 하는 일 |
|---|---|
| `npm run dev:docs` | `features.json` → `FEATURES.md`, `harness.json`·생성기 물감 → `flutter_app/lib/core/design/tokens.g.dart` |
| `npm run mockup:capture` | 목업을 상태별로 찍어 `docs/dev/screens/`에 쓴다(화면 54장, Chrome 필요) |
| `npm run mockup:build` | 목업 다시 만들기 |

목업이나 디자인 값이 바뀌면 이 순서로 다시 만들고 `check:harness`를 돌린다. 기능 목록의 화면은 [화면 등록부](FEATURES.md#화면-등록부)에 있는 ID만 쓸 수 있고, 검사가 목업 경로·그림·계약 연결을 확인한다.

## 9. 다른 AI에게 줄 짧은 지시

> 이 저장소의 AGENTS.md, docs/ESEL_HARNESS.md, docs/dev/README.md를 먼저 읽어라. docs/dev/FEATURES.md에서 선행 기능이 끝난 기능 하나만 골라, 목업 그림(docs/dev/screens)과 같은 화면을 만들고 합격 기준을 테스트로 증명하라. 계약 P01~P18은 서버에서 강제하고, 목업의 시연 버튼과 예시 데이터는 옮기지 마라. 끝나면 features.json 상태를 고치고 npm run dev:docs와 npm run check:harness를 돌린 뒤, 확인한 것과 못 한 것을 나눠 보고하라.

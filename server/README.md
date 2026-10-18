# Esel server

Esel의 직접 구축 REST API입니다. NestJS, PostgreSQL, Prisma로 구성합니다.

구현 구조와 설계 결정은 [ARCHITECTURE.md](ARCHITECTURE.md)를 참고하세요.

## 처음 읽을 것

| 문서 | 내용 |
|---|---|
| [AGENTS.md](AGENTS.md) | AI가 이 폴더에서 일하는 규칙. 루트 `AGENTS.md`의 우선순위 아래에서 서버 세부 규칙만 보충한다 |
| [docs/LEARN.md](docs/LEARN.md) | 서버를 처음 배우는 사람을 위한 설명과 미션 순서(미션마다 AI 지시문) |
| [docs/API_RULES.md](docs/API_RULES.md) | 주소·응답·오류·폴더 규칙 |
| [api-contract.json](api-contract.json) | 만들 API 약속 목록. 여기 없는 API는 만들지 않는다. 경로·권한·오류 코드의 정본이고, 요청·응답 데이터 모양의 정본은 Swagger(코드의 DTO)다 |
| [docs/REVIEW.md](docs/REVIEW.md) | PR 리뷰 체크리스트 |

```bash
npm run check:server   # 약속·규칙·루트 하네스 대조. 설치 없이 동작하고, 실패하면 이유와 고치는 법을 알려 준다(실패 0건이어야 한다)
npm run test:harness   # 검사 스크립트 자체 테스트
```

## 로컬 실행

저장소 루트에서 PostgreSQL을 시작합니다.

```bash
docker compose up -d postgres
```

서버 디렉터리에서 환경변수와 DB를 준비한 뒤 실행합니다. Node.js 24 LTS를 권장합니다(Docker와 같음).

```bash
cp .env.example .env
npm install            # 끝나면 prisma generate가 자동으로 돈다(postinstall)
npm run prisma:deploy  # 커밋된 migration 적용(12색 기준 데이터 포함)
npm run start:dev
```

- API: `http://localhost:3000/api`
- 상태 확인: `http://localhost:3000/api/health`
- Swagger: `http://localhost:3000/api/docs` (운영 `NODE_ENV=production`에서는 꺼짐)

`.env.example`과 `compose.yaml`의 비밀번호(`esel_dev`)는 개발용입니다. 운영에서는 `CORS_ORIGINS`를 실제 앱 주소로 꼭 정해야 서버가 시작합니다.

## 현재 구현된 API

`api-contract.json` 기준 라우트 43개가 구현되어 있습니다. 이 중 사진 전송·조회 방식이 구현 중인 미디어 2개는 `doing`이고, 계약 완료는 41/59개(69.5%)입니다.

| 방법 | 주소 | 하는 일 |
|---|---|---|
| `GET` | `/api/health` | API 프로세스와 PostgreSQL 연결 상태 확인 |
| `POST` | `/api/auth/email/signup` | 이메일 가입, 비밀번호 해시와 새 세션 생성 |
| `POST` | `/api/auth/email/login` | 이메일·비밀번호 확인 후 새 기기 세션 생성 |
| `POST` | `/api/auth/refresh` | refresh token을 한 번 사용하고 새 토큰 쌍으로 교체 |
| `POST` | `/api/auth/logout` | Bearer access token에 해당하는 현재 기기 세션 폐기 |
| `GET` | `/api/today` | 서비스 날짜의 후보 3색과 내 선택·발행 여부 조회 |
| `PUT` | `/api/today/choice` | 후보 중 오늘의 색 선택·변경(발행 전까지) |
| `GET` | `/api/mastheads/:name/availability` | 영문 소문자 2~10자 제호의 형식·중복 확인 |
| `POST` | `/api/profile` | 제호를 확정해 내 잡지 프로필 생성 |
| `POST` | `/api/media` | JPEG·PNG·HEIC 파일 업로드 준비 |
| `POST` | `/api/media/:id/complete` | 실제 파일 형식·크기·이미지 정보를 검사해 업로드 완료 |
| `GET` | `/api/me/notifications` | 내 알림 설정 조회(저장 전 기본값은 모두 `true`) |
| `PUT` | `/api/me/notifications` | 내 알림 설정 저장·변경 |
| `GET` | `/api/issues/:id` | 공개 가능한 호 조회(소유자에게만 반응 수 포함) |
| `POST` | `/api/issues/:id/like` | 좋아요 저장(중복 요청도 한 번만 저장) |
| `DELETE` | `/api/issues/:id/like` | 좋아요 취소 |
| `POST` | `/api/issues/:id/scrap` | 스크랩 저장(중복 요청도 한 번만 저장) |
| `DELETE` | `/api/issues/:id/scrap` | 스크랩 취소 |
| `GET` | `/api/issues/:id/lines` | 독자 한 줄 목록을 20개씩 cursor로 조회 |
| `POST` | `/api/issues/:id/lines` | 60자 이내 독자 한 줄 작성 |
| `GET` | `/api/magazines/:masthead` | 공개 가능한 지난 호와 내 구독 상태 조회 |
| `POST` | `/api/magazines/:masthead/subscription` | 잡지 구독 |
| `DELETE` | `/api/magazines/:masthead/subscription` | 잡지 구독 취소 |
| `GET` | `/api/me/magazine` | 오늘 호·지난 호와 소유자 전용 반응 숫자 조회 |
| `GET` | `/api/me/issues/:id/reactions` | 내 호의 좋아요·스크랩·독자 한 줄 수와 최근 목록 조회 |
| `GET` | `/api/me/records?month=YYYY-MM` | 사진 기록과 색 복원을 구분한 월간 기록 조회 |
| `POST` | `/api/me/records/:date/restore` | 이번 달 지난 빈 날의 후보 색 복원(월 2회) |
| `GET` | `/api/users/:masthead` | 제호로 공개 사용자 정보 조회 |
| `GET` | `/api/friends` | 내 친구 목록을 cursor로 조회 |
| `GET` | `/api/friends/requests` | 받은 친구 요청을 cursor로 조회 |
| `POST` | `/api/friends/requests` | 제호로 친구 요청 전송(양방향 중복 방지) |
| `POST` | `/api/friends/requests/:id/accept` | 받은 친구 요청 수락 |
| `POST` | `/api/friends/requests/:id/decline` | 받은 친구 요청 거절 |
| `POST` | `/api/twins` | 친구를 오늘 트윈에 초대 |
| `GET` | `/api/twins/:id` | 참여자에게 트윈 현재 단계 조회 |
| `POST` | `/api/twins/:id/accept` | 트윈 초대 수락 |
| `PUT` | `/api/twins/:id/choice` | 내 트윈 후보 3색 중 하나 선택 |
| `POST` | `/api/twins/:id/posts` | 업로드 완료된 미디어로 내 트윈 표지 게시 |
| `PUT` | `/api/twins/:id/visibility` | 두 표지가 모두 올라온 뒤 내 공개 범위를 private·solo·joint로 선택 |
| `POST` | `/api/twins/:id/consent` | 두 사람 모두 joint를 선택한 뒤 공동 공개에 개별 동의 |
| `POST` | `/api/twins/:id/publish` | 두 사람의 명시적 동의가 모인 트윈 공동 발행 |
| `PATCH` | `/api/me/profile` | 영문 제호와 80자 이내 한 줄 소개 수정 |
| `DELETE` | `/api/me` | 삭제 내용 확인 후 계정과 소유 데이터를 영구 삭제 |

이메일 가입 요청 예시:

```powershell
$body = @{ email = 'me@example.com'; password = '8자 이상 비밀번호' } | ConvertTo-Json
Invoke-RestMethod -Method Post `
  -Uri 'http://127.0.0.1:3000/api/auth/email/signup' `
  -ContentType 'application/json' `
  -Body $body
```

같은 `$body`를 `/api/auth/email/login`으로 보내면 로그인할 수 있습니다. 로그인은 틀린 비밀번호와 가입하지 않은 이메일을 모두 `401 WRONG_CREDENTIALS`로 답합니다. 다만 가입 API의 `409 EMAIL_TAKEN`으로는 이미 가입한 이메일인지 알 수 있고, 아직 이메일 소유 확인 절차도 없으므로 운영 인증을 완성하기 전에 보완해야 합니다.

토큰 갱신은 `{ "refreshToken": "로그인에서 받은 값" }`을 `/api/auth/refresh`로 보냅니다. 성공하면 이전 세션을 폐기하고 새 access/refresh token을 반환합니다. 사용한 refresh token이 다시 들어오면 탈취 가능성으로 보고 그 사용자의 활성 세션을 모두 폐기합니다.

보호 API는 `Authorization: Bearer <access token>` 헤더가 필요합니다. 전역 인증 가드가 기본적으로 모든 API를 닫고, health·가입·로그인·갱신처럼 공개하기로 약속한 API에만 `@Public()`을 붙입니다. 로그아웃은 현재 기기 세션만 폐기하며 이후 같은 access/refresh token을 사용할 수 없습니다.

비밀번호는 Node 내장 `scrypt`로 해시하고, access/refresh token은 SHA-256 해시만 DB에 저장합니다. 이메일은 공백을 지우고 소문자로 통일하며 PostgreSQL의 소문자 unique index가 동시 가입도 막습니다.

받은 access token으로 오늘 후보를 조회하고 색을 고르는 예시:

```powershell
$headers = @{ Authorization = "Bearer $accessToken" }
$today = Invoke-RestMethod -Method Get `
  -Uri 'http://127.0.0.1:3000/api/today' `
  -Headers $headers
$choice = @{ colorId = $today.candidates[0].id } | ConvertTo-Json
Invoke-RestMethod -Method Put `
  -Uri 'http://127.0.0.1:3000/api/today/choice' `
  -Headers $headers -ContentType 'application/json' -Body $choice
Invoke-RestMethod -Method Get `
  -Uri 'http://127.0.0.1:3000/api/mastheads/selin/availability' `
  -Headers $headers
```

후보는 `SERVICE_TIME_ZONE`의 날짜를 기준으로 DB에 하루 한 번 저장됩니다. 현재 배정 알고리즘은 Flutter 데모와 같은 결정적 임시 규칙이며, 희귀 팔레트·확률 정책이 정해지면 `today.rules.ts`를 교체해야 합니다.

프로필 생성은 `{ "masthead": "selin" }`처럼 영문 소문자 2~10자를 받습니다. 한 계정은 프로필을 하나만 만들 수 있고, 제호 unique 제약으로 동시에 같은 이름을 요청해도 한 명만 성공합니다.

미디어는 준비와 완료를 분리합니다. 준비 요청은 `{ "mimeType": "image/png", "sizeBytes": 12345 }`를 받고 `id`, `storageKey`, 허용 형식과 크기만 반환하며 서버 컴퓨터의 실제 경로는 노출하지 않습니다. 개발 환경에서 파일을 저장한 뒤 완료 API를 호출하면 서버가 선언값을 믿지 않고 실제 파일 시그니처와 15MB 제한을 다시 검사하며 PNG·JPEG는 가로·세로도 기록합니다. 완료는 `PENDING` 자산에만 허용됩니다. PostgreSQL에는 파일 바이트가 아니라 저장 키와 메타데이터만 둡니다.

현재 `MEDIA_STORAGE_ROOT`와 Docker named volume `esel-media-data`를 쓰는 **로컬 개발용 저장 방식**입니다. Flutter 기기가 파일을 보낼 업로드 URL은 아직 없으므로 두 미디어 API의 계약 상태는 `doing`입니다. 실제 앱 연결 전에는 자체 호스팅 S3 호환 스토리지 같은 운영 저장소와 업로드 URL 방식을 결정해야 하며, 이를 정하지 않은 상태에서 별도 업로드 API를 임의로 추가하지 않았습니다.

알림 설정은 `enabled`, `newIssue`, `reactions` 세 boolean을 모두 보냅니다. 아직 저장한 적이 없는 계정의 GET은 모두 `true`를 반환하지만 조회만으로 DB 행을 만들지는 않습니다.

호 조회와 반응 API는 P01/P02 공개 판정을 먼저 통과해야 합니다. 지난 날짜와 오늘의 비후보 색은 공개하고 미래 날짜는 숨깁니다. 오늘 후보 3색은 내가 오늘 발행하기 전까지 색별 최신 3개만 미리보기로 열며, 그보다 오래된 호의 ID를 직접 호출해도 `404 NOT_FOUND`로 답합니다. 내가 오늘 발행하면 후보 3색이 모두 열립니다.

공개 `IssuePublicDto`에는 좋아요·스크랩·독자 한 줄 **개수**가 없습니다. 발행한 본인이 조회한 `IssueOwnerDto`에만 `likeCount`, `scrapCount`, `lineCount`가 추가됩니다. `liked`, `scrapped`는 요청한 사용자의 상태라 공개 숫자가 아닙니다. 좋아요·스크랩 생성은 복합 기본키와 upsert로 중복 요청에도 한 행만 남고, 취소도 여러 번 호출할 수 있습니다.

독자 한 줄도 같은 공개 판정을 거칩니다. 본문은 앞뒤 공백을 제거한 뒤 1~60자만 저장하며, 같은 사용자가 같은 호에 1분 안에 여섯 번째로 쓰면 `429 RATE_LIMITED`입니다. 목록은 `{ items, nextCursor }`로 최신순 20개씩 반환하고 전체 개수는 제공하지 않습니다.

서가는 제호로 찾아 공개 가능한 호만 최신 호수순으로 20개씩 반환합니다. 잠긴 오늘 호는 ID·사진·제호를 응답에 넣지 않으며 cursor에도 숨은 호 ID를 넣지 않습니다. `issueCount`는 발행으로만 증가하는 공개 호수이고 구독자 수는 반환하지 않습니다. 구독·취소는 반복 호출해도 각각 같은 성공 상태를 반환합니다.

내 잡지는 오늘 호와 지난 호를 나누어 반환하고, 본인에게만 세 반응 숫자를 포함합니다. 반응 목록 API는 먼저 공개 가능 여부를 확인하므로 보이는 남의 호는 `403 FORBIDDEN`, 잠긴 호나 없는 호는 `404 NOT_FOUND`입니다. 목록은 각 종류의 최근 50개까지만 반환하지만 숫자는 전체 행 기준입니다.

월간 기록은 `month=YYYY-MM`을 필수로 받고 사진이 있는 `ISSUE`와 나만 보는 `RESTORED`를 구분합니다. 복원은 서버 시간대 기준 이번 달의 지난 빈 날짜에만 가능하고 그 날짜 후보 3색 중 하나를 월 2회까지 고를 수 있습니다. `RestoredColor`는 `Issue`·`UserDailyChoice`와 분리되어 있어 발행 호수와 같은 색 방 잠금을 바꾸지 않습니다. 같은 사용자의 월간 한도 경쟁 요청은 serializable transaction으로 처리합니다.

사용자 조회는 제호와 발행 호수만 반환합니다. 내부 사용자 ID, 구독자 수, 반응 수는 공개하지 않습니다.

친구 요청은 두 사용자 ID를 항상 같은 순서로 정규화한 `pairKey`에 unique 제약을 둡니다. 그래서 같은 방향뿐 아니라 서로 엇갈려 동시에 요청해도 한 건만 남습니다. 요청을 수락하면 하나의 `Friendship`으로 바꾸며, 친구 목록의 `friendId`는 다음 트윈 초대에 사용합니다.

트윈은 개인 오늘 색·개인 호·월간 기록과 분리된 `TwinParticipation`, `TwinCandidate`, `TwinPost`에 저장합니다. 한 사용자는 하루에 한 트윈에만 참여하고, 두 사람은 각자 후보 3색을 받되 교집합은 정확히 한 색입니다. 서로 다른 후보를 골라도 되며, 한 사람만 표지를 게시한 동안 상대의 미디어는 응답하지 않습니다. 둘 다 게시해도 개인 발행이나 같은 색 방 잠금 해제로 계산하지 않습니다. 두 표지가 모두 올라온 뒤 각자 `private`·`solo`·`joint`를 고르며, 공동 발행은 두 사람 모두 `joint`를 선택하고 각각 동의한 경우에만 가능합니다. 어느 한쪽이 공개 범위를 다시 고르면 기존 동의는 모두 취소되어 두 사람이 다시 확인해야 합니다.

프로필 수정은 제호와 소개 중 하나 이상을 받고, 제호는 기존과 같은 영문 소문자 2~10자·소개는 80자 제한을 적용합니다. 탈퇴는 `{ "confirmed": true }`가 있어야 실행되며, 한 트랜잭션 안에서 사용자가 참여한 트윈, 발행한 호, 계정과 연관 데이터를 삭제합니다. 현재 정책은 탈퇴자의 트윈 전체를 제거해 상대 기록도 함께 사라지는 방식이며, 팀이 상대 기록 보존 정책을 정하면 익명화 모델을 별도로 설계해야 합니다.

## Flutter 앱과 연결

저장소 루트에서 실제 서버를 먼저 띄웁니다.

```powershell
docker compose up -d --build api
```

Android 에뮬레이터는 호스트 PC를 `10.0.2.2`로 부릅니다. Flutter 앱의 서버 모드에는 인증·사인 확인·프로필 생성·오늘의 색·표지 조회/반응/독자 한 줄·스케치북/구독·내 반응·월간 기록/복원을 연결했다. 실행과 검증 범위는 [Flutter 핵심 API 안내](../docs/flutter/CORE_API_CONNECTION.md)를 따른다. 알림 설정·미디어 업로드·새 발행·피드·팔레트 추천 등은 전체 앱 연결을 완료한 것이 아니다. 현재 미디어 API는 서버 내부 경로를 노출하지 않고 업로드 URL도 제공하지 않으며 호 응답도 파일 URL을 제공하지 않으므로, 운영 저장소 결정 뒤 앱 업로드와 이미지 표시를 연결해야 한다.

```powershell
cd flutter_app
flutter run -d <장치ID> `
  --dart-define=ESEL_API_MODE=server `
  --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
```

USB로 연결한 Android 실기기에서는 `adb reverse tcp:3000 tcp:3000`을 먼저 실행하고 `API_BASE_URL=http://127.0.0.1:3000/api`를 사용합니다. Compose 포트를 외부 네트워크에 열지 않고도 USB 터널로 연결할 수 있습니다.

연결 흐름은 다음과 같습니다.

```text
EmailLoginView
  → AuthController
  → AuthRepositoryImpl
  → AuthRemoteSource
  → StandardHttpClient
  → POST /api/auth/email/signup, /api/auth/email/login, /api/auth/refresh 또는 /api/auth/logout
  → NestJS AuthController → AuthService → PrismaService → PostgreSQL
```

## 검증

```bash
npm run lint
npm test
npm run test:e2e
npm run build
```

`.env`는 커밋하지 않습니다. 개발 기본값은 `.env.example`에서 관리합니다.

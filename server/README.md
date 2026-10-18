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

`api-contract.json` 기준 라우트 61개가 모두 구현되어 있습니다. 계약 완료는 61/61개(100%)이고 진행 중(`doing`)이나 미구현(`todo`) API는 없습니다.

| 방법 | 주소 | 하는 일 |
|---|---|---|
| `GET` | `/api/health` | API 프로세스와 PostgreSQL 연결 상태 확인 |
| `GET` | `/api/today/cover` | 비로그인용 오늘 표지 1장과 안쪽 지면 최대 2쪽 조회 |
| `POST` | `/api/auth/email/signup` | 이메일 가입, 비밀번호 해시와 새 세션 생성 |
| `POST` | `/api/auth/email/login` | 이메일·비밀번호 확인 후 새 기기 세션 생성 |
| `POST` | `/api/auth/refresh` | refresh token을 한 번 사용하고 새 토큰 쌍으로 교체 |
| `POST` | `/api/auth/logout` | Bearer access token에 해당하는 현재 기기 세션 폐기 |
| `GET` | `/api/today` | 서비스 날짜의 후보 3색과 내 선택·발행 여부 조회 |
| `PUT` | `/api/today/choice` | 후보 중 오늘의 색 선택·변경(발행 전까지) |
| `GET` | `/api/mastheads/:name/availability` | 영문 소문자 2~10자 제호의 형식·중복 확인 |
| `POST` | `/api/profile` | 제호를 확정해 내 잡지 프로필 생성 |
| `POST` | `/api/media` | JPEG·PNG·HEIC 파일 업로드 준비 |
| `PUT` | `/api/media/:id/file` | 준비한 사진을 서버 영구 디스크에 스트리밍 업로드 |
| `POST` | `/api/media/:id/complete` | 실제 파일 형식·크기를 검사하고 480px 썸네일을 만들어 업로드 완료 |
| `GET` | `/api/media/:id?size=original\|thumb` | 호·트윈 공개 권한을 확인해 원본 또는 썸네일 전송 |
| `POST` | `/api/issues` | 업로드 완료 사진과 선택 착용 정보로 오늘 호 발행 |
| `GET` | `/api/feed` | 공개 가능한 구독·추천 호를 최신순 cursor 피드로 조회 |
| `GET` | `/api/stand?colorId=…` | 날짜·색별 팔레트 방과 후보색 최신 3장 미리보기 조회 |
| `GET` | `/api/palette/recommended` | 아직 구독하지 않은 사람별 최신 공개 사진 한 장 조회 |
| `GET` | `/api/palette/colors` | 발행 전 후보 3색을 먼저 두고 잠금 상태를 포함한 색 목록 조회 |
| `GET` | `/api/palette/subscriptions` | 구독한 사람별 최신 공개 사진 한 장 조회 |
| `GET` | `/api/me/garments` | 내가 등록한 옷을 최신순 cursor 목록으로 조회 |
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
| `POST` | `/api/share-links` | 볼 수 있는 표지 또는 공동 공개된 트윈의 공유 토큰 생성 |
| `GET` | `/api/share-links/:token` | 로그인 여부에 맞춰 공개 권한을 다시 검사하고 공유 내용 조회 |
| `POST` | `/api/issues/:id/reports` | 볼 수 있는 표지 신고 접수 |
| `POST` | `/api/issues/:id/lines/:lineId/reports` | 볼 수 있는 독자 한 줄 신고 접수 |
| `POST` | `/api/users/:masthead/block` | 사용자를 차단하고 콘텐츠 노출 중지 |
| `DELETE` | `/api/users/:masthead/block` | 사용자 차단 해제 |
| `GET` | `/api/me/blocks` | 내가 차단한 사용자 cursor 목록 조회 |
| `DELETE` | `/api/issues/:id` | 내 호를 소프트 삭제하고 사진 파일 제거 |
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

미디어는 준비·파일 전송·완료를 분리합니다. 준비 요청은 `{ "mimeType": "image/png", "sizeBytes": 12345 }`를 받고 `id`, `uploadUrl`, 허용 형식과 크기만 반환하며 서버 컴퓨터의 실제 경로와 `storageKey`는 노출하지 않습니다. 앱은 Bearer 토큰과 준비 때 선언한 `Content-Type`으로 `uploadUrl`에 원본 바이트를 `PUT`하고, 이후 완료 API를 호출합니다. 업로드와 완료는 소유자의 `PENDING` 자산에만 허용되며 서버는 스트리밍 중에도 15MB 제한을 적용합니다. 완료 단계에서는 선언값을 믿지 않고 실제 파일 시그니처와 크기를 다시 검사하고 PNG·JPEG의 가로·세로를 기록합니다. PostgreSQL에는 파일 바이트가 아니라 저장 키와 메타데이터만 둡니다.

파일은 `MEDIA_STORAGE_ROOT`에 저장하고 Docker에서는 재시작 뒤에도 남는 named volume `esel-media-data`를 `/app/data/media`에 연결합니다. JPEG·PNG 완료 시 `sharp`로 최대 480×480 JPEG 썸네일을 미리 만들며, `GET /api/media/:id?size=thumb`으로 요청합니다. 조회할 때도 매번 호의 같은 색 잠금·차단·삭제와 트윈 공개 범위를 검사하고 권한이 없거나 미완료 상태이면 `404`로 숨깁니다. 현재 응답은 사용자별 권한이 달라질 수 있어 `Cache-Control: private, no-store`입니다. 호를 삭제하면 미디어 상태를 `DELETED`로 바꾸고 원본·썸네일 파일을 제거합니다.

HEIC 원본은 현재 허용하고 실제 시그니처도 검사하지만 JPEG 썸네일 생성은 보장하지 않습니다. iPhone 앱에서 JPEG로 바꿔 올릴지 서버에 HEIC 변환기를 둘지는 관혁이와 정한 뒤 계약을 갱신합니다. 외부 S3·R2는 쓰지 않으므로 배포 환경에는 컨테이너 재배포 뒤에도 보존되는 영구 디스크가 반드시 필요합니다.

오늘 호 발행은 `POST /api/issues` 한 트랜잭션 안에서 오늘의 선택 색 확인, READY 상태인 내 사진 연결, 호 생성, `issueCount` 증가, 선택 색 잠금을 함께 처리합니다. 같은 사용자의 같은 서비스 날짜에는 DB unique 제약이 있어 동시 요청도 한 호만 성공합니다. `garments`는 없어도 되고 최대 8개이며, 새 옷은 `garments`, 호에서의 순서·태그 좌표·오늘의 색 표시는 `issue_garments`에 나눠 저장합니다. URL·가격처럼 DTO에 없는 필드는 전역 whitelist가 `400 VALIDATION`으로 거절합니다.

`GET /api/me/garments`는 내 옷만 20개씩 최신순으로 돌려주므로 다음 코디에서 `garmentId`로 다시 고를 수 있습니다. 응답에도 가격·쇼핑 링크는 없으며, 계정을 삭제하면 옷과 호 연결 정보도 외래 키 cascade로 함께 지워집니다.

홈 피드는 미래 호와 발행 전 사용자의 오늘 후보 3색 호를 먼저 제외한 뒤 최신순 cursor 페이지를 만듭니다. 구독한 사람의 호에는 `SUBSCRIPTION`, 그 밖에는 `RECOMMENDED` 출처만 표시하고 반응 숫자·순위는 공개하지 않습니다. 인기 혼합에 사용할 내부 신호가 아직 정해지지 않아 현재는 이미 본 페이지가 다시 정렬되지 않는 최신순만 사용합니다.

팔레트 색상 방은 오늘 후보색이면서 내가 아직 발행하지 않았을 때 최신 3장과 `hiddenCount`만 보내고, 발행 후·비후보색·지난 날짜는 전체 cursor 목록을 엽니다. 미래 날짜는 `closed`와 빈 목록으로 답합니다. 추천 탭은 같은 색을 골랐다면 그 색을 우선 조건으로 삼고, 자신과 이미 구독한 사람을 제외한 뒤 사람별 최신 공개 사진 한 장만 반환합니다. 구독 탭도 P01 공개 판정을 먼저 적용한 뒤 구독한 사람마다 최신 사진 한 장만 반환합니다. 색상 목록의 선택 인원 수는 정렬에만 쓰며 응답에는 넣지 않습니다. 미성년자 판별 방법은 아직 결정되지 않아 일반 잠금 예외는 구현하지 않았습니다.

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

공유 링크 생성은 표지의 현재 P01 공개 권한 또는 트윈의 공동 발행 상태를 먼저 확인합니다. 응답에는 내부 사용자·표지·트윈 ID를 넣지 않고 임의 토큰과 앱이 열 경로만 보냅니다. DB에는 원문 토큰 대신 SHA-256 해시만 저장합니다. 링크를 열 때도 권한을 다시 계산합니다. 로그인 사용자는 자신의 P01·차단 상태를 적용하고, 비로그인은 같은 색 잠금 우회를 막기 위해 지난 날짜의 표지와 공동 발행 트윈만 볼 수 있습니다. 삭제된 호의 기존 링크는 `404`가 됩니다.

표지·독자 한 줄 신고는 먼저 해당 사용자가 대상을 볼 수 있는지 검사하고 접수 기록만 저장합니다. 한 사용자의 신고 두 종류를 합쳐 1분에 5회까지 허용하며 여섯 번째부터 `429 RATE_LIMITED`로 답합니다. 운영자가 누가 어떤 기준으로 처리할지와 한 줄 삭제 정책은 아직 정하지 않았으므로 자동 숨김·삭제는 하지 않습니다.

차단은 제호 검색 결과 자체를 숨기지는 않지만, 차단한 사용자의 표지와 독자 한 줄을 내 홈 피드·팔레트·스케치북·직접 조회·미디어 조회에서 숨깁니다. 차단 목록은 전체 개수 없이 20명씩 cursor로 반환합니다.

호 삭제는 행을 지우지 않고 `deletedAt`을 기록하는 소프트 삭제입니다. 하루 한 호 unique 행과 개인 호수는 그대로 남기므로 삭제한 날에는 다시 올릴 수 없고 결호 규칙도 유지됩니다. 공개 조회·공유 링크·미디어는 즉시 `404`가 되며 팔레트 미리보기와 `hiddenCount`는 삭제되지 않은 호만 기준으로 다시 계산합니다.

프로필 수정은 제호와 소개 중 하나 이상을 받고, 제호는 기존과 같은 영문 소문자 2~10자·소개는 80자 제한을 적용합니다. 탈퇴는 `{ "confirmed": true }`가 있어야 실행되며, 한 트랜잭션 안에서 사용자가 참여한 트윈, 발행한 호, 계정과 연관 데이터를 삭제합니다. 현재 정책은 탈퇴자의 트윈 전체를 제거해 상대 기록도 함께 사라지는 방식이며, 팀이 상대 기록 보존 정책을 정하면 익명화 모델을 별도로 설계해야 합니다.

## Flutter 앱과 연결

저장소 루트에서 실제 서버를 먼저 띄웁니다.

```powershell
docker compose up -d --build api
```

Android 에뮬레이터는 호스트 PC를 `10.0.2.2`로 부릅니다. Flutter 앱의 서버 모드에는 인증·사인 확인·프로필 생성·오늘의 색·표지 조회/반응/독자 한 줄·스케치북/구독·내 반응·월간 기록/복원을 연결했다. 실행과 검증 범위는 [Flutter 핵심 API 안내](../docs/flutter/CORE_API_CONNECTION.md)를 따른다. 알림 설정·미디어 업로드·새 발행·피드·팔레트 추천 등은 전체 앱 연결을 완료한 것이 아니다. 서버의 미디어 업로드·조회 API는 준비됐지만 Flutter가 아직 `uploadUrl`로 파일을 보내고 호·트윈의 미디어 ID를 이미지 URL로 조합하는 연결 작업은 남아 있다.

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

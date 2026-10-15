# Esel 서버 배움 안내

서버를 처음 만드는 사람을 위한 안내다. 개념을 Esel의 실제 기능으로 설명하고, [6장](#6-배움-순서)의 미션을 순서대로 하면 서버가 완성되도록 짰다. AI를 쓸 때는 미션마다 적힌 지시문을 그대로 주면 된다. 규칙의 정본은 [API 규칙](API_RULES.md)과 [약속 목록](../api-contract.json)이다.

## 1. 서버가 하는 일

Esel은 세 부분으로 움직인다.

| 부분 | 하는 일 | Esel의 예 |
|---|---|---|
| 앱(Expo) | 화면을 그리고 사람의 손짓을 받는다 | 표지를 보여 주고, 발행 버튼을 누른다 |
| 서버(NestJS) | 요청을 받아 **규칙을 확인**하고 데이터를 읽고 쓴다 | "오늘 이미 발행했나?"를 확인하고, 아니면 호수를 1 올려 저장한다 |
| DB(PostgreSQL) | 데이터를 표(테이블)로 오래 보관한다 | `issues` 표에 누가, 몇 호를, 무슨 색으로 냈는지 |

앱만으로는 안 되는 이유: 앱은 사용자의 휴대폰에서 돈다. 누군가 앱을 고쳐서 "잠긴 표지를 보여 줘"라고 요청할 수 있다. 그래서 **누가 무엇을 볼 수 있는지는 서버가 정한다.** 같은 색 잠금(P01), 하루 한 호(P04), 숫자는 본인에게만(P18)이 모두 서버의 일이다.

## 2. API: 앱과 서버의 약속

API는 "이 주소로, 이 방법으로, 이것을 보내면, 이것을 돌려준다"는 약속이다. 예:

```http
POST /api/issues/3f2a…/like
Authorization: Bearer eyJhbGci…

→ 201 { "liked": true }
```

- **주소(path)**: 무엇에 대한 요청인지. `/api/issues/:id/like` = 그 호의 좋아요.
- **방법(method)**: GET 읽기, POST 만들기·실행, PUT 정하기, PATCH 일부 바꾸기, DELETE 지우기.
- **상태 코드**: 200·201·204 성공(GET 200, 만들기 POST 201, 돌려줄 것이 없으면 204), 400 형식 틀림, 401 로그인 필요, 403 보이지만 남의 것, 404 없음(또는 나에게 보이지 않음), 409 상태 충돌, 422 규칙상 안 됨.
- **DTO**: 주고받는 데이터의 모양을 정한 틀(클래스). `ReactionStateDto = { liked: boolean }`.

API를 설계하는 일(무슨 주소에 무엇을 주고받을지)은 앱과 서버가 함께 정하고, 그것을 실제로 지키는 코드를 서버가 만든다. Esel의 약속은 [api-contract.json](../api-contract.json)에 모두 적혀 있다. **여기 없는 API는 만들지 않는다.** 주소·권한·오류 코드는 이 파일이, 주고받는 데이터의 자세한 모양은 Swagger(코드의 DTO)가 정본이다.

## 3. 요청이 지나가는 길

```mermaid
flowchart LR
    A[앱] -->|HTTP 요청| M[main.ts → configureApp<br>/api 접두어·보안 헤더]
    M --> V[ValidationPipe<br>DTO 형식 검사]
    V --> G[인증 가드<br>토큰 확인]
    G --> C[Controller<br>요청 받기]
    C --> S[Service<br>규칙·권한 확인]
    S --> P[PrismaService]
    P --> D[(PostgreSQL)]
    S -->|응답 DTO| A
```

| 단계 | 파일 | 하는 일 | 하지 않는 일 |
|---|---|---|---|
| Controller | `src/issues/issues.controller.ts` | 주소와 DTO를 연결하고 서비스를 부른다 | DB를 직접 읽지 않는다 |
| Service | `src/issues/issues.service.ts` | "이미 발행했나?", "주인인가?"를 확인하고 DB를 읽고 쓴다 | HTTP를 몰라도 된다 |
| Rules | `src/issues/issues.rules.ts` | P01·P04 같은 규칙을 작은 함수로 | DB·HTTP를 모른다. 그래서 테스트가 쉽다 |
| DTO | `src/issues/dto/*.dto.ts` | 받을 값의 검사 규칙과 돌려줄 모양 | |

## 4. DB, Prisma, migration

- **테이블**: 엑셀 시트처럼 행과 열로 된 표. `profiles` 표의 한 행 = 한 사람의 잡지.
- **Prisma**: TypeScript로 DB를 다루게 해 주는 도구. 표의 모양은 `prisma/schema.prisma`에 적는다.
- **migration**: DB 모양이 바뀐 **기록**. "issues 표에 mastheadColor 열을 추가" 같은 변경이 SQL 파일로 쌓인다. 다른 사람 DB도 이 기록을 순서대로 적용해 같은 모양이 된다. 그래서 **이미 공유한 migration은 고치지 않고, 새 migration을 만든다.** 검사가 고친 것을 잡아낸다.
- **unique 제약**: "같은 값이 두 번 들어갈 수 없다"를 DB가 지키게 하는 것. `issues(author_id, service_date)`가 unique라서, 버튼을 두 번 빨리 눌러도 하루에 호가 두 개 생기지 않는다(P04).
- **트랜잭션**: 여러 작업을 "모두 되거나 모두 안 되거나"로 묶는 것. 발행은 ① 호 저장 ② 내 호수 +1이 함께여야 한다. 중간에 실패하면 둘 다 취소되어야 호수만 오르는 일이 없다.
- **seed**: 처음부터 있어야 하는 기본 데이터(12색). 이것도 코드로 넣는다. Esel은 12색을 migration(`20261015130000_add_checks_and_colors`)에 넣었다. 앱이 돌려면 꼭 있어야 해서, `prisma migrate deploy`만 돌려도 모든 DB에 같은 값이 들어가게 하려는 것이다.
- **CHECK 제약**: "이 열의 값은 이 조건을 지켜야 한다"를 DB가 지키게 하는 것. 제호는 `^[a-z]{2,10}$`, 개인 호수는 1 이상. 서버 코드에 버그가 있어도 잘못된 값이 저장되지 않는다.

## 5. 테스트와 검사

| 종류 | 확인하는 것 | 명령 | 필요한 것 |
|---|---|---|---|
| 하네스 검사 | 약속·규칙을 어겼는지, 루트 하네스와 맞는지 | `npm run check:server` | 아무것도(설치 없이 됨) |
| 검사의 자체 테스트 | 검사가 맞게 잡는지 | `npm run test:harness` | 아무것도 |
| 단위 테스트 | 규칙 함수 하나 | `npm test` | `npm install` |
| API 테스트(e2e) | 실제 HTTP 요청과 DB | `npm run test:e2e` | `docker compose up -d postgres` |
| 빌드·린트 | 코드가 컴파일되고 깔끔한지 | `npm run build`, `npm run lint` | `npm install` |

`test/contracts/`에는 합격 기준이 `it.todo('…')`로 적혀 있다. todo는 실패가 아니라 "남은 일"로 표시된다. API 하나를 만들 때 그 todo를 실제 테스트로 바꾼다. todo 파일은 손으로 관리하고, `check:server`가 API마다 todo나 테스트가 있는지 확인한다. `done`은 todo 문구가 아니라 `it(…)` 안에서 `request(app.getHttpServer())`로 그 주소를 실제로 부르는 테스트가 있어야 인정된다. `check:server`는 언제나 실패 0건이어야 하고, 실패하면 "왜 문제인가"와 "고치는 법"을 같이 보여 준다.

## 6. 배움 순서

미션은 순서대로 한다. 앞 미션이 끝나야 다음 미션의 바탕이 생긴다. 미션마다 AI에게 줄 지시문이 있다. AI가 끝나면 [학습용 보고](../AGENTS.md#학습용-보고)를 받고, 보고의 "새로 나온 개념"을 스스로 한 번 더 설명해 본다.

### 미션 0. 서버 기반에서 고친 것 읽고 답하기 (코드 없음)

- **목표**: 서버 기반(PR #4)을 리뷰하면서 고친 일곱 가지를 읽고, AI 없이 아래 질문에 답한다. 처음 만든 서버에 흔히 남는 문제들이라, 왜 문제였는지 알면 다음에는 스스로 피할 수 있다.
- **배울 것**: 개발 환경과 운영 환경의 차이(`NODE_ENV`), 의존성과 lockfile, 테스트가 실제 서버와 같은 설정을 써야 하는 이유, DB가 직접 지키는 규칙.
- **끝난 기준**: 질문 5개에 자기 말로 답하고, 확인 명령을 직접 돌려 결과를 본다.

| 무엇이 | 왜 문제였나 | 어떻게 고쳤나 | 어디서 보나 |
|---|---|---|---|
| 운영에서도 열린 Swagger(`/api/docs`) | Swagger는 모든 API 주소와 요청·응답 모양을 보여 주는 문서다. 운영 서버에서 열려 있으면 누구나 우리 API 구조를 본다(검토에서 `NODE_ENV=production`으로 200을 확인했다) | `NODE_ENV`가 `production`이 아닐 때만 켠다 | `src/app.setup.ts`, `test/app-setup.e2e-spec.ts` |
| `@nestjs/mau`와 `"deploy": "nest deploy"` | `nest new`가 만든 템플릿에 딸려 온 NestJS 유료 클라우드 배포 도구다. 실행하면 팀 승인 없이 외부 서비스로 배포를 시도한다. 팀은 서버를 직접 운영하기로 했다(BaaS·유료 배포 금지) | 패키지와 명령을 지우고 lockfile을 다시 만들었다. 다시 들어오면 `check:server`가 막는다 | `package.json` |
| vitest의 `tsconfigPaths` | tsconfig의 `paths`(별칭 import)를 쓰게 하는 옵션인데, 서버는 별칭을 쓰지 않는다. 이 옵션이 저장소 루트의 앱 tsconfig까지 읽어서, 루트 앱을 설치하지 않으면 `npm test`가 "Tsconfig not found"로 실패했다 | 옵션과 `vite-tsconfig-paths`를 지웠다. 이제 `server/`만으로 설치·테스트·빌드된다 | `vitest.config.ts` |
| 손으로 돌려야 하던 `prisma generate` | DB 클라이언트 코드(`src/generated`)는 커밋하지 않고 만들어 쓴다. 잊으면 빌드·테스트가 실패했다 | `postinstall`·`prebuild`에서 자동으로 돌린다 | `package.json` |
| main과 e2e가 다른 설정 | e2e가 `/api` 접두어만 따라 해서, 형식 검사(ValidationPipe)와 보안 헤더(Helmet)가 테스트에서 빠져 있었다 | 설정을 `configureApp(app)` 하나로 모아 둘 다 부른다. 종료 신호에 DB 연결을 닫는 `enableShutdownHooks()`도 넣었다 | `src/app.setup.ts`, `test/create-app.ts` |
| Docker·Compose | 컨테이너가 root로 돌고, npm이 PID 1이라 종료 신호가 서버에 바로 가지 않았다. 개발용 비밀번호가 고정된 DB 포트가 같은 와이파이의 다른 기기에도 열려 있었다 | `USER node`, `CMD ["node", "dist/main.js"]`, 포트는 `127.0.0.1`에만 | `Dockerfile`, 루트 `compose.yaml` |
| 느슨한 환경변수와 DB | 운영에서도 CORS가 localhost 기본값으로 열렸고, 시간대 이름 오타를 알 수 없었다. 제호 `Selin`과 `selin`이 함께 들어갈 수 있었다 | 운영에서는 `CORS_ORIGINS` 필수, 시간대 검사, `serviceDate()` 도우미, 새 migration의 CHECK 제약과 12색 | `src/config/environment.ts`, `src/common/service-date.ts`, `prisma/migrations/20261015130000_add_checks_and_colors` |

새로 나온 말:

- **운영 환경(production)**: 실제 사용자가 쓰는 서버. 개발 환경과 달리 비밀값·문서·디버그 기능을 열어 두지 않는다.
- **lockfile**(`package-lock.json`): 설치한 패키지의 정확한 버전 목록. 모두가 같은 버전을 쓰게 한다.
- **PID 1**: 컨테이너 안에서 가장 먼저 뜬 프로세스. `docker stop`의 종료 신호(SIGTERM)를 이 프로세스가 받는다.
- **CORS**: 브라우저가 "이 주소의 웹 앱이 우리 서버를 불러도 되는가"를 확인하는 규칙. 허용 목록에 있는 주소만 연다.

AI 없이 답해 보기:

1. 운영 서버에서 `/api/docs`가 열려 있으면 누가 무엇을 알 수 있나? 그런데 개발에서는 왜 열어 두나?
2. `npm run deploy`가 남아 있었다면 누군가 실수로 실행했을 때 무슨 일이 생기나? 팀의 어떤 결정과 부딪히나?
3. 루트 앱을 설치하지 않은 PC에서 예전 서버의 `npm test`는 왜 실패했나? `server/`가 혼자 돌아야 하는 이유는?
4. main.ts에만 `ValidationPipe`를 걸고 e2e에는 안 걸었다면, 테스트가 어떤 버그를 놓칠 수 있나?
5. 제호 형식을 서버 코드(DTO)에서 검사하는데 왜 DB CHECK 제약까지 두나? 하나만 있으면 어떤 일이 생길 수 있나?

직접 확인하기:

```bash
cd server
npm run check:server              # 실패 0건이어야 한다
npm test                          # 서비스 날짜·환경변수 단위 테스트가 보인다
npm run test:e2e                  # DB가 필요하다(미션 1). 운영에서 /api/docs가 404인 테스트, DB 제약 테스트를 찾아 읽는다
grep -n "production" src/app.setup.ts src/config/environment.ts
```

```text
server/AGENTS.md와 docs/LEARN.md 미션 0을 읽어. 내가 질문 1~5에 답한 것을 보여 줄 테니, 정답을 바로 말하지 말고
틀리거나 빠진 부분만 힌트로 알려 줘. 코드는 바꾸지 마.
```

### 미션 1. 서버를 직접 띄워 보기 (코드 없음)

- **목표**: 저장소 루트에서 `docker compose up -d --build api`로 띄우고 `http://localhost:3000/api/health`를 연다. Compose의 api는 운영 모드(`NODE_ENV=production`)라 `/api/docs`는 404가 정상이다. Swagger는 `server/`에서 `npm run start:dev`로 띄워 `http://localhost:3000/api/docs`에서 본다.
- **배울 것**: 컨테이너, 포트(`127.0.0.1`에만 열린 이유), 헬스체크, 개발 모드와 운영 모드의 차이, Swagger 읽는 법.
- **끝난 기준**: health가 `database: up`을 돌려준다. 운영 모드에서 `/api/docs`가 404인 것을 확인한다. `docker compose down`으로 끈다.

### 미션 2. 공통 틀 만들기

- **목표**: `src/common/`에 `AppException`, 전역 예외 필터(오류 모양 통일), `errors.ts`(api-contract.json의 errors와 같게), `@Public()` 데코레이터, 목록 응답 타입 `Page<T>`를 만든다. 전역 필터는 `src/app.setup.ts`의 `configureApp`에 건다(그래야 e2e도 같은 필터를 쓴다).
- **배울 것**: 예외 필터, 데코레이터, 왜 오류 모양을 하나로 맞추는지.
- **끝난 기준**: 없는 주소를 부르면 `{ "error": { "code": "NOT_FOUND", … } }`가 오는 e2e 테스트가 통과한다.

```text
server/AGENTS.md와 docs/API_RULES.md 7장·8장을 따라 src/common의 공통 틀을 만들어 줘.
오류 코드와 메시지는 api-contract.json의 errors와 똑같이 맞추고, 전역 필터는 src/app.setup.ts의 configureApp에 걸어.
없는 주소의 404 응답 모양을 test/create-app.ts의 createTestApp()으로 띄운 e2e 테스트로 확인해.
새 패키지는 추가하지 마. 끝나면 모든 검사를 돌리고 학습용 보고 형식으로 설명해 줘.
```

### 미션 3. 오늘의 후보 색

- **목표**: 날짜별 후보 3색을 만드는 규칙 함수와 단위 테스트. 12색은 이미 migration에 있고(`check:server`가 루트 `harness.json`의 `colors`와 같은지 본다), 서비스 날짜는 `src/common/service-date.ts`의 `serviceDate()`가 있다. 둘 다 먼저 읽고 이해한다.
- **배울 것**: 기준 데이터를 migration에 넣는 이유, 시간대, 순수 함수와 단위 테스트.
- **끝난 기준**: "후보는 항상 서로 다른 3색", "같은 날짜면 같은 후보" 단위 테스트 통과. `serviceDate` 테스트를 읽고 "한국 시간 0시 1분은 새 날짜"인 이유를 설명할 수 있다.

```text
server/AGENTS.md를 따라 미션 3을 해 줘. 12색은 colors 테이블(sort_order 순서)에 이미 있고, 서비스 날짜는
src/common/service-date.ts의 serviceDate()를 써. 후보 3색은 src/today/today.rules.ts의 순수 함수로 만들어 단위 테스트를 붙여.
API는 아직 만들지 마. 후보를 고르는 방식은 아직 팀이 정하지 않았으니, 날짜로 결정되는 간단한 방식으로 하고 보고에 "임시"라고 적어 줘.
```

### 미션 4. 이메일 가입·로그인 (DEV-05)

- **목표**: `auth.signup`, `auth.login`, `auth.refresh`, `auth.logout`과 전역 인증 가드.
- **배울 것**: 비밀번호를 그대로 저장하지 않는 이유와 해시(Node 내장 `crypto.scrypt`), access token과 refresh token, 401과 403의 차이.
- **끝난 기준**: `test/contracts/auth.e2e-spec.ts`의 todo가 실제 테스트로 바뀌어 통과. 비밀번호·refresh token 원문이 DB에 없다.
- **주의**: 토큰 서명용 패키지(예: `@nestjs/jwt`)를 추가해야 하면, 추가하기 전에 리뷰어에게 먼저 묻는다.

```text
server/AGENTS.md를 따라 api-contract.json의 auth.* 네 개를 만들어 줘. 비밀번호는 node:crypto의 scrypt로 해시하고,
refresh token은 해시만 저장하고 쓸 때마다 새로 바꿔(회전). 전역 인증 가드를 걸고 public API에만 @Public()을 달아.
새 패키지가 꼭 필요하면 설치하기 전에 이유와 함께 먼저 물어봐. test/contracts/auth.e2e-spec.ts의 todo를 실제 테스트로 바꾸고,
끝나면 모든 검사를 돌린 뒤 학습용 보고 형식으로 설명해 줘.
```

### 미션 5. 오늘의 색 고르기 (DEV-07)

- **목표**: `today.get`, `today.choose`. 후보 밖 색은 422, 발행한 뒤 바꾸면 409.
- **배울 것**: 422와 409의 차이, 서버가 "오늘"을 정하는 이유.

```text
server/AGENTS.md를 따라 api-contract.json의 today.get과 today.choose를 만들어 줘. 미션 3의 규칙 함수를 쓰고,
test/contracts/today.e2e-spec.ts의 해당 todo를 실제 테스트로 바꿔. 끝나면 모든 검사를 돌리고 학습용 보고로 설명해 줘.
```

### 미션 6. 제호 정하기 (DEV-06)

- **목표**: `mastheads.availability`, `profile.create`. 형식이 틀리면 422, 이미 있으면 409.
- **배울 것**: unique 제약과 동시 요청, DB CHECK 제약. 제호 CHECK(`^[a-z]{2,10}$`)는 이미 migration에 있다. 서버(DTO 검사와 서비스)가 422로 먼저 막고, DB가 한 번 더 막는다(`test/db-constraints.e2e-spec.ts`).

### 미션 7. 사진 올리기 (DEV-08)

- **목표**: `media.prepare`, `media.complete`. 15MB 초과 413, 사진 아님 415.
- **배울 것**: 사진 파일은 DB가 아니라 저장소에 두고 DB에는 위치만 적는 이유. 저장소 서비스는 팀이 정하지 않았으니, 개발용으로는 로컬 폴더를 쓰고 보고에 "임시"라고 적는다.

### 미션 8. 오늘 호 발행 (DEV-09)

- **목표**: `issues.publish`. 트랜잭션으로 호 저장 + 호수 +1, 같은 날 두 번째는 409.
- **배울 것**: 트랜잭션, 동시에 두 요청이 올 때의 테스트(`Promise.all`로 두 번 보내 하나만 성공).

### 미션 9. 같은 색 잠금 (DEV-12)

- **목표**: `stand.get`. 오늘 발행 전에는 오늘 **후보 3색 방이 모두** 최신 3장과 `hiddenCount`만 준다(2026-10-15 결정). 고른 색을 바꿔도 열리지 않고, 후보가 아닌 색·지난 날짜 방은 열려 있고, 오늘 발행하거나 자정이 지나면 열린다. 숨긴 표지의 ID·이름·사진 주소는 응답에 없다. 할 일은 `test/contracts/stand.e2e-spec.ts`에 있다.
- **배울 것**: 권한에 따라 응답을 다르게 만드는 법, 숨긴 것을 404로 답하는 이유(있다는 사실도 새지 않게).
- **참고 구현**: 저장소의 `.codex/temp/prototype/20260906-minimal-gallery/src/social-state.js`의 `sameColorRoom`과 그 테스트. 이 구현은 고른 색 하나만 잠그는 예전 규칙이라, 색을 바꾸면 방이 열리는 구멍이 있다. 잠그는 대상을 "오늘 후보 3색 모두"로 바꿔 옮긴다.

### 그다음

피드(DEV-10) → 펼침면·반응(DEV-11) → 서가·구독(DEV-13) → 내 잡지(DEV-14) → 색 기록(DEV-15) → 친구(DEV-16) → 트윈(DEV-17) → 공유(DEV-18) → 계정(DEV-19) → 신고·차단·삭제(DEV-20) 순서로, 미션과 같은 방식(약속 확인 → todo를 테스트로 → 구현 → 검사 → 보고)으로 진행한다. 지시문은 미션 5의 것에서 API 이름과 테스트 파일만 바꿔 쓰면 된다. `api-contract.json`에서 `note`가 달린 API(비로그인 표지, 공유 링크 열기, 신고·삭제 등)는 아직 사용자가 정하지 않은 것이 있으니, 구현하기 전에 먼저 물어본다.

## 7. 자주 하는 실수

| 실수 | 왜 문제인가 | 이렇게 |
|---|---|---|
| 컨트롤러에서 `prisma.…`를 바로 부름 | 규칙 확인이 흩어져 빠뜨리기 쉽다 | 서비스에서만 DB를 쓴다 |
| 공개 응답에 `likeCount`를 넣음 | 모든 사람에게 인기 숫자가 보인다(P18) | `…OwnerDto`에만 |
| 잠긴 표지를 403으로 답함 | "그 표지가 있다"는 사실이 샌다 | 404로 답한다 |
| 공유된 migration 파일 수정 | 다른 사람 DB와 어긋난다 | 새 migration을 만든다 |
| 앱이 보낸 "오늘 날짜"를 믿음 | 휴대폰 시간을 바꾸면 규칙을 피할 수 있다 | 서버가 날짜를 정한다 |
| 테스트 없이 status를 done으로 | 완료가 증명되지 않는다 | todo를 `it(…)` 안에서 `request(...)`로 부르는 테스트로 바꾼 뒤 done |
| e2e에서 앱을 직접 만들고 configureApp을 빼먹음 | 실제 서버와 다른 설정(검사·보안 헤더 없음)을 테스트하게 된다 | `test/create-app.ts`의 `createTestApp()`을 쓴다 |
| 운영에서도 Swagger·디버그 기능을 켬 | 누구나 API 구조와 내부 정보를 본다 | `NODE_ENV`가 `production`이면 끈다 |
| 약속에 없는 API를 먼저 만듦 | 앱이 모르는 API, 리뷰 없는 기능이 생긴다 | api-contract.json부터 고치고 리뷰 |

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

| 방법 | 주소 | 하는 일 |
|---|---|---|
| `GET` | `/api/health` | API 프로세스와 PostgreSQL 연결 상태 확인 |
| `POST` | `/api/auth/email/signup` | 이메일 가입, 비밀번호 해시와 새 세션 생성 |

이메일 가입 요청 예시:

```powershell
$body = @{ email = 'me@example.com'; password = '8자 이상 비밀번호' } | ConvertTo-Json
Invoke-RestMethod -Method Post `
  -Uri 'http://127.0.0.1:3000/api/auth/email/signup' `
  -ContentType 'application/json' `
  -Body $body
```

비밀번호는 Node 내장 `scrypt`로 해시하고, access/refresh token은 SHA-256 해시만 DB에 저장합니다. 이메일은 공백을 지우고 소문자로 통일하며 PostgreSQL의 소문자 unique index가 동시 가입도 막습니다. 로그인·토큰 갱신·로그아웃은 아직 구현 전이므로 가입 뒤 앱을 재시작한 세션 복원은 다음 작업에서 완성합니다.

## Flutter 앱과 연결

저장소 루트에서 실제 서버를 먼저 띄웁니다.

```powershell
docker compose up -d --build api
```

Android 에뮬레이터는 호스트 PC를 `10.0.2.2`로 부릅니다. Flutter 앱을 mock이 아닌 서버 모드로 실행하면 이메일 회원가입 화면이 위 API를 호출합니다.

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
  → POST /api/auth/email/signup
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

# 서버 구현 진행 기록 (2026-11-12)

> 작업 기록이다. 결정이 아니다. 여기 적힌 권고는 [하네스 §2 결정 이력](../ESEL_HARNESS.md)에 반영되지 않았고, 팀이 정하기 전까지 작업 기준이 아니다. 서버 담당 팀원이 학교 PC(Windows 11)에서 Claude Code와 함께 진행했고, PM이 보낸 서버 수정 목록 중 2번까지의 상황을 남긴다.

## 0. 먼저 읽을 요약

**방향:** 정해지지 않은 정책(색 배정 확률, 미성년자 판별 등)은 미뤄 두고, **서버를 실제로 돌려 연결하는 것**을 1번 목표로 잡았다. 교수님 방침대로 Supabase 같은 BaaS(서버 기능을 대신 제공하는 외부 서비스) 없이, NestJS + PostgreSQL + Prisma로 직접 만든 구조를 그대로 이어 간다. 이 저장소의 서버는 처음부터 그렇게 만들어져 있어서 새로 갈아엎을 필요는 없었다.

| 단계 | 내용 | 상태 |
|---|---|---|
| 0 | 이 PC에서 서버 실행·DB 연결 | **완료** |
| 1 | 로그인 시도 제한이 실제로 막지 못하는 보안 버그 | **완료** · PR [#35](https://github.com/konga22/Esel/pull/35) |
| 2 | 쓰이지 않은 업로드 사진이 쌓이는 문제 | **완료** · PR [#35](https://github.com/konga22/Esel/pull/35) |
| 3 | 문서 정리(API 개수, Flutter 연결 상태) | 시작 전 |
| 4 | 실기기 배포 준비 점검 | 지시가 있을 때만 |

PR #35는 리뷰 대기 중이다(병합 전). GitHub CI 5개(서버 검사와 API 테스트, Docker 구성 실행, Flutter 앱, 하네스·규칙 Ubuntu·Windows)가 모두 통과했다.

## 1. 서버 구조 한눈에 보기

```text
Flutter 앱 ──REST/JSON──▶ NestJS API(server/) ──Prisma──▶ PostgreSQL 17
                              │
                              └─▶ 서버 디스크(사진 원본·480px 썸네일)
```

- **API 약속**: [server/api-contract.json](../../server/api-contract.json)의 62개 API가 모두 `done`이다. 여기 없는 API는 만들지 않는다.
- **규칙 문서**: [server/AGENTS.md](../../server/AGENTS.md)(작업 규칙), [server/docs/API_RULES.md](../../server/docs/API_RULES.md)(주소·응답·오류), [server/ARCHITECTURE.md](../../server/ARCHITECTURE.md)(설계), [server/docs/LEARN.md](../../server/docs/LEARN.md)(입문).
- **요청 흐름**: `controller → service → PrismaService`. 같은 색 잠금(P01), 하루 한 호(P04), 숫자는 본인에게만(P18) 같은 제품 계약은 서버가 지킨다.

## 2. 단계 0: 서버 실행과 연결

### 한 일

1. `server/.env`를 `.env.example`에서 만들었다(개발용 값, 커밋하지 않음).
2. `npm ci`로 서버 의존성을 설치했다(Node 24.19.0).
3. Docker Desktop을 켜고 `docker compose up -d postgres`로 PostgreSQL을 띄웠다.
4. `npm run prisma:deploy`로 migration(DB 구조 변경 기록) 14개를 적용했다.
5. `npm run start:dev`로 서버를 켜고 확인했다.

| 확인 | 결과 |
|---|---|
| `GET /api/health` | `{"status":"ok","database":"up"}` |
| `GET /api/today/cover` | 200 (빈 DB라 표지 없음) |
| `GET /api/docs` (Swagger) | 200 |
| 기존 테스트 | 단위 40개, API 290개 통과 |

### 막혔던 것: Docker Desktop이 켜지자마자 꺼짐

- **증상**: 켤 때마다 "An unexpected error occurred"가 뜨고 엔진이 올라오지 않았다.
- **원인**: Docker가 예전에 남긴 소켓 파일(프로그램끼리 통신할 때 쓰는 임시 파일)을 Windows가 읽지도 지우지도 못했다. 오류 문구는 `rename …sock …sock.stale: The file cannot be accessed by the system`이었다.
- **해결**: Docker를 완전히 끈 뒤, 아래 두 폴더를 `…broken-…` 이름으로 옮기고(삭제하지 않음) 다시 켰다.
  - `%LOCALAPPDATA%\Docker\run`
  - `%LOCALAPPDATA%\docker-secrets-engine`
- **주의**: Docker가 비정상 종료되면 다시 생길 수 있다. 그때 같은 방법을 쓴다. 중간에 오류 창의 "Reset to factory defaults"가 한 번 눌려서 Docker 설정이 기본값으로 돌아갔을 수 있다.
- 이 PC의 Docker에는 Esel과 무관한 `supabase-*` 컨테이너도 떠 있다. 다른 프로젝트 것이라 건드리지 않았다.

## 3. 단계 1: 로그인 시도 제한 수정

커밋 `e0b7593` · `fix: block logins while the attempt limit is active`

### 문제

`POST /api/auth/email/login`은 비밀번호를 **먼저** 확인하고, 틀렸을 때만 횟수를 셌다. 그래서 1분 안에 5번 틀린 뒤 6번째에 맞는 비밀번호를 넣으면 로그인됐다. 비밀번호를 하나씩 대입해 보는 공격을 막는 장치가 정작 맞는 비밀번호는 막지 못한 것이다. 기록도 메모리에 계속 쌓이고 지워지지 않았다.

고치기 전 코드에 새 테스트를 돌려 버그를 먼저 재현했다. 429를 기대했는데 201(로그인 성공)이 나왔다.

### 고친 것

| 전 | 후 |
|---|---|
| 비밀번호 확인 → 틀리면 횟수 +1 | 횟수 +1 → 제한이면 바로 429 → 비밀번호 확인 |
| 5번 틀린 뒤 맞는 비밀번호 = 로그인 성공 | 5번 시도한 뒤 6번째 = 맞아도 `429 RATE_LIMITED`, 세션도 안 만듦 |
| 동시에 100개 보내면 100개 모두 통과 | 동시에 보내도 5개까지만 비밀번호 확인까지 감 |
| 기록이 계속 쌓임 | 1분 지난 기록은 1분에 한 번 정리 |

- 제한 전에 로그인이 성공하면 기록을 지운다.
- 계정이 없는 이메일도 같은 시간만큼 계산하게 하는 기존 장치(`LOGIN_TIMING_DUMMY_HASH`)는 유지했다. 횟수도 계정 유무와 관계없이 이메일 기준으로 세므로 429로 계정 존재 여부가 드러나지 않는다.
- 바뀐 파일: `server/src/auth/login-rate-limiter.ts`, `auth.service.ts`, 두 테스트 파일, `ARCHITECTURE.md` 한 줄.

### 고친 테스트 하나

기존 API 테스트 "성공은 실패 횟수를 초기화…"가 **5번 틀린 뒤 성공(201)** 을 기대하고 있었다. 버그를 정답으로 고정하던 테스트라 **4번 틀린 뒤 성공**으로 바꿨다. 그리고 "5번 틀린 뒤 6번째는 맞는 비밀번호여도 429" 테스트를 새로 넣었다. PR에서 리뷰어 확인을 부탁했다.

### 새로 나온 개념

- **레이트 리밋(rate limit)**: 정해진 시간 안에 요청할 수 있는 횟수를 제한하는 것.
- **경쟁 상태(race condition)**: 요청 여러 개가 동시에 들어와 "확인"과 "기록" 사이 틈을 함께 통과하는 문제.
- **429 Too Many Requests**: "너무 자주 요청했다"는 상태 코드.

## 4. 단계 2: 쓰이지 않은 업로드 사진 정리

커밋 `a83ce0c` · `fix: clean up unused uploaded photos on the server` · [#34](https://github.com/konga22/Esel/pull/34) 리뷰 후속 항목

### 문제

사진 업로드는 준비(`POST /api/media`) → 파일 전송(`PUT /api/media/:id/file`) → 완료 검사(`POST /api/media/:id/complete`) 3단계다. 그 뒤 올리기가 실패하거나 앱이 다시 시도하면, 호에 연결되지 않은 사진의 DB 행과 디스크 파일(원본·썸네일)이 그대로 남았다.

### 고른 방식

코드를 쓰기 전에 비교안을 정리했고, 팀원이 **정리 기준 1 + 실행 방식 C**를 골랐다.

| | 고른 안 | 다른 안 |
|---|---|---|
| 정리 기준 | **1**: 연결 안 됨 + 마지막 변경 뒤 24시간, 상태 무관 | 2: 상태별로 1시간 / 24시간 |
| 실행 방식 | **C**: 서버 시작 시 한 번 + 6시간마다 | A: 수동 `npm` 명령 / B: 서버 시작 시만 |

### 동작

- **대상**: 호·트윈 게시에 연결되지 않고 `updatedAt` 뒤 24시간이 지난 `PENDING`·`READY`·`REJECTED` 사진.
- **한 번에**: 오래된 것부터 최대 100장. 남은 것은 다음 차례에 지운다.
- **지키는 것**:
  - 지우는 순간에도 "연결 안 됨 + 24시간 지남" 조건을 다시 건다(조건부 삭제). 그래서 그 사이 발행된 사진은 지우지 않는다.
  - DB 행을 먼저, 파일을 나중에 지운다. 반대로 하면 파일만 사라지고 "준비됨" 행이 남아 올리기가 깨질 수 있다.
  - 한 장이 실패해도 로그만 남기고 다음 장으로 넘어간다.
  - `DELETED`(삭제한 호의 사진)는 하루 한 호 기록(P04)이라 지우지 않는다.
  - 앞 정리가 돌고 있으면 겹쳐 실행하지 않는다.
  - 서버를 끌 때는 돌던 정리가 끝날 때까지 기다린다. Nest는 이 모듈을 DB 연결 모듈(`PrismaModule`)보다 먼저 닫으므로 정리 도중 DB 연결이 끊기지 않는다(Nest 코드로 확인).
- **새로 생기지 않은 것**: API, migration, 외부 패키지.

| 파일 | 역할 |
|---|---|
| `server/src/media/media.rules.ts` | 기준값(24시간, 100장)과 기준 시각 계산 |
| `server/src/media/media.service.ts` | `cleanupUnusedMedia()`: 실제 삭제 |
| `server/src/media/media-cleanup.scheduler.ts` (새 파일) | 시작 시 + 6시간마다 호출 |
| `server/src/media/media.module.ts` | 스케줄러 등록 |

문서는 [server/README.md](../../server/README.md), [server/ARCHITECTURE.md](../../server/ARCHITECTURE.md) §11, [PUBLISH_API_CONNECTION.md](../flutter/PUBLISH_API_CONNECTION.md)(후속 항목을 "보완함"으로)에 반영했다.

### 새로 나온 개념

- **생명주기 훅(lifecycle hook)**: 서버가 켜지거나 꺼질 때 Nest가 자동으로 불러 주는 함수(`onApplicationBootstrap`, `onModuleDestroy`).
- **`setInterval` + `unref()`**: 정해진 시간마다 함수를 부르는 Node 내장 타이머. `unref()`는 이 타이머 때문에 프로그램이 끝나지 못하는 일을 막는다.
- **조건부 삭제**: "이 조건이 지금도 맞을 때만 지워라"를 한 번의 DB 명령으로 보내는 것.
- **가짜 타이머(fake timer)**: 테스트에서 6시간을 기다리지 않고 시간을 앞으로 감는 기능.

## 5. 검사 결과

| 명령 | 단계 1 후 | 단계 2 후 |
|---|---|---|
| `npm run check:server` | 통과 | 통과 |
| `npm run test:harness` | 24/24 | 24/24 |
| `npm run lint` | 통과 | 통과 |
| `npm test` (단위) | 43개 | 48개 |
| `npm run build` | 통과 | 통과 |
| `npm run test:e2e` (API) | 291개 + todo 5 | 295개 + todo 5 |
| 루트 `npm run check:harness` | — | 통과 |
| GitHub CI (PR #35) | — | 5개 모두 통과 |

- todo 5개는 원래 남아 있던 것이다.
- `tsc --noEmit`의 오류 2건(`reader-line-rate-limiter.spec.ts`, `twins.e2e-spec.ts`)은 main에 원래 있던 것이고 빌드 대상이 아니다.
- 실기기·Flutter 앱 화면은 확인하지 않았다.

## 6. 앱 개발자에게 알릴 것

- API 경로·오류 코드·응답 모양은 바뀌지 않았다.
- 로그인: 5번 시도한 뒤 1분 동안은 맞는 비밀번호도 `429 RATE_LIMITED`다. 원래 문서에 적힌 동작이다.
- 사진: 업로드를 마친 사진도 **24시간 안에 올리지 않으면 서버에서 지워진다.** 그보다 오래 둔 초안의 사진 ID로 올리면 `409 MEDIA_NOT_READY`이므로 사진을 다시 올려야 한다.

## 7. 남은 것

**PM 목록**

- **3번 문서 정리**: `docs/ESEL_HARNESS.md` §6의 "API 55개"와 `server/README.md`의 "62개"를 `api-contract.json` 기준으로 맞춘다. README의 "Flutter 앱과 연결" 절을 현재 연결 상태로 고친다.
- **4번 배포 준비 점검**: 지시가 있을 때만. 실제 배포는 하지 않는다.
- **손대지 않음**: `isMinor`(항상 `false`). 미성년자 판별 방법이 PM 결정 대기 중이다.

**이번에 알게 된 범위 밖 항목**

- 가입 제한기(`signup-rate-limiter.ts`)도 기록이 메모리에 쌓이기만 한다.
- 제한 기록은 서버 메모리에만 있어서, 서버를 여러 대 띄우거나 재시작하면 공유되지 않거나 사라진다(문서에 원래 적힌 한계).
- 업로드 도중 서버가 죽어 남은 임시 `*.part` 파일과, DB 행 없이 디스크에만 남은 파일은 아직 정리하지 않는다.
- `npm ci` 결과 의존성 취약점 경고가 있다(moderate 7, high 8). `npm audit fix --force`는 Prisma를 낮추는 호환성 파괴 변경이라 검토 없이 실행하지 않는다.

**아직 정해지지 않은 정책(이번 범위에서 미룸)**

후보 3색 배정 확률·희귀 팔레트, 미성년자 판별, 인기 혼합 신호, Apple·Google 로그인과 이메일 인증, 운영 미디어 저장소와 HEIC 변환, 푸시 알림, 신고 처리 정책, 탈퇴 시 공동 트윈의 상대 기록 처리. 출처는 [기능 목록](../dev/FEATURES.md)의 "사용자 결정이 필요한 것"과 [하네스 §2](../ESEL_HARNESS.md)의 미확정 줄이다.

# 저장소·PR 점검 보고서 (2026-10-15)

> 점검 기록이다. 결정이 아니다. 여기 적힌 권고는 [하네스 §2 결정 이력](../ESEL_HARNESS.md)에 반영되지 않았고, 사용자가 정하기 전까지 작업 기준이 아니다. 학교 PC(Windows)에서 Claude Code로 점검했고, 맥북에서 이어서 작업할 때 읽으려고 남긴다.

## 0. 먼저 읽을 요약

**main 저장소:** 문서·디자인·하네스는 거의 완성됐다. 지금 디자인으로 동작하는 앱·서버는 아직 없다(DEV-01~20 전부 `todo`). 확인한 문제는 세 가지다.

| ID | 문제 | 심각도 | 할 일 |
|---|---|---|---|
| H1 | `check:harness`가 맥북 밖(Windows·다른 팀원 PC)에서 실패. 보관 문서의 `/Users/gimminsang/...` 절대 링크 + `.gitattributes` 없음(CRLF) | 중 | 작은 수정(§2.3) |
| H2 | 발행 전에 색을 바꾸면 같은 색 잠금(P01)이 풀린다 | **높음** | **사용자 결정** 후 DEV-02 |
| H3 | Expo 앱은 9월 디자인 그대로라 현재 디자인과 거의 겹치지 않음 | 정보 | DEV-01부터 새로 |

**열린 PR 세 개:**

| PR | 작성자 | 대상 | 규모 | 등급 | 한 줄 평가 | 권고 |
|---|---|---|---|---|---|---|
| [#4 서버 기반](https://github.com/konga22/Esel/pull/4) | SKNGYJ | `main` | +8,796 (lock 7,657) | **B** | 구조와 P04 DB 강제는 좋음. 외부 유료 배포 흔적, 운영 Swagger, 병합 시 루트 typecheck 깨짐 | 4가지 고친 뒤 병합 |
| [#7 서버 하네스](https://github.com/konga22/Esel/pull/7) | konga22 | `Server_side` | +1,046 | **C+** | 약속 목록과 학습 문서는 충실. 검사 강제력과 루트 하네스 연결에 구멍 | 고친 뒤 병합 |
| [#8 Flutter 시연 앱](https://github.com/konga22/Esel/pull/8) | 김관혁 | `main` | +17,276 | **C** | 시연은 동작하고 로컬 저장은 견고. 플랫폼 결정이 기록되지 않았고 P01·P13·P16이 깨짐 | **main 병합 보류** |

등급은 검토자 판단이다. 기준은 "이 저장소의 AGENTS.md·하네스·개발 가이드를 얼마나 지켰는가"와 "실제로 돌려 봤을 때 주장대로 동작하는가"다.

**사용자가 정해야 할 것:**
1. 클라이언트를 **Expo로 유지할지 Flutter로 바꿀지**(PR #8). 바꾼다면 하네스 §2에 날짜와 함께 기록하고 하네스 문서를 같이 고친다.
2. **같은 색 잠금 기준**(H2). 그날 후보 3색 모두 잠금 / 처음 고른 색 고정 / 본 색은 고를 수 없음 중 하나.
3. PR #7의 "일부러 실패를 남기는 미션 0"을 유지할지. 아니면 PR #4 리뷰에서 바로 고칠지.

**권장 순서:**
1. main에서 H1 고치기. `.gitattributes`를 넣으면 PR #7의 migration 해시 거짓 실패도 함께 사라진다. 루트 `tsconfig.json`에 `exclude: ["server"]`도 넣는다.
2. 위 결정 1·2 내리기.
3. PR #4 고치기 → main 기준 rebase → 병합.
4. PR #7 고치기 → base를 main으로 바꾸기(또는 #4 병합 후 rebase) → 병합.
5. PR #8은 결정 1에 따라 처리: 정식 채택이면 하네스 갱신과 수정 목록(§3.4)을 반영해 병합, 아니면 시연 브랜치나 태그로만 둔다.

## 1. 점검 환경과 방법

- 환경: Windows 11(학교 PC), Node 24.19, npm 11.17, Flutter 3.47, Git `core.autocrlf=true`. Docker CLI는 있지만 데몬은 꺼져 있었다.
- main(`bbdaf2d`)을 새로 clone해서 문서와 코드를 읽고 `test:rules`·`check:harness`를 돌렸다.
- PR 세 개는 검토 에이전트 세 개가 나눠서, 각자 별도 worktree에서 PR 내용을 하네스·개발 가이드와 대조하고 빌드·테스트를 실제로 돌렸다.
- 보고서의 무거운 주장은 메인 세션이 코드를 다시 열어 확인했다. 확인한 항목은 **(재확인)**으로 표시했다.
- 돌리지 못한 것은 "미확인"으로 적었다. 실기기, iOS, Docker/DB e2e, Expo typecheck가 여기에 해당한다.
- 맥북에서는 `/Users/gimminsang/...` 경로가 실제로 있어서 H1이 드러나지 않는다. 그래서 지금까지 몰랐던 것으로 보인다.

## 2. main 저장소 상태

이 절의 문제(H1~H3)와 실행 결과는 메인 세션이 직접 재현했다.

### 2.1 구성

| 층 | 위치 | 상태 |
|---|---|---|
| 기준 문서 | `AGENTS.md` → `docs/ESEL_HARNESS.md` → `harness.json` | 계약 P01~P18, 수동 검증 V01~V12, 날짜별 결정 이력 |
| 디자인 원본 | `.codex/temp/prototype/20261003-cover-sns/generator` (`lib.mjs`) | 캔버스 화면을 코드로 생성. 최신 기준 |
| 앱 목업 | `.codex/temp/prototype/20261011-app-mockup/src/app.js` (1,446줄) | 54화면, 백엔드 없음 |
| 규칙 기준 | `.codex/temp/prototype/20260906-minimal-gallery/src/*.js` + 테스트 59개 | 같은 색 잠금·트윈·복원 규칙 |
| 기능 목록 | `docs/dev/features.json` → `FEATURES.md` | DEV-01~20, **전부 `todo`** |
| Expo 앱 | `app/`, `src/` (약 1,300줄) | 9월 갤러리 디자인. 3색(`#DE6B4A` 강조색 등), 표지 SNS 미반영 |

커밋 27개(2026-09-05 ~ 10-11)이고 디자인 방향이 세 번 바뀌었다(갤러리 → 미니멀 → 표지 SNS). 문서·디자인은 거의 완성됐고, 지금 디자인으로 동작하는 앱·서버는 아직 없다.

### 2.2 잘된 점

- **결정 이력 표**(하네스 §2): 날짜, 사용자 결정인지 시안 가정인지, AI가 어떻게 처리할지가 함께 있어서 다른 AI가 컨셉을 다시 추측하지 않아도 된다.
- **문서와 코드의 어긋남을 기계로 검사**: `features.json`에서 `FEATURES.md`·`src/design/tokens.ts`를 생성하고, 생성 파일 최신 여부, 계약·화면 연결, 선행 기능 순환, `done` 기능의 테스트 파일 존재를 `check:harness`가 확인한다.
- **정책이 타입 수준 요구로 내려가 있음**: 공개 응답 타입에 반응 숫자 필드 없음(P18), 잠긴 표지의 이름·ID가 응답에 없음(P01), "클라이언트 잠금은 보안이 아니다" 명시.
- **보관 자료 표시 체계**: 이전 시안이 `harness.json.archive`·README·맨 위 표시로 구분되고 검사로 강제된다.

### 2.3 확인한 문제

#### H1. `check:harness`가 작성자 맥북 밖에서는 실패한다 (심각도: 중, 작은 수정)

원인 두 가지. 둘 다 이 PC에서 재현했고, 둘을 임시로 우회하면 `하네스 정합성 통과: 경로 109개, 색 12개, 예시 인물 27명, 제품 계약 18개 …`가 나온다.

1. **보관 문서의 맥 절대 경로 링크.** [check-harness.mjs:62](../../scripts/check-harness.mjs)는 `http:` 같은 스킴만 건너뛰고 `/`로 시작하는 링크는 그대로 `access()`한다. 그래서 `/Users/gimminsang/...` 링크가 있는 문서는 그 맥에서만 통과한다.
   - `.codex/temp/20260906-0210-feat-feed-chrome-ui-workflow.md:66`
   - `.codex/temp/prototype/20260906-paint-feed/prototype.md:61`, `:130`
   - `.codex/temp/prototype/20260906-paint-feed/assets.md:19-35` (`/Users/gimminsang/.codex/generated_images/...`는 저장소 밖 파일)
   - `.codex/temp/prototype/20260906-art-directions/prototype.md:90` (링크가 아닌 코드 표기라 검사에는 걸리지 않음)
   - PR #8 작성자도 같은 실패를 보고했다.
2. **`.gitattributes`가 없음.** Windows(`core.autocrlf=true`)에서 `docs/dev/FEATURES.md`·`src/design/tokens.ts`가 CRLF로 체크아웃되고, [dev-harness.mjs](../../scripts/dev-harness.mjs)의 `checkDev()`가 LF로 생성한 문자열과 `assert.equal`로 비교해서 `FEATURES.md가 최신이 아님`으로 실패한다.

고치는 방법:
- 저장소 안을 가리키는 링크는 상대 경로로 바꾸고, 저장소 밖 파일은 링크 대신 "원본은 작성자 로컬에만 있음" 같은 일반 텍스트로 바꾼다. 맨 위 보관 표시 줄은 유지한다.
- `check-harness.mjs`가 `/`로 시작하는 링크를 만나면 건너뛰지 말고 "저장소 상대 경로를 쓰라"는 메시지로 실패하게 한다.
- 루트에 `.gitattributes`(`* text=auto eol=lf`, 이미지·폰트는 `binary`)를 추가하고, `checkDev()` 비교 전에 `\r\n`을 `\n`으로 정규화한다.

재현:

```bash
git clone https://github.com/konga22/Esel.git && cd Esel   # Windows, autocrlf=true
node scripts/check-harness.mjs                              # ENOENT C:\Users\gimminsang\...
```

#### H2. 발행 전에 색을 바꾸면 같은 색 잠금이 풀린다 (심각도: 높음, 제품 결정 필요)

[social-state.js:83-91](../../.codex/temp/prototype/20260906-minimal-gallery/src/social-state.js)의 `canView`는 아직 확정되지 않은 `state.selected` 색만 잠근다. `choose()`는 확정·발행 전이면 몇 번이든 색을 바꿀 수 있다.

재현 결과(규칙 함수를 그대로 호출):

| 순서 | 동작 | sage 방 |
|---|---|---|
| 1 | sage 선택(발행 전) | `preview`, 3장 |
| 2 | butter로 바꿈(발행 전) | `open`, **5장 전부** |
| 3 | 다시 sage로 바꿈 | `canChoose` = true → 다 본 뒤 sage로 발행 가능 |

앱 목업도 같은 구조다(`20261011-app-mockup/src/app.js:175-176`, `S.me.color` 기준). P01은 "발행을 끌어내 SNS를 활성화하는 연쇄 작용"(10-05 사용자 설명)이 목적이라, 이대로 서버에 옮기면(DEV-02) 목적이 무너진다. **DEV-02를 시작하기 전에 사용자가 정해야 한다.** 선택지 예:

- 그날 후보 3색을 모두 잠근다(발행 전에는 세 방 모두 미리보기 3장).
- 처음 색을 고르는 순간 그날 색을 고정한다(`choose`를 1회로).
- 미리보기 이상을 본 색은 그날 고를 수 없게 한다.

#### H3. Expo 앱은 현재 디자인과 거의 겹치지 않는다 (심각도: 정보)

`src/components/theme.ts`는 옛 색(`#252522`, `#DE6B4A`), `src/data/demo.ts`는 3색이고, 화면 코드에 색 hex가 직접 들어가 있다. 개발 가이드(§3)도 이 코드를 "새 화면이 대체하면 정리"할 대상으로 본다. 이 PC에서는 Expo 의존성을 설치하지 않아서 `npm run typecheck`·`npm test`는 **돌리지 않았다(미확인)**.

#### 실행 결과 (main)

| 명령 | 결과 |
|---|---|
| `npm run test:rules` | 59/59 통과 |
| `npm run check:harness` | **실패**(H1). 절대 경로 링크 건너뛰기 + LF 정규화로 우회하면 통과 |
| `npm run typecheck`, `npm test` (Expo) | 미실행(의존성 미설치) |

## 3. 열린 PR 검토

### 3.1 한눈에 비교

| 항목 | #4 서버 기반 | #7 서버 하네스 | #8 Flutter 시연 |
|---|---|---|---|
| 하네스가 정한 방향과 맞는가 | 맞음(직접 운영 서버, BaaS 없음) | 맞음(루트 계약을 서버 약속으로 옮김) | **다름**(클라이언트 Expo → Flutter, 하네스 미갱신) |
| 루트 문서 갱신 | 해당 없음(병합 후 `harness.json` 서버 상태 갱신 필요) | 서버 문서만. 루트와 대조하는 검사 없음 | **안 함**. 대신 `.agents/rules/esel-flutter.md`(always_on)가 반대 지시 |
| 제품 계약 P01~P18 | P04를 DB로 강제(좋음). P01·P14는 일부만 | 대부분 반영. 서가 P01·트윈 P08~P09 일부 빠짐 | P11은 좋음. **P01·P13·P16 위반**, P04·P18 일부 |
| 승인 없는 새 의존성 | `@nestjs/mau`, `nest deploy` | 없음 | Flutter 패키지 4개(승인 기록 없음) |
| 테스트 | 단위 2/2(루트 설치 필요), e2e 미확인 | todo 211개(설명은 259), 검사가 todo 문구로 통과 | 47/47 통과. 다만 앱이 안 쓰는 코드를 검사하는 테스트가 있음 |
| 정직성 | 범위를 정직하게 밝힘 | 수치 오류(259→211), "3건 실패"는 맥 기준 | 범위와 미검증을 정직하게 적음. 단 "정적 검사 오류 없음"은 현 stable에서 경고 1건 |
| main에 미치는 영향 | **루트 typecheck 9건 실패** | 충돌 없음 | 루트 검사에는 영향 없음(`check:harness`가 `flutter_app/`을 보지 않음) |

### 3.2 PR #4 직접 구축 서버 기반 (SKNGYJ, base `main`)

**등급 B · 조건부 병합.** 서버 골격으로는 충분히 좋다. 다만 병합 전에 고칠 것이 4가지 있다.

**한 일:**
- NestJS + Prisma 7.10 + PostgreSQL 17 서버 골격(`server/`): zod 환경변수 검증, Helmet, CORS 허용 목록, 전역 ValidationPipe, Swagger, `/api/health`(DB 확인)
- Prisma 모델 8개(User, Profile, Color, DailyPalette, DailyPaletteColor, UserDailyChoice, MediaAsset, Issue)와 init 마이그레이션
- `compose.yaml`(postgres, 일회성 migrate, api), 멀티스테이지 Dockerfile
- 단위 테스트 2개, e2e 1개, `server/ARCHITECTURE.md`

기능(인증·업로드·발행·피드)은 아직 없고, PR에도 그렇게 적혀 있다.

| 기준 | 판정 | 근거 |
|---|---|---|
| BaaS 없음(`harness.json` `noBaaS`) | 적합 | Supabase·Firebase 없음 |
| controller → service → Prisma | 적합 | health 모듈이 이 구조이고, 서비스에 단위 테스트가 있음 |
| P04 하루 한 호 | 적합(DB 강제) | `schema.prisma` `@@unique([authorId, serviceDate])`, `@@unique([authorId, issueNumber])`(재확인) |
| P04 결호 없는 호수 | 부분 | 중복만 막음. 연속성은 이후 트랜잭션이 책임지고, `issue_number >= 1` CHECK도 없음 |
| P01 같은 색 잠금 | 부분 | `(serviceDate, colorId, publishedAt)` 인덱스로 최신 3장 조회는 됨. 미성년자 필드 없음. ARCHITECTURE.md가 "책등으로 반환"이라 써서 하네스의 "개수만"과 어긋남 |
| P14 제호 `^[a-z]{2,10}$` | 부분 | `VarChar(10)` + unique만 있음. 패턴 CHECK가 없어서 `Selin`과 `selin`이 함께 존재할 수 있음 |
| P15 얼굴 연출 4종 | 적합 | FaceMode enum이 하네스와 1:1, 호마다 저장 |
| P18 숫자는 본인만 | 적합(해당 없음) | 반응 숫자 컬럼이 아직 없음 |
| 새 라이브러리·외부 서비스 승인 없이 추가 금지 | **위반** | `server/package.json:11` `"deploy": "nest deploy"`, `:47` `@nestjs/mau` |
| `.env` 커밋 금지 | 적합 | `.env.example`만 추적함 |
| 가이드의 검사 명령이 통과할 것 | **위반(병합 시)** | 아래 문제 1·2 |

**PR #7이 지적한 3건 (재확인)**
- **운영 환경 Swagger 노출: 사실이다.** `server/src/main.ts`가 조건 없이 `SwaggerModule.setup('api/docs', …)`를 부른다. 검토 에이전트가 `NODE_ENV=production`으로 띄워 `/api/docs`가 200인 것을 확인했다.
- **`@nestjs/mau`: 부분 사실이다.** dependencies가 아니라 `devDependencies`에 있어서 운영 이미지(`npm ci --omit=dev`)에는 들어가지 않는다. 하지만 NestJS 상용 배포 클라우드(Mau) CLI라서 승인되지 않은 외부 서비스다. `nest new` 템플릿 기본값이 남은 것으로 보인다.
- **`"deploy": "nest deploy"`: 사실이다.** 실행하면 Mau로 배포를 시도한다.

**실행 결과 (검토 에이전트)**

| 명령 | 결과 |
|---|---|
| `git merge-tree main origin/Server_side` | 충돌 없음(main보다 10커밋 뒤처짐) |
| `npm ci`, `npm run lint` | 통과 |
| `npm run build` | generate 전에는 실패하고, `prisma:generate` 후 성공 |
| `npm test` | 루트 Expo를 설치하지 않으면 **실패**(`Tsconfig not found expo/tsconfig.base`), 설치하면 2/2 통과 |
| `prisma validate`, 스키마와 init SQL 비교 | 일치 |
| 운영 모드 스모크(DB 없음) | 기동됨. health 503 `database: down`, Helmet·CORS 동작, 잘못된 env면 기동 실패 |
| 병합 트리에서 루트 `npm run typecheck` | **실패 9건, 모두 `server/`** |
| `npm audit --omit=dev` | high 4건(Prisma 도구 체인 경유, ARCHITECTURE.md에 인지돼 있음) |
| `test:e2e`, `docker compose up --build` | 미확인(Docker 데몬 꺼짐) |

**문제 (심각도 순)**

1. **[높음] 병합하면 main의 루트 `npm run typecheck`가 깨진다(설정은 재확인).** 루트 `tsconfig.json`의 `include: **/*.ts`가 `server/`까지 포함해서 데코레이터·vitest 전역 오류가 9건 난다. 루트 `exclude`에 `"server"`를 넣으면 0건이다.
2. **[높음] 서버 테스트가 루트 Expo 설치에 의존한다(설정은 재확인).** `server/vitest.config.ts`의 `resolve.tsconfigPaths: true`가 루트 tsconfig(`extends expo/tsconfig.base`)를 따라간다. 서버는 `paths`를 쓰지 않으므로 이 옵션과 `vite-tsconfig-paths`를 지우면 된다.
3. **[높음] 외부 유료 배포 흔적**(`deploy` 스크립트, `@nestjs/mau`).
4. **[높음] 운영 환경 Swagger 노출.** 가이드가 Swagger를 계약 정본으로 쓰므로, 없애지 말고 개발 환경에서만 켠다.
5. **[중간] 컨테이너가 root로 실행된다**(Dockerfile에 `USER` 없음). `CMD ["npm","run","start:prod"]`라 npm이 PID 1이 되고, `enableShutdownHooks()`가 없어서 종료 신호를 받아도 Prisma 연결 정리가 불리지 않는다.
6. **[중간] compose**: 개발용 비밀번호가 고정된 채 `5432`·`3000` 포트가 모든 인터페이스에 열린다.
7. **[중간] DB 제약이 하네스를 강제하지 못한다.** 제호 패턴, 후보 색 position 1~3, hex 형식, 12색 seed가 없다. "후보 밖 색 선택 불가"(DEV-07), "Issue 색 = 그날 선택", "미디어 소유자 = 작성자"도 DB가 막지 못한다. `Issue.mastheadColor`(DEV-09 요청 본문)도 컬럼이 없다.
8. **[중간] 환경변수 검증이 느슨하다.** 운영에서도 `CORS_ORIGINS`가 localhost 기본값으로 채워지고, `SERVICE_TIME_ZONE`은 검증하지 않으며 아직 쓰이지도 않는다.
9. **[낮음]**
   - e2e가 `main.ts` 설정(ValidationPipe, Helmet)을 재현하지 않는다.
   - build가 generate에 의존하는데 자동화가 없다.
   - ARCHITECTURE.md의 계약 요약이 하네스와 조금 다르다: P01 개수만·자정·미성년자, P12 "한 줄", P18 순위 금지가 빠졌다.

**잘한 점:**
- P04 핵심을 PostgreSQL unique로 막아서 동시 요청까지 방어한다.
- 피드 인덱스가 P01 "최신 3장" 조회에 맞다. FaceMode가 하네스와 1:1이다.
- 마이그레이션을 일회성 서비스로 분리했고, DB healthcheck가 있다.
- 시작할 때 zod로 실패시키고, `whitelist`·`forbidNonWhitelisted`, `.env` 미커밋이 지켜졌다.
- ARCHITECTURE.md가 범위를 정직하게 밝혔다("기능 구현이 아님", "클라이언트 잠금은 보안이 아님").

**병합 조건:**
1. `deploy` 스크립트와 `@nestjs/mau`를 지우고 lockfile을 다시 만든다.
2. Swagger는 운영이 아닐 때나 명시적 플래그가 있을 때만 켠다.
3. vitest에서 `tsconfigPaths`를 지우고 `vite-tsconfig-paths`를 삭제한다.
4. 루트 `tsconfig.json`의 exclude에 `server`를 넣는다.
5. main 기준으로 rebase한다.
6. `docker compose up --build`와 `test:e2e` 결과를 다시 첨부한다.

후속 PR로 Dockerfile `USER node`, 포트 `127.0.0.1` 바인딩, CHECK 제약 migration, `prebuild: prisma generate`를 요청한다.

### 3.3 PR #7 서버 개발 하네스와 배움 안내 (konga22, base `Server_side`)

**등급 C+ · 고친 뒤 병합.** 내용은 좋지만, 하네스의 핵심인 "강제력"과 "루트와의 일관성"에 구멍이 있다.

**한 일:** `server/AGENTS.md`·`CLAUDE.md`(서버 AI 규칙), `server/api-contract.json`(API 49개, 오류 코드 23개, 공개 금지 필드), `docs/LEARN.md`(개념과 미션 0~9)·`API_RULES.md`·`REVIEW.md`, `scripts/check-server.mjs`(정규식 정적 검사), `harness/migrations.lock.json`, `test/contracts/*.e2e-spec.ts` 14개. 서버 런타임 코드는 바꾸지 않았다.

| 기준 | 판정 | 근거 |
|---|---|---|
| `features.json` 서버 초안 반영 | 적합 | 45/45 모두 옮김, DEV 번호 일치 |
| P04 하루 한 호, P12 쓰기는 로그인, P14 제호 | 적합 | `ISSUE_ALREADY_PUBLISHED`, 모든 user/owner API에 401 todo, `^[a-z]{2,10}$` |
| 우선순위(사용자 요청 > 계약 > 목업 …) | **위반** | `server/AGENTS.md:3` "이 파일이 서버 작업에서는 우선한다", 루트는 그다음에 읽으라고 함 |
| API 정본 | 정리 안 됨 | 서버 문서는 "api-contract에 없는 API는 만들지 않음", 루트(`docs/dev/README.md` §3, DEV-03)는 "확정은 Swagger" |
| P01 같은 색 잠금 | 부분 | `magazines.get`(서가) 계약이 `["P04","P18"]`뿐(`api-contract.json:71`, 재확인). 미성년자 예외, "확정·복원·트윈으로는 안 열림" todo 없음 |
| P18 숫자는 본인만 | 부분 | 설계는 맞음(Public/Owner DTO 분리). 검사는 `*PublicDto` 이름과 정확한 필드명에만 반응 |
| P08~P10 트윈 | 부분 | 공유 추천 1개, 기본 비공개, "트윈 게시로 잠금 안 풀림" 없음 |
| 루트 하네스와 연결 | 없음 | `check-server.mjs`는 `server/`만 읽음. `P99`, `DEV-99`를 넣어도 통과 |

**문제 (심각도 순, 검토 에이전트가 실험으로 확인. (재확인)은 메인 세션이 코드로 다시 확인)**

1. **[높음] 완료(done) 판정이 todo 문구만으로 통과한다(재확인).** `check-server.mjs:65-66`은 테스트 파일에 `/api/경로` 문자열이 있는지만 본다. 그런데 PR이 넣은 todo(예: `today.e2e-spec.ts:7` `it.todo('GET /api/today/cover: …')`)에 이미 그 문자열이 있어서, 49개 전부 실제 테스트 없이 `done`으로 바꿀 수 있다.
2. **[높음] 루트 하네스와 어긋난다.** 테스트 경로가 루트 `features.json`(`server/test/auth.e2e-spec.ts` 등)과 다르고(`server/test/contracts/…`), 서버 기능을 `done`으로 바꾸는 순간 루트 `dev-harness.mjs`의 "done 기능의 테스트 파일 존재" 검사가 실패한다. 상태가 두 곳(`features.json`, `api-contract.json`)에 있다. 공개 금지 필드도 `harness.json.publicCounts`를 읽지 않고 따로 적었다. todo 생성 스크립트도 커밋되지 않았다.
3. **[중간] 서버 AGENTS.md가 루트 우선순위를 뒤집는다(재확인)**(위 표).
4. **[중간] Windows에서 거짓 실패가 난다.** `.gitattributes`가 없어서 migration SQL이 CRLF로 체크아웃되고 해시가 달라진다. 그래서 "실패 3건이 정상"이 아니라 4건이 된다. 학습자가 `migrations:lock`을 돌리면 CRLF 해시가 커밋돼서 이번에는 맥 팀원이 실패한다.
5. **[중간] `--lock-migrations`가 기존 해시를 무조건 덮어써서**, 수정된 공유 migration을 그대로 승인한다.
6. **[중간] 정규식 검사가 쉽게 속는다.** `@Controller({ path })`, `PrismaClient` 직접 주입, `FeedPageDto.likeCount`, `likesCount`는 놓친다. Swagger를 운영에서만 켜는 조건은 통과하고, 올바르게 막은 코드는 실패하는 오탐이 있다.
7. **[중간] 일부러 실패를 남기는 미션 0 설계.** 빨간 검사가 "정상"이 되면 팀이 무뎌진다. 유료 배포 패키지 같은 문제는 PR #4 리뷰에서 바로 고치는 편이 낫다. 저장소에 CI(`.github`)가 없어서 "미션 0 후 #4 병합"을 강제할 장치도 없다.
8. **[낮음]**
   - DEV-20(신고·차단·삭제)에는 API도 todo도 없다.
   - 트윈 API에 `NOT_FOUND`가 없고, 요청 본문이 있는 API 6개에 `VALIDATION`이 없다.
   - 클라이언트 전용 합격 기준 약 12개가 서버 e2e todo에 섞여 있다.
   - 403/404, 200/201 표기가 문서끼리 다르다.
   - 학습자 페르소나("처음 배우는 중")가 모든 서버 AI 세션에 적용된다.

**PR 설명과 실제의 차이:** "it.todo 259개"는 틀렸고 **실제 `it.todo`는 211개**다(직접 셈). "API 49개"는 맞다. "lint·vitest 못 돌림"이라고 했는데, 검토에서 `npm run lint`는 통과했고 todo 파일도 정상 수집됐다(211 todo).

**잘한 점:**
- 서버 초안 45개를 빠짐없이 옮겼다.
- 접근 권한 4종(public/user/owner/member)과 Public/Owner 응답 이름으로 P12·P18을 구조로 표현했다.
- "잠긴 것은 404(존재 사실 누출 방지)", "목록에 total 없음", "서버가 '오늘'을 정함"은 루트 계약을 정확히 이해한 규칙이다.
- 실패 메시지가 "왜 문제인가 / 고치는 법" 형식이다.
- main과 충돌 없이 합쳐진다.

**병합 전 할 일:**
1. done 판정이 `it.todo`를 무시하고 실제 요청 코드(`request(…).get(…)`)나 vitest 결과를 보게 한다.
2. `--lock-migrations`를 "추가만, 기존 해시 변경은 거부"로 바꾼다.
3. 해시 전에 줄바꿈을 정규화하거나 `.gitattributes`를 추가한다.
4. `server/AGENTS.md:3`을 "루트 우선순위를 따르고 서버 세부 규칙만 보충한다"로 바꾼다.
5. `check:server`가 `../harness.json`(`productContracts`, `publicCounts`)과 `../docs/dev/features.json`(ID, 경로, tests)을 읽어 대조하게 한다.
6. `magazines.get`에 P01·P02를 추가한다.
7. 정본 관계를 루트 가이드에 한 줄로 적는다("경로·권한·오류 = api-contract.json, 데이터 모양 = Swagger").

### 3.4 PR #8 Docker 없이 실행하는 Flutter 중간발표 시연 앱 (김관혁, base `main`)

**등급 C · main 병합 보류.** 시연용으로는 동작하고 범위도 정직하게 적었다. 하지만 하네스가 정한 클라이언트(Expo)와 다른 플랫폼을 들여오면서 하네스를 고치지 않았고, 핵심 흐름에 계약 위반 버그가 있다.

**한 일:** `flutter_app/`(Dart 약 11.8k줄, 테스트 47건, 에셋 8.8MB), `docs/flutter/MIDTERM_DEMO.md`·`PROGRESS.md`, `.agents/rules/esel-flutter.md`, `scripts/start-demo.ps1`, README 한 줄. `harness.json`, `AGENTS.md`, `docs/ESEL_HARNESS.md`, `docs/dev/*`는 **고치지 않았다(재확인)**.

- **mock 모드**(`--dart-define=ESEL_API_MODE=mock`, 시연 경로): 비로그인 표지 → 로그인 시트 → 피드 → 가판대 → 오늘 호 만들기(로컬 발행) → 내 잡지 → 서가 → 설정.
- **server 모드**(기본값): 로컬 초안 편집기와 계정 화면만 보이고, 잡지 UI에는 들어갈 수 없다.
- 친구·트윈·월간 기록 화면은 코드만 있고 어느 모드에서도 들어갈 수 없다.

| 기준 | 판정 | 근거 |
|---|---|---|
| 플랫폼 결정 | **위반** | `harness.json` `development.client`는 "Expo app/, src/", 하네스 §2(09-05)는 "새 플랫폼·기술을 임의로 추가하지 않음". PR은 하네스를 고치지 않고 `.agents/rules/esel-flutter.md`에 "Esel 클라이언트는 최신 사용자 요청에 따라 Flutter/Dart로 개발한다"만 적었다(재확인). 이 사용자 결정은 §2에도 PR 본문에도 없다 |
| 하네스 정합 | **위반** | `harness.json.notImplemented`에 `persistent-storage`, `real-auth`가 남아 있는데 코드는 둘 다 구현했다. 경로표·`nativeApp`에 `flutter_app`이 없다 |
| 새 라이브러리 승인 | 미확인 | `flutter_secure_storage`, `image_picker`, `share_plus`, `path_provider` |
| P01 같은 색 잠금 | **위반** | 아래 문제 2 |
| P04 하루 한 호 | 부분 | 로컬 라이브러리는 하루 한 번, 결호 없는 호수를 테스트로 보장한다. 다만 `hasPublishedToday`는 로그인할 때만 다시 계산하고 기기 현지 날짜를 쓴다. 앱을 켠 채 자정을 넘기면 재로그인 전까지 발행이 막힌다 |
| P11 얼굴 확인 전 발행 거절 | 적합 | 확인 전 발행 거절, "익명화를 보장하지는 않아요" 문구, 합성된 화면으로 내보내기 |
| P12 비로그인 | 부분 | 표지 + 2쪽 + 640px 지나 로그인 바는 맞다. 바가 글라스가 아니고 버튼이 하나뿐이며, 움직임이 240ms로 토큰(360ms)과 다르다 |
| P13 창간 | **위반** | 아래 문제 1 |
| P14 제호 | 부분 | 패턴 검사는 있다. 이메일 로그인은 이메일 앞부분으로 제호를 만들고, 2자 미만이면 예시 인물 `selin`으로 바꾼다 |
| P15 얼굴 연출 4종 | 부분 | 4종은 있다. "제호 뒤로"는 사진을 키우는 대신 제호를 옮기고, 물감 폭은 슬라이더 값이다(하네스: 얼굴 폭의 2.15배) |
| P16 표지는 첫 장만 | **위반** | 세로 PageView 모든 장에 `'Esel'` 제호가 붙고(`feed_screen.dart:189`), 녹아들기가 없다 |
| P17 12색 | 부분 | 12색 hex·이름·순서는 `tokens.ts`와 일치한다. 후보 3색은 고정이고, 피드 색 이름은 모든 장이 `'파우더 블루'`로 하드코딩돼 있다(`feed_screen.dart:263`, 재확인) |
| P18 숫자는 본인만 | 부분 | 남의 표지에는 숫자가 없다. 본인 판정을 userId가 아니라 제호 문자열로 한다. mock Apple/Google 로그인이 예시 인물 `dana`가 돼서 dana 표지에 가짜 본인 통계가 보인다 |
| 디자인 토큰 출처 | **위반** | 생성 파일 `tokens.g.dart`("DO NOT MODIFY BY HAND")에 손으로 넣은 32줄 블록이 있다. 생성기를 다시 돌리면 사라진다. 그 안에 하네스에 없는 색(`inkSubtle` 등, Muted보다 흐림)이 있다. 글꼴은 번들되지 않아 기기 기본 글꼴로 나온다 |
| 48px 터치, 캡슐 3항목 | 적합/부분 | 최소 크기는 강제한다. 캡슐은 화면 전체 폭에 일반 아이콘이다 |
| 시연·예시 데이터 금지(가이드 §2) | **위반** | 예시 인물, "같은 색 187명", 고정 `Nº 249 · 2026. 9. 6.`, 타인 서가는 누구를 눌러도 `seul`, 화면에 내부 ID("(S6)", "(P01)") 노출 |
| mock / 실서버 분리 | 부분 | 인증은 설정으로만 갈리고 몰래 전환하지 않는다(PR 설명대로). 피드·가판대·서가는 어댑터 없이 하드코딩이라 DEV-03의 "설정 하나로 교체"가 아니다 |
| 에셋·초상권(하네스 §6) | **위반** | 아래 문제 5 |

**실행 결과 (검토 에이전트, Flutter 3.47.6)**

| 명령 | 결과 |
|---|---|
| `flutter pub get` | 성공(현 SDK에서 lockfile 4개 패키지가 바뀜) |
| `flutter analyze` | **경고 1건, exit 1**(`http_client.dart:100`). PR의 "오류 없음"은 작성자 SDK 기준으로 보인다 |
| `flutter test` | 47/47 통과 |
| `test:rules` | 59/59 통과 |
| `check:harness` | main과 같은 H1 실패. 보정하면 main·PR 모두 통과. 이 검사는 `flutter_app/`을 보지 않는다 |
| 토큰 생성기 재실행 | 커밋된 파일과 32줄 차이(손으로 고친 것 확정) |
| 임시 재현 테스트 2건 | 가판대 키 불일치, 창간 후 0호 모두 재현 |
| APK·실기기·iOS | 미실행 |

**문제 (심각도 순)**

1. **[높음] 창간을 끝내도 창간호가 없다(P13·P04).** `app/app.dart:150-164`는 창간 완료 때 `'${masthead}@esel.app'` / `'esel1234'`로 가입시키고 화면 상태만 `_issueCount = 1`로 바꾼다(재확인). 라이브러리에 실제 발행은 없고, 내 잡지에는 "총 0호 발행"이 보인다. 기본 제호는 예시 인물 `dana`다. 비로그인 화면의 "내 잡지 만들기"로 실제로 들어갈 수 있다.
2. **[높음] 같은 색 잠금이 사실상 동작하지 않는다(P01).** 가판대 칩 id는 `EselPaint.name`(= `powder`)인데, `stand_controller.dart:23`와 `publishing_controller.dart:8`의 기본값·키는 `'powder-blue'`다(재확인). 그래서 내 색 칩에 자물쇠가 한 번도 뜨지 않고, 파우더 칩을 누르면 방이 비어 버린다. 잠금 기준도 사용자가 고른 색이 아니라 고정된 예시 색이고, 자정·미성년자 처리가 없다. 기존 `stand_test`도 같은 잘못된 키를 써서 이 버그를 가린다.
3. **[높음] 플랫폼 결정 미기록.** 하네스는 Expo를 말하고 `.agents/rules`는 Flutter를 말해서, 이후 AI·팀원 작업의 기준이 둘로 갈린다.
4. **[중간] 피드 모든 장에 Esel 제호(P16)와 고정 색 이름.** 생성 파일을 손으로 수정했고, 글꼴이 번들되지 않았다.
5. **[중간] 에셋.**
   - 36장 중 33장(약 8MB)은 코드에서 쓰지 않는데 APK에 들어간다.
   - `m03`~`m07`은 13곳에서 참조하지만 파일이 없다.
   - `assets/demo/dana.jpg`는 하네스가 정한 `blue-city.jpg`가 아니라 다른 사진이다.
   - 이름을 바꾼 사본이라 출처 추적이 끊긴다.
   - APK를 배포하면 하네스 §6("Pexels는 초상권 동의를 보장하지 않음")의 로컬 사용 범위를 넘는다.
6. **[중간] 개인정보.** 삭제·탈퇴해도 사진 파일과 `exports/`를 지우지 않는데, 화면은 "모든 호와 데이터가 영구히 삭제"라고 안내한다. mock에서는 같은 이메일에 아무 비밀번호(6자 이상)만 넣으면 그 계정의 로컬 데이터가 열린다.
7. **[중간]** 타인 서가가 항상 `seul`이다. P18 본인 판정을 제호 문자열로 한다. 날짜 경계(자정) 처리가 없다.
8. **[낮음]** 테스트 일부가 앱이 호출하지 않는 함수(`submitPublish`, `PrivacyRule`)를 검사한다. server 모드와 mock 모드가 같은 `library.json`을 쓴다. 사용자 문구에 "Docker"가 나온다. Android 앱 이름이 소문자 `esel`이다.

**잘한 점:**
- 로컬 저장소가 견고하다: 원자적 쓰기, 백업 복구, 쓰기 큐, 롤백, 스키마 버전, 테스트까지.
- 실서버 인증과 mock이 설정으로만 갈리고, 실패해도 몰래 전환하지 않는다. 토큰은 보안 저장소에 둔다.
- P11 확인 전 발행 거절, EXIF 제거, 15MB 제한, `allowBackup=false`가 있다.
- 48px 터치를 강제하고, 12색 값이 정확하다.
- 시연 범위와 검증하지 않은 항목을 문서에 정직하게 적었다. 비밀값·빌드 산출물은 빠져 있다.

**권고:** 클라이언트 결정(§0의 결정 1)이 먼저다.
- (가) Flutter로 바꾸기로 했다면 하네스 §2에 날짜와 함께 기록하고, `harness.json`(`development.client`, `nativeApp`, `notImplemented`)·AGENTS.md·하네스 §6·`docs/dev`(클라이언트·테스트 경로)를 같은 PR에서 갱신한다. `.agents/rules/esel-flutter.md`는 하네스와 일치시키거나 지운다.
- (나) 결정이 없다면 중간발표용 브랜치나 태그로만 두고 main에는 합치지 않는다.

정식으로 받는다면 작성자에게 위 문제 1·2·4·5·6 수정, 실제 흐름 테스트(창간 → Nº 001, 가판대 실제 키, 피드 첫 장만 제호), Flutter 버전 고정을 요청한다.

## 4. 세 PR에 공통으로 보인 것

- **줄바꿈과 경로 이식성.** H1(main), PR #7 migration 해시, PR #8 lockfile 차이가 모두 "작성자 기기에서만 맞는" 상태다. 루트 `.gitattributes`와 CI가 없어서 생긴다. GitHub Actions로 `test:rules`, `check:harness`, (병합 후) `check:server`를 Windows·macOS에서 돌리면 대부분 미리 잡힌다.
- **루트 하네스가 새 영역을 보지 않는다.** `check:harness`는 `server/`, `flutter_app/`을 읽지 않고, PR #7의 `check:server`는 루트를 읽지 않는다. 계약 ID·공개 금지 필드·테스트 경로가 이미 어긋나기 시작했다(§3.3 문제 2).
- **같은 색 잠금(P01)이 세 군데 모두 약하다.** 규칙 기준 코드는 색 바꾸기로 우회된다(H2). 서버 약속은 서가에서 P01이 빠졌다. Flutter 앱은 키 불일치로 동작하지 않는다. 제품의 핵심 장치이니 결정 2를 내린 뒤 DEV-02에서 한 번에 정리하는 것이 좋다.

## 5. 맥북에서 이어서 할 때

```bash
git fetch origin
git switch docs/repo-pr-review-20261015
```

- 맥북 AI에게는 "AGENTS.md, docs/ESEL_HARNESS.md, 이 보고서(docs/reports/2026-10-15-repo-pr-review.md)를 읽고 §0의 권장 순서 1번부터"라고 지시하면 된다.
- 결정 1~3은 사용자가 정한 뒤 하네스 §2 결정 이력에 날짜와 함께 적는다. 이 보고서만으로는 결정이 아니다.
- PR 리뷰 코멘트는 아직 아무 PR에도 남기지 않았다. 팀원에게 전달하려면 §3의 "병합 조건"과 "권고"를 그대로 코멘트로 옮기면 된다.

## 6. 처리 결과 (2026-10-15~16)

> 이 절은 보고서를 쓴 뒤에 붙였다. 위 1~5절은 점검 당시 기록 그대로다. 결정은 [하네스 §2](../ESEL_HARNESS.md) 10-15 행이 기준이다.

### 6.1 결정

| §0 결정 | 결과 | 기록 |
|---|---|---|
| 1. 클라이언트 | Flutter로 전환. Expo 앱 삭제 | 하네스 §2 10-15, konga22/Esel#10 |
| 2. 같은 색 잠금 기준 | 발행 전에는 그날 후보 3색 방이 모두 미리보기(최신 3장 + 개수). 색을 바꿔도 열리지 않고, 바꿀 자유는 유지. 후보가 아닌 색·지난 날짜는 공개 | 하네스 §2·P01, konga22/Esel#11(규칙 기준·목업·디자인·앱), konga22/Esel#7(서버 약속) |
| 3. 미션 0 | 리뷰에서 바로 고치고, 미션 0은 "무엇을 왜 고쳤는지 읽고 답하기"로 바꿈. `check:server`는 항상 실패 0건 | 하네스 §2, `server/docs/LEARN.md` |

결정 2·3은 사용자가 "추천하는 쪽으로 전부 해결"을 맡겨 추천안을 채택한 것이다(사용자 위임).

### 6.2 문제별

| 보고서 | 처리 | PR |
|---|---|---|
| H1 다른 PC에서 `check:harness` 실패 | 절대 경로 링크를 상대 경로로, 어느 Markdown이든 절대 경로 링크는 검사 실패. `.gitattributes`(LF), 생성 문서 비교에서 CRLF 무시. CI의 Windows 작업으로 확인 | #11 |
| H2 색을 바꾸면 잠금이 풀림 | 결정 2. 규칙 테스트 59 → 60개 | #11, #7 |
| H3 Expo 앱이 옛 디자인 | Expo 앱 삭제 | #10 |
| #4 병합 조건 1~6 | 유료 배포 흔적 삭제, 운영 Swagger 끄기, vitest가 루트 설치에 의존하지 않게, 루트 tsconfig는 #10에서 사라짐, main 합침, compose·e2e는 CI(PostgreSQL, Docker)에서 확인 | #7 |
| #4 후속 | `USER node`·node PID 1·종료 처리, 포트 127.0.0.1, CHECK 제약과 12색 migration, `prisma generate` 자동화, 환경변수 검증, `configureApp`으로 main과 e2e 설정 공유 | #7 |
| #7 문제 1~8 | todo 문구로 done 통과 막음, migration 잠금은 추가만, 줄바꿈 정규화, 서버 AGENTS 우선순위, 루트 하네스·기능 목록 대조, 서가 P01·P02, 정규식 검사 보강(자체 테스트 24개), 신고·차단·삭제 API, 클라이언트 전용 todo 정리, 상태 코드 통일 | #7 |
| #8 문제 1~8 | 창간 → 실제 Nº 001, 같은 색 잠금(키 통일, 후보 3색, 자정, 미성년자), 피드 첫 장만 제호와 녹아들기, 본인 판정을 계정 id로, 탈퇴 시 사진·내보내기 삭제와 mock 비밀번호 확인, 에셋 정리와 출처 표, 화면에 새는 내부 값 제거, mock/서버 저장 분리와 데이터 소스 인터페이스, Flutter 버전 고정. 테스트 47 → 136개 | #11 |
| §4 공통 | `.gitattributes`, CI(하네스·규칙: Ubuntu·Windows, Flutter, 서버·Docker), `check:server`가 루트를 대조, P01을 다섯 곳에서 같은 규칙으로 | #11, #7 |

### 6.3 아직 남은 것

- 실기기(Android·iOS) 확인, Flutter 3.47에서 analyze.
- 앱 화면 중 C3 펼침면, C6 만들기 편집기, M1 내 잡지는 디자인과 아직 다르다. 친구·트윈·월간 기록은 시연 범위 밖이다.
- 서버 기능(인증·업로드·발행·피드)은 아직 없다. API 55개 중 1개(health)만 완료.
- 사용자가 정할 것:
  - 후보 3색 배정 방식(전원 같음 / 사람마다)과 실제 확률
  - 미성년자 판별 방법
  - 미리보기 3장을 고르는 기준
  - 비로그인 첫 표지·공유 링크를 같은 색 잠금의 예외로 둘지
  - 신고 처리 주체와 기준
  - 호 삭제 후 같은 날 재발행과 호수
  - 차단한 사람이 제호 검색에 나오는지
  - 제호 변경 정책
  - 얼굴 자동 감지
  - 가판대 작은 표지 제호를 Esel로 둘지 개인 제호로 할지

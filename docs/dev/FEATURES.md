# 기능 개발 목록

> 자동 생성 파일이다. [features.json](features.json)을 고치고 `npm run dev:docs`로 다시 만든다. 개발 방법은 [개발 가이드](README.md)에 있다. (기준일 2026-10-11)

| ID | 기능 | 단계 | 목업 화면 | 계약 | 먼저 할 것 | 상태 |
|---|---|---|---|---|---|---|
| [DEV-01](#dev-01) | 디자인 토큰과 기본 UI | 0 기반 | — | P17 | — | todo |
| [DEV-02](#dev-02) | 도메인 규칙 이식 | 0 기반 | — | P01 P02 P03 P04 P06 P07 P08 P09 P10 P14 P18 | — | todo |
| [DEV-03](#dev-03) | API 계약과 모의 어댑터 | 0 기반 | — | P12 P18 | DEV-02 | todo |
| [DEV-04](#dev-04) | 비로그인 첫 표지와 로그인 바 | 1 계정 | J1 J1b | P12 P16 | DEV-01 DEV-03 | todo |
| [DEV-05](#dev-05) | 로그인 | 1 계정 | J2 | P12 | DEV-04 | todo |
| [DEV-07](#dev-07) | 오늘의 색 | 2 창간·발행 | J3 | P03 P05 P17 | DEV-02 DEV-03 | todo |
| [DEV-08](#dev-08) | 사진과 얼굴 연출 | 2 창간·발행 | J4 J6 C6 | P11 P15 | DEV-01 | todo |
| [DEV-09](#dev-09) | 오늘 호 발행 | 2 창간·발행 | C6 C8b | P04 P01 | DEV-07 DEV-08 | todo |
| [DEV-06](#dev-06) | 창간 | 2 창간·발행 | J3 J4 J5 J6 J7 | P13 P14 P15 P04 | DEV-05 DEV-07 DEV-08 DEV-09 | todo |
| [DEV-10](#dev-10) | 표지 피드 | 3 읽기 | C1 C2 C7 | P01 P02 P16 P18 | DEV-09 | todo |
| [DEV-11](#dev-11) | 펼침면과 독자 한 줄 | 3 읽기 | C3 | P12 P18 | DEV-10 | todo |
| [DEV-12](#dev-12) | 가판대와 같은 색 | 3 읽기 | C4 C8 C8b | P01 P02 P18 | DEV-10 | todo |
| [DEV-13](#dev-13) | 서가와 구독 | 3 읽기 | C5 C5b | P04 P18 | DEV-10 | todo |
| [DEV-14](#dev-14) | 내 잡지와 반응 | 4 내 잡지 | M1 A4 | P18 | DEV-09 DEV-11 | todo |
| [DEV-15](#dev-15) | 월간 색 기록과 복원 | 4 내 잡지 | R1 R2 R3 R4 R5 | P06 P07 P03 | DEV-02 DEV-09 | todo |
| [DEV-16](#dev-16) | 친구 | 5 관계 | F1 F2 F3 | P12 | DEV-06 | todo |
| [DEV-17](#dev-17) | 트윈 | 5 관계 | T1 T2 T3 T4 T5 T6 T7 T8 T9 T10 T8private T8solo | P08 P09 P10 | DEV-16 DEV-08 | todo |
| [DEV-18](#dev-18) | 공유 | 5 관계 | A1 A3 A5 A7 | P01 P18 | DEV-11 DEV-17 | todo |
| [DEV-19](#dev-19) | 설정과 계정 | 6 계정 관리 | S1 S2 S3 S3off S4 S5 S5done S6 S6confirm S6done | P14 | DEV-05 DEV-06 | todo |
| [DEV-20](#dev-20) | 신고·차단·삭제 | 7 운영 | — | P01 P02 | DEV-11 DEV-16 | todo |

## DEV-01

**디자인 토큰과 기본 UI** · 0단계 기반 · 상태 `todo`

Expo 앱이 디자인 보드와 같은 값을 쓰게 한다. 토큰은 생성 파일 src/design/tokens.ts에서만 가져오고, 02 컴포넌트 보드의 버튼·칩·세그먼트·입력·글라스 캡슐·시트·알림을 공용 컴포넌트로 만든다.

**지킬 계약** P17 · **먼저 할 것** 없음

**앱(Expo)**

- src/design/tokens.ts는 `npm run dev:docs`가 harness.json에서 만든다. 손으로 고치지 않는다
- 공용 컴포넌트는 src/ui/에 두고 02 컴포넌트 보드의 치수(버튼 54px, 칩 38px, 누르는 영역 48px)를 따른다
- 기존 src/components/theme.ts의 이전 색(#252522, #DE6B4A 등)은 쓰지 않는다
- Cormorant Garamond·Instrument Sans·DM Mono·Nanum Myeongjo를 expo-font로 불러온다. 새 글꼴 패키지는 사용자 승인 후 추가

**서버 (초안)**

- 없음

**합격 기준**

- src/ui의 모든 누르는 요소가 48×48 이상
- 색·글꼴·간격 값이 tokens.ts 밖에 하드코딩되지 않음(오늘의 색 hex 포함)
- 누름 반응 scale 0.97·160ms, 움직임 줄이기 설정에서 즉시 바뀜
- 투명도 줄이기·고대비에서 글라스가 Paper 단색으로 바뀜

**추가할 테스트**

- `tests/ui/tokens.test.ts`

## DEV-02

**도메인 규칙 이식** · 0단계 기반 · 상태 `todo`

같은 색 방(P01), 하루 한 호(P04), 색 복원(P06·P07), 트윈(P08~P10), 제호 규칙(P14), 숫자 공개 범위(P18)를 Expo 앱의 순수 TypeScript 함수로 옮긴다. 기준 구현은 20260906-minimal-gallery/src/social-state.js와 앱 목업 app.js다.

**지킬 계약** P01, P02, P03, P04, P06, P07, P08, P09, P10, P14, P18 · **먼저 할 것** 없음

**앱(Expo)**

- src/domain/에 화면·네트워크와 무관한 순수 함수로 둔다
- 팔레트는 12색 key(sage…cobalt)를 쓴다. 기준 구현의 sage·butter·blue·rare 4색은 옮기지 않는다
- 기준 구현의 테스트 59개(`npm run test:rules`)를 12색 기준으로 옮기고, 같은 이름의 경우를 모두 통과시킨다

**서버 (초안)**

- 같은 규칙을 서버 서비스 함수로도 구현한다. 클라이언트 판정은 보안 경계가 아니다

**합격 기준**

- sameColorRoom: 오늘 발행 전 최신 3장, 나머지는 개수만 반환
- 내 발행·자정 이후·미성년자는 방 전체 공개, 확정·복원·트윈 게시로는 열리지 않음
- 하루 두 번째 발행은 거절, 개인 호수는 발행으로만 1 증가
- 복원은 이번 달 지난 빈 날짜만, 월 2회, 게시·호수에 영향 없음
- 트윈은 각자 후보 3개 중 겹치는 색 1개, 서로 다른 색 허용, 두 사람 게시 전 비공개, 공동 공개는 양측 동의

**추가할 테스트**

- `tests/domain/same-color.test.ts`
- `tests/domain/publish.test.ts`
- `tests/domain/record.test.ts`
- `tests/domain/twin.test.ts`
- `tests/domain/masthead.test.ts`

**사용자 결정이 필요한 것**

- 같은 색 미리보기 3장을 고르는 기준(현재 최신순 가정)
- 미성년자 판별 방법

## DEV-03

**API 계약과 모의 어댑터** · 0단계 기반 · 상태 `todo`

화면이 서버 완성을 기다리지 않도록, 앱이 쓰는 API를 하나의 인터페이스로 정의하고 메모리 모의 구현과 HTTP 구현을 바꿔 끼울 수 있게 한다.

**지킬 계약** P12, P18 · **먼저 할 것** DEV-02

**앱(Expo)**

- src/api/contract.ts에 기능별 요청·응답 타입을 둔다. 서버 OpenAPI(/api/docs)가 생기면 그 타입을 기준으로 맞춘다
- src/api/mock.ts는 앱 목업의 예시 데이터와 DEV-02 규칙으로 동작한다
- src/api/http.ts는 서버 호출. 어느 쪽을 쓸지는 환경 설정 하나로 바꾼다
- 공개 응답 타입에는 좋아요·구독자·독자 한 줄·스크랩 수 필드를 두지 않는다(소유자용 타입에만)

**서버 (초안)**

- 서버 PR konga22/Esel#4 병합 후 Swagger(/api/docs)를 계약의 정본으로 삼는다

**합격 기준**

- 모의 어댑터만으로 목업의 모든 흐름을 앱에서 끝까지 진행할 수 있음
- 공개 피드·표지 타입에 숫자 필드가 없음(타입 검사로 확인)
- 로그인 없이 쓰기 API를 부르면 401 계열 오류로 끝남

**추가할 테스트**

- `tests/api/mock-contract.test.ts`

## DEV-04

**비로그인 첫 표지와 로그인 바** · 1단계 계정 · 상태 `todo`

앱을 처음 열면 오늘의 표지와 안쪽 2쪽까지 읽을 수 있고, 640px 지나면 캡슐 자리에서 로그인 바가 올라온다.

**목업 화면**

[J1 비로그인 첫 표지](screens/j1-intro.jpg) · [J1b 스크롤 후 로그인 바](screens/j1b-login-bar.jpg)

**지킬 계약** P12, P16 · **먼저 할 것** DEV-01, DEV-03

**앱(Expo)**

- 제호 녹아들기와 작은 로고 값은 generator/scroll.mjs와 같게(위 48px, 아래 18px, 맨 위 360px, 크기 0.14)
- React Native에서는 Animated/Reanimated의 네이티브 드라이버로 transform·opacity만 움직인다(새 라이브러리는 승인 후)

**서버 (초안)**

- GET /api/today/cover: 비로그인용 오늘의 표지 1장과 안쪽 2쪽(숫자 없음)

**합격 기준**

- 비로그인에서 3번째 안쪽 지면 이후는 받지 않음(서버가 2쪽까지만 응답)
- 반응·구독·스크랩·만들기를 누르면 로그인 시트가 열림
- 작은 로고를 누르면 맨 위로 이동하고 제호로 녹아듦

**추가할 테스트**

- `tests/screens/intro.test.tsx`

## DEV-05

**로그인** · 1단계 계정 · 상태 `todo`

로그인 시트에서 계정으로 들어간다. 서버 계획상 이메일 가입·로그인과 refresh token 회전이 먼저이고, Apple·Google은 그 뒤다.

**목업 화면**

[J2 로그인 시트](screens/j2-login-sheet.jpg)

**지킬 계약** P12 · **먼저 할 것** DEV-04

**앱(Expo)**

- 토큰은 expo-secure-store 같은 보안 저장소에 둔다(AsyncStorage 금지). 패키지 추가는 승인 후
- 목업의 "목업이라 실제로 로그인하지 않아요" 문구는 옮기지 않는다

**서버 (초안)**

- POST /api/auth/email/signup
- POST /api/auth/email/login
- POST /api/auth/refresh (회전)
- POST /api/auth/logout
- 비밀번호와 refresh token 원문은 저장하지 않음

**합격 기준**

- 잘못된 비밀번호는 원인과 다시 할 방법을 한 줄로 알림
- refresh token 재사용 시 세션 전체 무효화
- 로그인 후 원래 하려던 동작(예: 좋아요)으로 돌아감

**추가할 테스트**

- `server/test/auth.e2e-spec.ts`
- `tests/api/auth-flow.test.ts`

**사용자 결정이 필요한 것**

- Apple·Google 로그인 도입 시점
- 이메일 인증 메일 발송 서비스

## DEV-07

**오늘의 색** · 2단계 창간·발행 · 상태 `todo`

서버가 서비스 날짜마다 12색 중 후보 3개를 정하고, 사용자는 하나를 고른다. 발행하면 그날 색은 바꿀 수 없다.

**목업 화면**

[J3 창간호의 색](screens/j3-color.jpg)

**지킬 계약** P03, P05, P17 · **먼저 할 것** DEV-02, DEV-03

**앱(Expo)**

- 색은 물감·스와치·띠·칩에만. 버튼이나 화면 바탕을 오늘의 색으로 칠하지 않음

**서버 (초안)**

- GET /api/today: serviceDate, 후보 3색, 내 선택, 오늘 발행 여부
- PUT /api/today/choice {colorId}: 발행 후 locked_at이 있으면 409
- SERVICE_TIME_ZONE(Asia/Seoul) 기준 자정에 날짜가 바뀜

**합격 기준**

- 후보 밖의 색은 고를 수 없음
- 색 고르기·확정만으로는 같은 색 방이 열리지 않음(P03)
- 발행 후 색 변경은 거절

**추가할 테스트**

- `server/test/today.e2e-spec.ts`

**사용자 결정이 필요한 것**

- 후보 3색을 고르는 방식과 희귀 팔레트 확률
- 시간대가 다른 사용자의 날짜 기준

## DEV-08

**사진과 얼굴 연출** · 2단계 창간·발행 · 상태 `todo`

사진을 찍거나 고르고, 얼굴 연출(그대로·물감 한 획·제호 뒤로·목 아래)을 기기 안에서 합성한 뒤 올린다.

**목업 화면**

[J4 촬영](screens/j4-shoot.jpg) · [J6 얼굴 연출](screens/j6-face.jpg) · [C6 오늘 호 만들기](screens/c6-make.jpg)

**지킬 계약** P11, P15 · **먼저 할 것** DEV-01

**앱(Expo)**

- 카메라·앨범은 기존 expo-camera·expo-image-picker를 쓴다
- 물감 합성과 자르기는 기기에서(expo-image-manipulator 등). 원본 얼굴 사진을 서버로 보내 가리지 않음
- 얼굴 위치를 못 찾으면 직접 위치를 정하게 하거나 목 아래를 권함
- "익명화된다"는 표현을 쓰지 않음

**서버 (초안)**

- POST /api/media: 업로드 준비(저장 키, 허용 형식·15MB 제한)
- POST /api/media/{id}/complete: 형식·크기·해상도 검증 후 READY
- 이미지 파일은 PostgreSQL에 넣지 않음

**합격 기준**

- 얼굴 위치를 정하지 않으면 발행 버튼 비활성(P11)
- "그대로"에서 제호가 얼굴을 덮지 않음(P15)
- 15MB 초과·이미지 아닌 파일은 이유와 함께 거절

**추가할 테스트**

- `tests/domain/face-layout.test.ts`
- `server/test/media.e2e-spec.ts`

**사용자 결정이 필요한 것**

- 이미지 저장소(S3 호환·로컬 등)
- 기기 얼굴 감지 방식

## DEV-09

**오늘 호 발행** · 2단계 창간·발행 · 상태 `todo`

오늘 호 만들기에서 표지 문구와 제호 색을 정해 발행한다. 발행은 하루 한 번이고, 성공하면 호수가 1 오르고 같은 색 방이 열린다.

**목업 화면**

[C6 오늘 호 만들기](screens/c6-make.jpg) · [C8b 같은 색 · 발행 후](screens/c8b-same-open.jpg)

**지킬 계약** P04, P01 · **먼저 할 것** DEV-07, DEV-08

**앱(Expo)**

- 발행 도장(0.96배 두 번)과 호수 넘김은 합 600ms 이내, 하루 한 번만
- 발행 직후 같은 색 열림(칩 칠하기 400ms, 표지 300ms·40ms 간격)
- 이미 발행한 날은 만들기 대신 오늘 호 보기

**서버 (초안)**

- POST /api/issues {mediaId, caption, faceMode, mastheadColor}: 하나의 트랜잭션에서 issue_count+1과 Issue 생성, 같은 날 두 번째는 409
- user_daily_choices.locked_at 설정

**합격 기준**

- 동시에 두 번 눌러도 호가 하나만 생김(DB unique)
- 실패하면 호수가 오르지 않고 다시 시도할 수 있음
- 발행 후 가판대의 내 색 칩 자물쇠가 사라짐

**추가할 테스트**

- `server/test/issues.e2e-spec.ts`
- `tests/screens/make.test.tsx`

## DEV-06

**창간** · 2단계 창간·발행 · 상태 `todo`

처음 쓰는 사람은 색 → 촬영 → 제호 → 얼굴 연출 → 창간호 순서로 내 잡지를 만든다. 창간호 발행은 DEV-09의 발행과 같은 규칙이다.

**목업 화면**

[J3 창간호의 색](screens/j3-color.jpg) · [J4 촬영](screens/j4-shoot.jpg) · [J5 제호 정하기](screens/j5-name.jpg) · [J6 얼굴 연출](screens/j6-face.jpg) · [J7 창간호](screens/j7-first-issue.jpg)

**지킬 계약** P13, P14, P15, P04 · **먼저 할 것** DEV-05, DEV-07, DEV-08, DEV-09

**앱(Expo)**

- 한 화면에 결정 하나, 각 단계에 뒤로가기
- 제호 입력은 소문자 a–z만 남기고 10자에서 멈춤, 글자 수에 맞춰 제호 크기를 줄임
- "쓸 수 있는 이름이에요"는 서버 중복 검사가 성공했을 때만 보여 줌

**서버 (초안)**

- GET /api/mastheads/{name}/availability
- POST /api/profile {masthead} — profiles.masthead unique로 동시 요청 방어

**합격 기준**

- 이미 있는 제호는 오류 문구와 함께 다음 버튼 비활성
- 창간 완료 시 개인 호수 Nº 001, 같은 색 방이 열림
- 중간에 앱을 닫았다 열면 마지막 단계부터 이어감

**추가할 테스트**

- `tests/screens/join.test.tsx`
- `server/test/profile.e2e-spec.ts`

**사용자 결정이 필요한 것**

- 닉네임 금칙어·예약어 목록
- 한글만 쓰는 사용자의 제호

## DEV-10

**표지 피드** · 3단계 읽기 · 상태 `todo`

피드의 첫 장만 표지이고 나머지는 안쪽 지면이다. 전체/구독 탭, 최신순에 가끔 인기 혼합, 반응 숫자는 보이지 않는다.

**목업 화면**

[C1 표지 피드](screens/c1-feed.jpg) · [C2 구독 탭 · 어두운 사진 표지](screens/c2-feed-subs.jpg) · [C7 피드 안쪽 지면 · 작은 로고](screens/c7-feed-inner.jpg)

**지킬 계약** P01, P02, P16, P18 · **먼저 할 것** DEV-09

**앱(Expo)**

- 이미 그린 지면은 다시 정렬하지 않고 뒤에만 붙임
- 어두운 사진 표지는 흰 제호와 위·아래 그림자
- 발행 전에는 내 색 표지를 피드에서 빼고 '발행하면 함께 펼쳐집니다' 안내를 한 번 넣음

**서버 (초안)**

- GET /api/feed?tab=all|subs&cursor=: 공개 권한 필터를 먼저 적용한 뒤 인기 혼합
- 응답에 좋아요 수 등 숫자 없음

**합격 기준**

- 발행 전 응답에 오늘 내 색 표지가 없음
- 미래 날짜·잘못된 날짜 지면은 오지 않음
- 30초 뒤 인기 혼합이 들어와도 이미 본 지면 순서가 바뀌지 않음

**추가할 테스트**

- `server/test/feed.e2e-spec.ts`
- `tests/screens/feed.test.tsx`

**사용자 결정이 필요한 것**

- 인기 혼합에 쓰는 내부 신호

## DEV-11

**펼침면과 독자 한 줄** · 3단계 읽기 · 상태 `todo`

표지를 펼치면 큰 제목, 사진 2장, 반응, 독자 한 줄이 나온다. 한 줄을 남길 수 있다.

**목업 화면**

[C3 펼침면](screens/c3-spread.jpg)

**지킬 계약** P12, P18 · **먼저 할 것** DEV-10

**앱(Expo)**

- 하트는 채울 때만 scale 0.85→1 200ms, 해제는 즉시
- 내 표지에서만 숫자와 '오늘 n명이 읽었어요 · 나에게만 보여요'

**서버 (초안)**

- GET /api/issues/{id}
- POST/DELETE /api/issues/{id}/like
- POST/DELETE /api/issues/{id}/scrap
- GET/POST /api/issues/{id}/lines

**합격 기준**

- 남의 표지 응답에 숫자 필드가 없음
- 잠긴 표지(P01)의 id로 직접 요청하면 403/404
- 한 줄은 60자 이내, 빈 줄 거절

**추가할 테스트**

- `server/test/reactions.e2e-spec.ts`

**사용자 결정이 필요한 것**

- 독자 한 줄 신고·삭제 정책

## DEV-12

**가판대와 같은 색** · 3단계 읽기 · 상태 `todo`

가판대에서 12색 칩으로 오늘의 표지를 거른다. 내 색은 발행 전 자물쇠이고, 누르면 최신 3장과 흐린 책등만 보인다.

**목업 화면**

[C4 가판대](screens/c4-stand.jpg) · [C8 같은 색 · 발행 전](screens/c8-same-locked.jpg) · [C8b 같은 색 · 발행 후](screens/c8b-same-open.jpg)

**지킬 계약** P01, P02, P18 · **먼저 할 것** DEV-10

**앱(Expo)**

- 흐린 책등은 서버가 준 개수로만 그린다(이름·사진을 받지 않음)
- 안내는 '발행하면 함께 펼쳐집니다'와 자정 안내만. 손실 문구·카운트다운 금지

**서버 (초안)**

- GET /api/stand?date=&color=: {access: open|preview|closed, covers, hiddenCount}
- preview일 때 4번째 이후 표지의 id·이름·이미지 URL을 응답에 넣지 않음

**합격 기준**

- 발행 전 내 색 요청에 표지 3장과 hiddenCount만 옴
- 발행·자정 이후에는 전체
- 다른 색·지난 날짜는 발행 전에도 전체

**추가할 테스트**

- `server/test/stand.e2e-spec.ts`
- `tests/screens/stand.test.tsx`

**사용자 결정이 필요한 것**

- 미리보기 3장 선정 기준

## DEV-13

**서가와 구독** · 3단계 읽기 · 상태 `todo`

남의 이름을 누르면 그 사람의 잡지(서가)가 열린다. 지난 호를 표지/책등으로 보고 구독할 수 있다.

**목업 화면**

[C5 서가 · 표지](screens/c5-shelf.jpg) · [C5b 서가 · 책등](screens/c5b-shelf-spines.jpg)

**지킬 계약** P04, P18 · **먼저 할 것** DEV-10

**앱(Expo)**

- 호수는 결호 없이 내려감
- 구독자 수는 보여 주지 않음

**서버 (초안)**

- GET /api/magazines/{masthead}: 지난 호 목록(공개분)
- POST/DELETE /api/magazines/{masthead}/subscription

**합격 기준**

- 서가 응답에 구독자 수가 없음
- 구독하면 피드 구독 탭에 나타남

**추가할 테스트**

- `server/test/magazines.e2e-spec.ts`

## DEV-14

**내 잡지와 반응** · 4단계 내 잡지 · 상태 `todo`

내 잡지에서 오늘 호, 지난 호, 메뉴(월간 색 기록·트윈·친구·설정)를 보고, 내 표지의 반응 수와 목록은 나만 본다.

**목업 화면**

[M1 내 잡지](screens/m1-me.jpg) · [A4 내 표지의 반응](screens/a4-reactions.jpg)

**지킬 계약** P18 · **먼저 할 것** DEV-09, DEV-11

**앱(Expo)**

- 오늘 발행 전이면 '오늘 호 만들기' 카드
- 반응 목록 화면에 '다른 사람에게는 좋아요 수가 표시되지 않아요'

**서버 (초안)**

- GET /api/me/magazine
- GET /api/me/issues/{id}/reactions (소유자만)

**합격 기준**

- 남의 issue id로 reactions를 부르면 403
- 소유자 응답에만 숫자가 있음

**추가할 테스트**

- `server/test/me.e2e-spec.ts`

## DEV-15

**월간 색 기록과 복원** · 4단계 내 잡지 · 상태 `todo`

한 달 달력에 사진으로 남긴 날(물감)과 색만 복원한 날(테두리 원)을 구분해 보여 주고, 지난 빈 날의 색을 한 달에 두 번 복원한다.

**목업 화면**

[R1 월간 색 기록](screens/r1-record.jpg) · [R2 날짜 기록](screens/r2-day.jpg) · [R3 놓친 날의 색](screens/r3-restore.jpg) · [R4 한 칸을 채웠어요](screens/r4-restored.jpg) · [R5 복원 후 달력](screens/r5-record-restored.jpg)

**지킬 계약** P06, P07, P03 · **먼저 할 것** DEV-02, DEV-09

**앱(Expo)**

- 복원한 날은 나만 보고, 게시·호수·같은 색 방에 영향이 없음을 화면에 적음

**서버 (초안)**

- GET /api/me/records?month=YYYY-MM
- POST /api/me/records/{date}/restore {colorId}: 이번 달 지난 빈 날짜만, 월 2회

**합격 기준**

- 오늘·미래·다른 달·이미 기록된 날 복원은 거절
- 세 번째 복원은 거절
- 복원으로 issue_count가 바뀌지 않음

**추가할 테스트**

- `server/test/records.e2e-spec.ts`

**사용자 결정이 필요한 것**

- 복원 후보 색(그날의 후보 3색 가정)

## DEV-16

**친구** · 5단계 관계 · 상태 `todo`

친구 목록, 받은 요청 수락·나중에, 아이디(제호)로 찾기. 친구여야 트윈에 초대할 수 있다.

**목업 화면**

[F1 나의 친구](screens/f1-friends.jpg) · [F2 친구 요청](screens/f2-friend-request.jpg) · [F3 친구가 되었어요](screens/f3-friend-added.jpg)

**지킬 계약** P12 · **먼저 할 것** DEV-06

**앱(Expo)**

- 친구 추가 완료는 화면(F3)으로 보여 주고 트윈 홈으로 이어짐

**서버 (초안)**

- GET /api/friends
- GET /api/friends/requests
- POST /api/friends/requests {masthead}
- POST /api/friends/requests/{id}/accept
- POST /api/friends/requests/{id}/decline

**합격 기준**

- 없는 아이디는 '찾지 못했어요'와 철자 확인 안내
- 같은 요청 중복 생성 불가

**추가할 테스트**

- `server/test/friends.e2e-spec.ts`

**사용자 결정이 필요한 것**

- 차단한 사람의 검색 노출

## DEV-17

**트윈** · 5단계 관계 · 상태 `todo`

친구와 같은 날 각자의 색으로 표지를 남긴다. 둘 다 게시해야 서로 열리고, 공동 표지 공개는 두 사람 모두 동의해야 한다.

**목업 화면**

[T1 트윈 시작](screens/t1-twin.jpg) · [T2 트윈 초대](screens/t2-invite.jpg) · [T3 나의 색 고르기](screens/t3-color.jpg) · [T4 나의 표지 준비](screens/t4-ready.jpg) · [T5 상대 게시 기다림](screens/t5-wait.jpg) · [T6 두 표지 공개](screens/t6-reveal.jpg) · [T7 공개 범위](screens/t7-visibility.jpg) · [T8 공동 공개 동의 대기](screens/t8-consent.jpg) · [T9 우리의 한 호](screens/t9-joint.jpg) · [T10 공동 발행 완료](screens/t10-published.jpg) · [T8private 둘만의 기록으로](screens/t8private.jpg) · [T8solo 내 표지만 공개](screens/t8solo.jpg)

**지킬 계약** P08, P09, P10 · **먼저 할 것** DEV-16, DEV-08

**앱(Expo)**

- 목업의 '시연' 버튼(수락·게시 도착·동의)은 옮기지 않는다. 실제로는 서버 상태 변화와 알림으로 넘어감
- 트윈 게시는 개인 오늘 호와 따로 세고 같은 색 방을 열지 않음(P09)

**서버 (초안)**

- POST /api/twins {friendId}
- POST /api/twins/{id}/accept
- PUT /api/twins/{id}/choice {colorId}
- POST /api/twins/{id}/posts (명시적 업로드)
- PUT /api/twins/{id}/visibility {private|solo|joint}
- POST /api/twins/{id}/consent
- POST /api/twins/{id}/publish

**합격 기준**

- 한 사람만 게시한 동안 상대 사진 URL이 응답에 없음
- joint 공개는 두 사람 consent 전에는 거절
- 상대 사진을 혼자 공개할 수 없음

**추가할 테스트**

- `server/test/twins.e2e-spec.ts`
- `tests/domain/twin.test.ts`

**사용자 결정이 필요한 것**

- 초대 만료 시간
- 트윈 진행 중 탈퇴한 경우

## DEV-18

**공유** · 5단계 관계 · 상태 `todo`

공개된 표지와 공동 공개된 트윈만 링크로 공유한다. 목업의 공유 앱 목록 대신 기기의 공유 메뉴를 연다.

**목업 화면**

[A1 내 표지 공유 시트](screens/a1-share-sheet.jpg) · [A3 공유 앱 선택](screens/a3-share-apps.jpg) · [A5 남의 표지 공유](screens/a5-share-other.jpg) · [A7 트윈 공유](screens/a7-share-twin.jpg)

**지킬 계약** P01, P18 · **먼저 할 것** DEV-11, DEV-17

**앱(Expo)**

- React Native Share로 기기 공유 메뉴를 연다. 목업의 '메시지·다른 앱' 목록은 옮기지 않음
- 링크 복사 후 상단 알림 '공유 링크를 복사했어요'

**서버 (초안)**

- POST /api/share-links {issueId|twinId}: 공개 권한이 있을 때만 링크 발급
- 링크를 연 사람에게도 같은 권한 검사(잠긴 표지·비공개 트윈은 열리지 않음)

**합격 기준**

- 발행 전 내 표지·비공개 트윈은 링크 발급 거절
- 링크 응답에 숫자·사용자 내부 ID 없음

**추가할 테스트**

- `server/test/share.e2e-spec.ts`

**사용자 결정이 필요한 것**

- 링크를 앱 미설치자가 열었을 때의 웹 화면

## DEV-19

**설정과 계정** · 6단계 계정 관리 · 상태 `todo`

프로필(제호·소개), 알림, 계정(이메일·로그아웃·탈퇴)을 관리한다.

**목업 화면**

[S1 나의 설정](screens/s1-settings.jpg) · [S2 프로필 편집](screens/s2-profile.jpg) · [S3 알림 설정](screens/s3-notifications.jpg) · [S3off 알림 꺼짐](screens/s3off-notifications.jpg) · [S4 계정 관리](screens/s4-account.jpg) · [S5 로그아웃 확인](screens/s5-logout.jpg) · [S5done 로그아웃 완료](screens/s5done.jpg) · [S6 탈퇴 전 확인](screens/s6-delete.jpg) · [S6confirm 탈퇴 마지막 확인](screens/s6confirm.jpg) · [S6done 탈퇴 완료](screens/s6done.jpg)

**지킬 계약** P14 · **먼저 할 것** DEV-05, DEV-06

**앱(Expo)**

- 프로필 이름은 제호 규칙(영문 소문자 2~10자)을 따른다. 피그마 S2의 '2–20자'는 쓰지 않음
- 프로필 저장은 화면 대신 상단 알림
- 목업의 '미리보기 처음으로'·'목업을 처음부터 다시 보기'는 옮기지 않음. 로그아웃·탈퇴 후에는 로그인 화면으로

**서버 (초안)**

- PATCH /api/me/profile {masthead?, bio}
- GET/PUT /api/me/notifications
- DELETE /api/me (탈퇴 확인 체크 후)

**합격 기준**

- 삭제 내용 확인 체크 전에는 다음 단계 비활성
- 탈퇴는 되돌릴 수 없음을 두 번 확인
- 알림을 끄면 하위 알림이 비활성

**추가할 테스트**

- `server/test/account.e2e-spec.ts`

**사용자 결정이 필요한 것**

- 제호 변경 허용 여부와 주기
- 탈퇴 시 공동 트윈의 상대 기록 처리
- 푸시 알림 서비스

## DEV-20

**신고·차단·삭제** · 7단계 운영 · 상태 `todo`

표지·독자 한 줄 신고, 사용자 차단, 내 호 삭제. 목업에는 아직 화면이 없다.

**지킬 계약** P01, P02 · **먼저 할 것** DEV-11, DEV-16

**앱(Expo)**

- 화면은 02 컴포넌트로 새로 그리고, 먼저 디자인 보드에 추가한 뒤 구현

**서버 (초안)**

- 삭제한 호는 공개 응답·공유 링크·이미지 URL에서 모두 사라짐
- 삭제 후 같은 색 방의 잠금 상태 재계산

**합격 기준**

- 차단한 사람의 표지·한 줄이 피드·가판대·서가에 나오지 않음

**추가할 테스트**

- 없음

**사용자 결정이 필요한 것**

- 신고 처리 주체와 기준
- 삭제 후 재발행 허용 여부

## 화면 등록부

| 화면 | 이름 | 목업 경로 | 참고 그림 | 피그마 노드 |
|---|---|---|---|---|
| J1 | 비로그인 첫 표지 | `intro` | [그림](screens/j1-intro.jpg) | 122:1180 |
| J1b | 스크롤 후 로그인 바 | `intro` | [그림](screens/j1b-login-bar.jpg) | 126:36 |
| J2 | 로그인 시트 | `intro` | [그림](screens/j2-login-sheet.jpg) | 122:1279 |
| J3 | 창간호의 색 | `join-color` | [그림](screens/j3-color.jpg) | 122:1323 |
| J4 | 촬영 | `join-shoot` | [그림](screens/j4-shoot.jpg) | 122:1378 |
| J5 | 제호 정하기 | `join-name` | [그림](screens/j5-name.jpg) | 122:1407 |
| J6 | 얼굴 연출 | `join-face` | [그림](screens/j6-face.jpg) | 122:1440 |
| J7 | 창간호 | `join-done` | [그림](screens/j7-first-issue.jpg) | 122:1481 |
| C1 | 표지 피드 | `feed` | [그림](screens/c1-feed.jpg) | 122:89 |
| C2 | 구독 탭 · 어두운 사진 표지 | `feed` | [그림](screens/c2-feed-subs.jpg) | 122:158 |
| C3 | 펼침면 | `spread` | [그림](screens/c3-spread.jpg) | 122:228 |
| C4 | 가판대 | `stand` | [그림](screens/c4-stand.jpg) | 122:309 |
| C5 | 서가 · 표지 | `shelf` | [그림](screens/c5-shelf.jpg) | 122:461 |
| C5b | 서가 · 책등 | `shelf` | [그림](screens/c5b-shelf-spines.jpg) | 122:1016 |
| C6 | 오늘 호 만들기 | `make` | [그림](screens/c6-make.jpg) | 122:753 |
| C7 | 피드 안쪽 지면 · 작은 로고 | `feed` | [그림](screens/c7-feed-inner.jpg) | 122:811 |
| C8 | 같은 색 · 발행 전 | `same` | [그림](screens/c8-same-locked.jpg) | 122:581 |
| C8b | 같은 색 · 발행 후 | `same` | [그림](screens/c8b-same-open.jpg) | — |
| M1 | 내 잡지 | `me` | [그림](screens/m1-me.jpg) | 142:72 |
| A4 | 내 표지의 반응 | `reactions` | [그림](screens/a4-reactions.jpg) | 144:395 |
| R1 | 월간 색 기록 | `record` | [그림](screens/r1-record.jpg) | 142:104 |
| R2 | 날짜 기록 | `day` | [그림](screens/r2-day.jpg) | 142:228 |
| R3 | 놓친 날의 색 | `restore` | [그림](screens/r3-restore.jpg) | 142:245 |
| R4 | 한 칸을 채웠어요 | `restored` | [그림](screens/r4-restored.jpg) | 142:270 |
| R5 | 복원 후 달력 | `record` | [그림](screens/r5-record-restored.jpg) | 148:291 |
| F1 | 나의 친구 | `friends` | [그림](screens/f1-friends.jpg) | 148:227 |
| F2 | 친구 요청 | `friend` | [그림](screens/f2-friend-request.jpg) | 148:261 |
| F3 | 친구가 되었어요 | `friend-added` | [그림](screens/f3-friend-added.jpg) | 148:277 |
| T1 | 트윈 시작 | `twin` | [그림](screens/t1-twin.jpg) | 143:93 |
| T2 | 트윈 초대 | `twin-invite` | [그림](screens/t2-invite.jpg) | 143:116 |
| T3 | 나의 색 고르기 | `twin-color` | [그림](screens/t3-color.jpg) | 143:133 |
| T4 | 나의 표지 준비 | `twin-ready` | [그림](screens/t4-ready.jpg) | 143:158 |
| T5 | 상대 게시 기다림 | `twin-wait` | [그림](screens/t5-wait.jpg) | 143:173 |
| T6 | 두 표지 공개 | `twin-reveal` | [그림](screens/t6-reveal.jpg) | 143:190 |
| T7 | 공개 범위 | `twin-vis` | [그림](screens/t7-visibility.jpg) | 143:208 |
| T8 | 공동 공개 동의 대기 | `twin-consent` | [그림](screens/t8-consent.jpg) | 143:238 |
| T9 | 우리의 한 호 | `twin-joint` | [그림](screens/t9-joint.jpg) | 143:256 |
| T10 | 공동 발행 완료 | `twin-done` | [그림](screens/t10-published.jpg) | 143:272 |
| T8private | 둘만의 기록으로 | `twin-done` | [그림](screens/t8private.jpg) | 143:288 |
| T8solo | 내 표지만 공개 | `twin-done` | [그림](screens/t8solo.jpg) | 143:301 |
| S1 | 나의 설정 | `settings` | [그림](screens/s1-settings.jpg) | 144:128 |
| S2 | 프로필 편집 | `profile` | [그림](screens/s2-profile.jpg) | 144:159 |
| S3 | 알림 설정 | `notifications` | [그림](screens/s3-notifications.jpg) | 144:194 |
| S3off | 알림 꺼짐 | `notifications` | [그림](screens/s3off-notifications.jpg) | 144:213 |
| S4 | 계정 관리 | `account` | [그림](screens/s4-account.jpg) | 144:232 |
| S5 | 로그아웃 확인 | `logout` | [그림](screens/s5-logout.jpg) | 144:257 |
| S5done | 로그아웃 완료 | `goodbye` | [그림](screens/s5done.jpg) | 144:308 |
| S6 | 탈퇴 전 확인 | `delete` | [그림](screens/s6-delete.jpg) | 144:272 |
| S6confirm | 탈퇴 마지막 확인 | `delete-final` | [그림](screens/s6confirm.jpg) | 144:293 |
| S6done | 탈퇴 완료 | `goodbye` | [그림](screens/s6done.jpg) | 144:322 |
| A1 | 내 표지 공유 시트 | `me` | [그림](screens/a1-share-sheet.jpg) | 144:336 |
| A3 | 공유 앱 선택 | `me` | [그림](screens/a3-share-apps.jpg) | 144:370 |
| A5 | 남의 표지 공유 | `spread` | [그림](screens/a5-share-other.jpg) | 147:245 |
| A7 | 트윈 공유 | `twin-done` | [그림](screens/a7-share-twin.jpg) | 147:272 |

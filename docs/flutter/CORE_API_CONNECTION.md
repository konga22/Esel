# Flutter 핵심 서버 API 연결

## 이번 작업 범위

서버 모드와 로컬 시연은 같은 화면·화면 전환을 쓴다. `ESEL_API_MODE`로 ServiceLocator에서 소스를 선택한다. 별도 DeviceHomeScreen·Server*Screen은 제거했으며 기존 HTTP 클라이언트·토큰·서버 소스는 보존했다.

| 기능 | 앱에서 확인하는 곳 | 연결 API |
|---|---|---|
| DEV-05 로그인·가입 | 계정 · 로그인 | 이메일 가입·로그인, 토큰 갱신·로그아웃(기존 구현 유지·실제 서버 검증) |
| DEV-06 사인·프로필 | 첫 캔버스 이름 단계 | 사인 중복 확인, 프로필 생성·세션 재조회 |
| DEV-07 오늘의 색 | 스케치북 → 오늘의 색 | GET /today, PUT /today/choice |
| DEV-11 표지·반응·한 줄 | 스케치북 사진 → 자세히 보기 | GET /issues/:id, 좋아요·스크랩 POST/DELETE, 한 줄 GET/POST |
| DEV-13 스케치북·구독 | 팔레트 사진/홈 사인 → 스케치북 | GET /magazines/:masthead, 구독 POST/DELETE |
| DEV-14 내 스케치북·반응 | 스케치북 | GET /me/magazine, GET /me/issues/:id/reactions |
| DEV-15 색 기록·복원 | 스케치북 → 색 달력 | GET /me/records?month=YYYY-MM, POST /me/records/:date/restore |

데이터는 각 기능의 domain 모델·data 소스·presentation 화면으로 나눈다. 기존 AppHttpClient의 토큰·오류 처리를 재사용한다. 공개 목록은 서버가 준 항목만 표시하며 잠긴 표지를 기기 자료에서 보충하지 않는다. 반응 숫자는 소유자용 API 화면에만 있고, 공개 모델에는 숫자를 두지 않는다. 목록과 독자 한 줄은 cursor로 다음 페이지를 받는다.

실패한 요청은 오류·재시도를 표시한다. 서버 응답 전 좋아요·구독·복원을 완료했다고 표시하지 않는다. 댓글 실패 시 입력을 유지한다. 계정이 바뀌면 열린 서버 상세 화면을 닫고 새 계정 키로 오늘 화면을 다시 만든다.

DEV-25(미술 도구 용어·260×60의 4칸 캡슐), DEV-12 공통 팔레트, DEV-13 세로 스케치북과 DEV-24 로컬 착용 정보를 반영했다. 서버 API 경로·권한·DB migration은 바꾸지 않는다. 서버 errors.ts의 화면 문구만 새 용어로 맞춘다.

## 동일 화면과 데이터 출처

- `TodayController`: 로컬 기록 또는 TodayRemoteSource/MagazineRemoteSource. 프로필을 만들기 전에는 오늘의 색만 조회하며 스케치북 404가 가입을 막지 않는다.
- `StandController → StandSource`: 공통 팔레트. 추천은 미구독자의 최신 공개 표지, 구독은 구독한 사람만, 색상은 기존 잠금 규칙을 적용한다. 로컬 비후보 색 순서는 고정 물감 순서이며 실제 선택량이라고 설명하지 않는다.
- `MagazineController → MagazineSource`: 본인/타인 모두 ShelfScreen. 원격은 서버 공개 항목과 cursor만 사용한다.
- `ReactionsController`: 공통 IssueBottomSheet의 상세·반응·한 줄을 로컬/원격으로 처리한다. 댓글 저장에 성공한 뒤 목록 조회만 실패하면 재시도는 조회만 한다.
- `RecordsSource`: 같은 MonthlyRecordScreen에서 월 이동·빈칸 복원. 로컬 복원도 계정별 저장·월 2회·서울 날짜·그날 후보를 검사한다.
- `CoverDraft.garments`는 선택 필드다. 기존 저장본에는 빈 목록을 적용한다. 옷 종류·이름(선택, 40자)·메모·오늘의 색 표시·원본 사진 비율 좌표를 저장한다. 사진 교체 시 태그 위치를 지우고, 옷 재사용 시 동일 ID를 쓰되 위치·오늘의 색은 다시 지정한다. 내 옷은 계정별로 분리되며 탈퇴 시 함께 지운다. 가격·상품 URL 필드는 없다.

## 서버 담당자와 남은 연결 작업

팔레트 추천/구독/색 순서와 garments는 `docs/dev/features.json`의 **검토안**이며 아직 `server/api-contract.json`의 실행 가능한 API가 아니다. 주소를 앱에 하드코딩하거나 migration을 추가하지 않았다. 서버 담당자가 경로·DTO·소유권·공개 필터·cursor·오류를 합의한 뒤 원격 소스를 구현해야 한다.

실제 사진 URL과 인증된 업로드, 새 캔버스 올리기, 얼굴 연출의 복합 효과 DTO, 피드, 팔레트, 착용 정보 동기화가 남아 있다. 서버 사진은 ‘사진 제공 준비 중’, 원격 미구현 기능은 오류로 표시한다. 서버에서 올리기를 누르면 성공 처리하지 않고 준비 중 안내를 표시한다. 친구/트윈의 예시 화면은 서버 모드 진입에서 제외한다. 서버 실패 시 로컬 전환은 없다.

## 실행 방법

Flutter 3.44.0 / Dart 3.12.0, Node는 저장소 기준 버전을 사용한다. 새 Flutter 패키지는 추가하지 않았다. 저장소 루트에서 Docker Desktop의 Linux 엔진을 시작한 뒤:

```sh
docker compose up -d --build api
cd flutter_app
flutter pub get
flutter run -d <장치ID> --dart-define=ESEL_API_MODE=server --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
```

위 주소는 Windows/macOS의 Android 에뮬레이터에서 쓴다. USB Android 실기기는 `adb reverse tcp:3000 tcp:3000` 후 주소를 `http://127.0.0.1:3000/api`로 바꾼다. macOS의 iOS 시뮬레이터는 호스트 주소와 Xcode 환경을 따로 확인해야 하며 이번 검수에서는 실행하지 않았다. 네트워크 오류가 나면 Docker·주소를 확인하고 앱의 재시도 버튼을 누른다. 기존 로컬 발표 시연은 `--dart-define=ESEL_API_MODE=mock`을 명시한다.

처음 설치한 서버 DB에는 다른 사람의 표지가 없을 수 있다. 로그인/가입 후 첫 캔버스 흐름에서 사인을 저장하고 스케치북에서 오늘의 색을 고른다. 스케치북의 원격 기록과 만들기의 기기 초안은 구분한다. 사진이 있는 기기 초안을 서버 발행본으로 가장하지 않는다.

## 남은 계약과 화면 차이

- **사진·발행:** 현재 IssueMediaDto에 사진 URL이 없고 앱용 업로드 주소도 미확정이다. 사진은 ‘사진 제공 준비 중’으로 표시한다. 미디어 ID로 경로나 URL을 추측하지 않는다. 표지 메타데이터·반응·한 줄 조회는 가능하지만 사진 표시·새 서버 발행을 완성한 상태는 아니다.
- **과거 후보 색:** 특정 지난 날짜 후보를 조회하는 API는 아직 없다. 복원창은 12색을 선택지로 보여주고 그날 후보인지 서버가 검사한다. 후보 밖 색·마감·월 2회 초과는 오류로 안내한다. 임시 날짜 배정 알고리즘을 앱에서 서버 정답처럼 사용하지 않는다. 정확히 3색만 보여주려면 서버 담당자와 조회 계약을 합의해야 한다.
- **사인·표시:** 공통 스케치북의 원격 소스는 사인을 탐색 키로 쓴다. 공개 DTO에 없는 내부 사용자 ID를 만들지 않는다. 로컬 공개 항목에는 기존 ownerId를 쓴다.
- **시각 검수:** 기존 토큰·글꼴과 앱 화면을 사용하되, 사진 제공 전 단계의 표지 목록은 색·날짜·문구로 표시한다. 디자인 캔버스와 실제 사진 격자를 완전히 맞춘 화면이라고 설명하지 않는다.

## 검증과 재현

일반 검사(앱 폴더):

```sh
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --debug --target-platform android-x64 --dart-define=ESEL_API_MODE=server
```

`core_api_test.dart`는 loopback HTTP 서버로 토큰 헤더·주소·body·cursor·404·연결 실패를 검사한다. `core_api_widgets_test.dart`는 가짜 HTTP 응답으로 버튼·재시도·본인 숫자·댓글 실패·좁은 화면/글자 확대를 검사한다. 실제 Docker 검증과 구분한다.

실제 Docker API 검증용 준비 도구는 **새 테스트 계정 두 개와 조회용 메타데이터 표지 한 개만 추가**한다. 업로드·발행 API가 완성된 것으로 꾸미지 않으며 기존 사용자·DB·볼륨을 삭제하지 않는다. 아래 경로 파일에는 임시 테스트 비밀번호가 있으므로 커밋하거나 채팅에 붙이지 않는다. 일반 테스트·CI는 이 연결 검사를 자동 실행하지 않는다.

Windows PowerShell, 저장소 루트:

```powershell
$env:ESEL_LIVE_FIXTURE = node flutter_app/tool/prepare_core_api_fixture.mjs
cd flutter_app
flutter test --no-pub test/features/server/core_api_live_test.dart
```

macOS 터미널, 저장소 루트:

```sh
export ESEL_LIVE_FIXTURE="$(node flutter_app/tool/prepare_core_api_fixture.mjs)"
cd flutter_app
flutter test --no-pub test/features/server/core_api_live_test.dart
```

이 검사는 실제 서버의 로그인·사인·프로필·오늘 색 저장·표지 조회·좋아요·스크랩·한 줄·구독·본인 반응·월간 복원과 로그아웃 후 재로그인을 확인한다. 복원은 이번 달 지난 빈 날이 있고 잔여 횟수가 있을 때만 시도하므로 매월 1일 등에는 복원 검증이 제한된다. 테스트 기록은 로컬 DB에 남는다. 재시작 보존 검사는 API 컨테이너를 재시작한 뒤 같은 fixture로 다시 실행한다.

검증 결과와 미확인 범위는 [콘텐츠 검증 기록의 핵심 API 절](CONTENT_VALIDATION.md#핵심-서버-api-연결-검증-2026-10-18)에 구분한다. 실기기 화면·macOS/iOS 직접 검수는 별도다.

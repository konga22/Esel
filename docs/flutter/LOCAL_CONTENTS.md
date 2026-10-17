# 콘텐츠의 로컬 동작

주간 드레스코드·같은 옷, 다른 코디의 동작과 서버 인계 검토안이다. 일·주·월 표지 특집과 최신 공개 목록 규칙은 [기간 특집 및 보완 안내](PERIOD_COLLECTIONS.md)를 함께 따른다. 월·연간 베스트·공개 인기 순위·개인 스타일 점수 결산은 제외한다. 기존 월간 색 기록·친구·트윈·서버 코드는 유지한다.

## 동작과 경계

- 서울 월요일 00:00 이상~다음 월요일 00:00 미만. 로컬 주제는 주별로 ‘가방으로 포인트’·‘겹쳐 입기’·‘데님’·‘비 오는 날’을 순환한다. 서버가 주제를 배정하는 기능은 아니다.
- 가판대 / 내 잡지 → 이번 주의 착장. 주제·기간·방법·내 상태·참여 표지를 한 스크롤 화면에서 본다. 새 하단 탭이나 발행 시스템은 없다.
- 오늘 미발행: 참여 → 기존 오늘 호 편집(사진·문구·얼굴) → 발행과 함께 참여 저장. 오늘 발행: 오늘 호에 연결만 한다. 하루 한 호와 후보 3색 검증은 TodayController를 거친다.
- 한 호는 한 참여 유형에 연결. 같은 요청은 중복 생성하지 않는다. 다른 유형/비교 대상으로 바꾸려면 내 참여에서 해제 후 다시 선택한다. 한 주에 날짜가 다른 여러 호로 참여 가능하다. 해제는 발행본·호수·방 잠금을 바꾸지 않는다.
- 같은 옷: 본인 ownerId의 지난 날짜 발행본만 선택. 사용자가 같은 옷인지 확인한다. 타인·당일 표지·초안은 선택 불가. 현재/이전 표지의 ID를 연결하고 사진을 복제하지 않는다. 비교는 두 날짜·표지·문구로 한다. AI 판별/옷장/점수는 없다.
- 발행/연결 순간 기간을 다시 검증한다. 마감 후 초안을 발행하면 오류를 표시하고 초안을 남긴다. 편집 화면에서 참여만 해제해 일반 호로 발행할 수 있다. 이전 참여는 읽기/해제 가능, 과거 호를 새 주제에 소급 참여시키지 않는다.
- 연결된 과거 호를 지우면 해당 참여와 연결 정보를 해제하고 오늘 발행본은 보존한다. 계정 탈퇴는 기존 계정 정리 흐름을 이용한다. 계정 전환 시 진행 중 연결과 화면 데이터를 분리한다.
- 내 참여는 계정별로 분리한다. 참여 목록은 이 기기의 다른 계정이 발행·참여한 기록도 기존 공개 규칙을 먼저 적용해 반환한다. 잠긴 표지는 이름·사진·ID까지 제외한다. 원격 커뮤니티 목록이나 서버 공개 권한 검증을 대신하지 않는다.
- 저장은 기존 LocalLibrary의 직렬·원자적 저장을 재사용한다. 선택 필드 `challengeId`, `previousIssueId`가 없는 version 1 기록도 읽는다. 기존 저장소 초기화는 하지 않는다. 사진 누락 표시는 기존 CoverPreview의 오류 처리를 이용한다.

## 실행

Flutter **3.44.0 / Dart 3.12.0**, 새 라이브러리 없음. 기존 SDK·PATH 설정은 변경하지 않는다.

Windows PowerShell, 저장소 루트:

```powershell
cd flutter_app
flutter --version
flutter pub get
flutter devices
flutter run -d <장치ID> --dart-define=ESEL_API_MODE=mock
```

Windows의 플러그인 symlink 준비에는 개발자 모드 또는 적절한 권한이 필요할 수 있다. `flutter pub get`을 완료한 뒤 실행한다. SDK 위치는 각 개발 환경에 맞추고 개인 설치 경로를 공유 설정에 넣지 않는다.

macOS 터미널에서도 flutter_app에서 같은 flutter 명령을 쓴다. SDK를 따로 둔 경우 해당 절대 경로의 `bin/flutter`를 사용한다. Android SDK/JDK와 휴대폰 USB 디버깅 필요. iOS는 macOS·Xcode·서명이 필요하다. macOS/iOS 실행 검증 상태는 검증 문서를 참고한다.

Docker·DB·OAuth·.env 불필요. 로컬 가입/로그인은 기기 내 시연 계정이며 실제 서버 인증이 아니다. 앱 완전 종료 후 같은 계정으로 다시 로그인한다. 웹은 기존대로 메모리 저장만 하므로 영속성 시연은 Android에서 한다.

## 서버 담당자 검토안 (미합의, 확정 API 아님)

기존 `server/api-contract.json`이 경로·권한·오류의 정본이고 DTO/Swagger가 데이터 모양의 정본이다. 이번 작업에서는 서버 파일/엔드포인트/migration을 추가하지 않는다. `ChallengeSource`는 앱 데이터 계층의 교체 지점이며 서비스 로케이터의 기존 모드 선택을 이용한다. RemoteChallengeSource는 명시적 미구현 오류로 끝나며 로컬로 자동 전환하지 않는다.

합의할 요청/응답 후보:

| 작업 | 데이터·권한·실패 합의 |
|---|---|
| 주제 조회 | id, type(weekly/restyle), title/topic, startsAt/endsAt(서울 기준 경계), status. 로컬 주제 ID/교대 규칙은 서버 ID/운영 주제로 교체해야 함 |
| 내 참여 조회 | 인증 주체로 ownerId 결정, issueId, challengeId, previousIssueId?, createdAt. 본인 전용·페이지네이션. 클라이언트 ownerId를 권한으로 신뢰하지 않음 |
| 오늘 호 연결 | challengeId, issueId, previousIssueId?, idempotency. 소유권·발행됨·오늘 날짜·기간·중복을 트랜잭션에서 검사. 하루 한 호는 기존 발행 계약 유지 |
| 해제/삭제 | 연결만 해제, 호 삭제와 구분. 비교 대상 삭제 시 연결 무효화 정책 및 기존 참여 표시 정책 합의 |
| 공개 참여 조회 (후속) | P01·미성년·차단·삭제 등 기존 공개 필터를 **그룹화/페이지네이션 전에** 적용. 숨긴 ID/사진/반응 수/이미지 URL까지 제한. 이번 로컬 목록과 구분 |
| 오류 의미 후보 | 인증 만료, 소유권 없음, 기간 종료, 다른 참여 충돌, 이전 호 없음/삭제됨, 저장 실패. HTTP 상태·오류 코드·문구는 기존 계약 체계에 맞춰 서버 담당자가 확정 |

남은 실제 연동 작업: 계약/DTO·Swagger·migration 합의와 서버 구현, 실제 인증 주체 연결, 미디어 업로드와 권한 URL, 발행-참여의 원자성, 네트워크 재시도/중복 방지, 서버 시각 기준, 동기화·오프라인 충돌·로컬 기록 이전 정책, 공개 목록 보안, 서버/앱 계약 E2E. URL 변경만으로 완료되지 않는다.

현재 정본과 맞출 세부 사항: 인증은 Bearer access token, 비노출 자원은 404 NOT_FOUND를 403 FORBIDDEN보다 먼저 적용한다. 401 AUTH_REQUIRED/TOKEN_EXPIRED, 400 VALIDATION, 409 ISSUE_ALREADY_PUBLISHED, 422 COLOR_NOT_CANDIDATE 등 기존 의미는 재사용한다. 기간 종료/연결 충돌 전용 코드의 추가 여부는 미합의다. 오류 본문은 기존 `{error:{code,message,hint,details?}}` 구조와 DTO 문서를 따른다. 새 목록 DTO에는 `publicForbiddenFields`의 likeCount/lineCount/scrapCount/subscriberCount/readerCount/viewCount/rank/score/popularity를 넣지 않는다. 메서드별 성공 코드와 cursor 형식도 계약 등록 시 기존 API 규칙에 맞춘다.

검증 및 실제 조작 기록은 [콘텐츠 검증 기록](CONTENT_VALIDATION.md)에 남긴다. 기능 목록의 doing은 서버까지 전체 완료한 뜻이 아니다.

# 중간발표용 Flutter 로컬 실행

기준일: 2026-10-14. 범위는 Docker 연결 전 앱 기본 동작이다.
기준: AGENTS.md → docs/ESEL_HARNESS.md → harness.json → docs/dev.
DEV-03의 기존 모의 어댑터를 명시적으로 선택하며 서버 실패 시 자동 전환하지 않는다.

## 팀원 Android 휴대폰 실행

Flutter SDK·Android SDK를 준비하고 휴대폰 USB 디버깅을 켠다. USB 연결 후 휴대폰에서 디버깅을 허용한다.
flutter_app 폴더에서 실행한다.

```powershell
flutter pub get
flutter devices
flutter run -d <휴대폰장치ID> --dart-define=ESEL_API_MODE=mock
```

저장소 루트에서 `scripts/start-demo.ps1 -DeviceId <휴대폰장치ID>`로도 실행할 수 있다.
Docker·DB·.env·OAuth 설정은 필요 없다.
설치 파일은 `flutter build apk --debug --dart-define=ESEL_API_MODE=mock`으로 만든다.
경로: flutter_app/build/app/outputs/flutter-apk/app-debug.apk.
Windows에서 symlink 오류가 나면 Windows 개발자 모드 또는 관리자 터미널에서 패키지를 준비한다.
iPhone은 macOS/Xcode·서명이 필요하며 이번 환경에서 검증하지 않았다.

## 웹 브라우저로 볼 때

```powershell
flutter run -d chrome --dart-define=ESEL_API_MODE=mock
flutter build web --dart-define=ESEL_API_MODE=mock
```

- `--dart-define=ESEL_API_MODE=mock`을 빼면 서버 모드의 옛 기기 보관함 화면이 뜬다. 디자인 화면을 보려면 휴대폰·웹 모두 이 옵션을 붙인다. IDE 실행 버튼은 이 옵션을 따로 설정해야 한다.
- 웹은 기기 파일을 쓸 수 없어 사진·초안·발행 기록을 브라우저 메모리에만 둔다. 새로고침하면 처음부터 다시 한다.
- 넓은 창에서는 휴대폰 폭(최대 430)으로 가운데에 보인다.
- 한글 본문 글꼴은 브라우저가 처음 열 때 인터넷에서 받는다(Noto Sans KR). 인터넷이 없으면 한글이 네모로 보일 수 있다.

## 영상 흐름

1. 첫 Esel 표지 → 로그인 → 이메일로 시작하기.
2. 개인 비밀번호 대신 시연용 주소·비밀번호 사용. 예: presentation@esel.local / eseldemo2026.
3. 로그인 시트의 ‘로컬 시연’ 안내로 실제 인증이 아님을 설명.
4. 만들기 → 후보 카멜·라일락·올리브 중 하나 선택.
5. 사진 선택 또는 촬영 → 표지 문구(40자 이내).
6. 얼굴 연출 4종·제호 색 변경, 직접 위치·크기·자르기 영역 조정 → 얼굴 확인.
7. 초안 저장 → 닫았다 다시 열기 → 오늘 호 발행.
8. 내 잡지 → 서가 전체 보기 → 표지/책등 전환 → 표지를 눌러 다시 펼치기.
9. 설정 → 계정 관리 → 로그아웃.

첫 발행은 Nº 001, 하루 한 호다. 반복 촬영은 다른 시연용 이메일로 로그인하면 별도 잡지로 진행한다.
앱 데이터 삭제로 재촬영하지 않는다. 앱을 완전히 종료하면 다시 로그인한다.
동일 이메일로 로그인하면 기기의 초안과 발행 기록이 유지된다. 원본 앨범 사진은 변경하지 않는다.

## 범위·보존·검증

- 기존 로그인·피드·3개 캡슐·만들기·내 잡지·서가를 연결하고 기존 편집기와 로컬 저장 코드를 재사용했다.
- 하단 캡슐은 디자인의 메뉴 캡슐(196×60, 물감·+·아바타)이다. 사진이 깔린 피드에서는 글라스, 흰 화면 탭에서는 단색 + 그림자다.
- 디자인 글꼴(Cormorant Garamond·Nanum Myeongjo·Instrument Sans·DM Mono, SIL OFL)을 `flutter_app/assets/fonts`에 넣었다. 한글 본문은 기기 기본 한글 글꼴을 쓴다.
- 로컬 발행은 기기 저장이며 업로드·동기화되지 않는다. 예시 피드 인물·통계는 하네스의 견본이다.
- 이번 범위 밖 친구·트윈·반응 수 메뉴는 로컬 내 잡지에서 숨겼으며 코드는 보존했다.
- 창간 전체 J3~J7, 실제 인증/소셜 인증·공유 링크·서버 권한은 이번 완료 범위 밖이다.
- Flutter의 실제 인증/HTTP 어댑터는 보존했다. 로컬 옵션을 주지 않으면 기존 서버 모드가 기본이다.
- 서버/Docker 코드는 별도 서버 PR #4·#7에서 검토한다. 이 Flutter PR에는 합치지 않으며 기존 로컬 서버 작업도 보존한다.
- 로컬 시연 토큰은 메모리 저장소만 사용해 기존 서버 토큰과 섞지 않는다.
- Flutter 테스트 47개 통과(발행 완료 화면의 Android 뒤로가기 포함), 정적 검사 오류 없음.
- 기준 규칙 테스트 59개 통과. check:harness는 기존 문서의 다른 PC 절대 경로 참조 때문에 실패했다. 보관 자료를 수정하지 않아 이 문제는 남아 있으며 Flutter 시연 실행과는 별개다.
- Pixel 9/Android 17: 이메일 로그인, 촬영·앨범 선택, 문구·얼굴 편집, 초안 저장·재편집, 이미지 공유창(외부 전송 안 함), 발행·내 잡지·서가·표지 상세 확인.
- 강제 종료/재실행 후 동일 이메일 로그인 → Nº 001·문구·연출 유지 및 당일 추가 발행 거절 확인.
- 저장 실패 롤백·저장본 복구·연속 호수·사용자별 격리는 자동 테스트로 확인.
- 물리 Android 휴대폰은 아직 연결하지 않았다. 팀원 기기에서 권한·촬영·공유를 확인해야 한다.
- Docker/DB E2E·iOS 검증은 포함하지 않는다. DEV-01~20 전체 완료를 뜻하지 않는다.

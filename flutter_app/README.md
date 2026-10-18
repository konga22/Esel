# Esel Flutter

서버 없이 실행하는 중간발표 시연 앱입니다. 실행 방법과 시연 범위는 [중간발표 안내](../docs/flutter/MIDTERM_DEMO.md)를 따릅니다.

```powershell
flutter pub get
flutter devices
flutter run -d <장치ID> --dart-define=ESEL_API_MODE=mock
```

사진 편집·초안 저장·로컬 올리기·팔레트·세로 스케치북·착용 정보 태그/옷 재사용을 지원합니다. 로컬 로그인은 실제 계정 인증이 아니며 서버로 업로드하지 않습니다.
로컬과 서버는 동일한 화면을 쓰며 데이터 출처만 바꿉니다. 캡슐은 바뀌는 칸·만들기·스케치북 3칸, 198×60입니다. 실제 API 어댑터는 보존되어 있고 로컬 옵션을 생략하면 서버 모드로 실행합니다. 현재 서버 모드는 이메일 회원가입·로그인·토큰 갱신·로그아웃, 사인 중복 확인·프로필 생성, 오늘 후보·선택, 표지 조회·좋아요·스크랩·독자 한 줄, 스케치북·구독, 내 스케치북·반응, 월별 색 기록·복원 API를 호출합니다. 사진 URL·모바일 업로드·새 서버 발행·피드·팔레트 추천은 아직 연결하지 않았습니다. 구현 범위·화면 진입·실제 Docker 검증 방법은 [핵심 API 연결 안내](../docs/flutter/CORE_API_CONNECTION.md)를 참고하세요.

## 직접 구축 서버 연결

먼저 저장소 루트에서 서버를 실행합니다.

```powershell
docker compose up -d --build api
```

Android 에뮬레이터:

```powershell
flutter run -d <장치ID> `
  --dart-define=ESEL_API_MODE=server `
  --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
```

Android 실기기는 `adb reverse tcp:3000 tcp:3000` 후 `API_BASE_URL=http://127.0.0.1:3000/api`를 사용합니다. 서버의 구현 구조와 보안 방식은 [서버 README](../server/README.md)와 [ARCHITECTURE.md](../server/ARCHITECTURE.md)에 정리되어 있습니다.

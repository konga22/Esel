# Esel Flutter

서버 없이 실행하는 중간발표 시연 앱입니다. 실행 방법과 시연 범위는 [중간발표 안내](../docs/flutter/MIDTERM_DEMO.md)를 따릅니다.

```powershell
flutter pub get
flutter devices
flutter run -d <장치ID> --dart-define=ESEL_API_MODE=mock
```

사진 편집·초안 저장·로컬 발행·서가 확인을 지원합니다. 로컬 로그인은 실제 계정 인증이 아니며 서버로 업로드하지 않습니다.
실제 API 어댑터는 보존되어 있고 로컬 옵션을 생략하면 서버 모드로 실행합니다. 현재 앱에 연결된 실제 서버 기능은 이메일 회원가입·로그인·토큰 갱신·로그아웃과 제호 중복 확인입니다. 서버에는 오늘 후보·선택, 프로필 생성, 미디어 준비·완료, 알림 설정, 호 조회, 좋아요·스크랩, 독자 한 줄, 서가·구독 API도 구현됐지만 해당 화면은 아직 로컬 데모 상태를 사용합니다. 미디어는 현재 서버 컨테이너 내부 개발 저장소를 쓰고 호 응답에 파일 URL이 없으므로 운영용 저장소와 모바일 업로드·표시 방식을 정한 뒤 연결해야 합니다.

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

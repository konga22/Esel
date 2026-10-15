# Esel Flutter

서버 없이 실행하는 중간발표 시연 앱입니다. 실행 방법과 시연 범위는 [중간발표 안내](../docs/flutter/MIDTERM_DEMO.md)를 따릅니다.

```powershell
flutter pub get
flutter devices
flutter run -d <장치ID> --dart-define=ESEL_API_MODE=mock
```

사진 편집·초안 저장·로컬 발행·서가 확인을 지원합니다. 로컬 로그인은 실제 계정 인증이 아니며 서버로 업로드하지 않습니다.
실제 API 어댑터는 보존되어 있고 로컬 옵션을 생략하면 서버 모드로 실행합니다.
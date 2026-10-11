// 계약 테스트: media 모듈. api-contract.json의 API와 docs/dev/FEATURES.md의 합격 기준을 할 일(it.todo)로 적어 두었다.
// 하나를 구현하면 그 it.todo를 실제 요청을 보내는 테스트로 바꾸고, api-contract.json의 status를 done으로 바꾼다.
// 실행: npm run test:e2e (todo는 실패가 아니라 '남은 일'로 표시된다)

describe('DEV-08 사진과 얼굴 연출', () => {
  // media.prepare · 접근: user · 응답: MediaUploadDto · 계약: P11
  it.todo('POST /api/media: 사진 올리기 준비(저장 위치 받기) → 201 또는 200');
  it.todo('POST /api/media: 로그인 없이 부르면 401 AUTH_REQUIRED');
  it.todo('POST /api/media: 보낸 값의 형식이 맞지 않아요. → 400 VALIDATION');
  it.todo('POST /api/media: 사진이 너무 커요. → 413 MEDIA_TOO_LARGE');
  it.todo('POST /api/media: 사진 파일만 올릴 수 있어요. → 415 MEDIA_TYPE');
  // media.complete · 접근: owner · 응답: MediaOwnerDto · 계약: P11
  it.todo('POST /api/media/:id/complete: 사진 올리기 완료 확인과 검증 → 201 또는 200');
  it.todo('POST /api/media/:id/complete: 로그인 없이 부르면 401 AUTH_REQUIRED');
  it.todo('POST /api/media/:id/complete: 찾을 수 없어요. → 404 NOT_FOUND');
  it.todo('POST /api/media/:id/complete: 이 작업을 할 권한이 없어요. → 403 FORBIDDEN');
  it.todo('POST /api/media/:id/complete: 사진이 너무 커요. → 413 MEDIA_TOO_LARGE');
  it.todo('POST /api/media/:id/complete: 사진 파일만 올릴 수 있어요. → 415 MEDIA_TYPE');
  it.todo('합격 기준: 얼굴 위치를 정하지 않으면 발행 버튼 비활성(P11)');
  it.todo('합격 기준: "그대로"에서 제호가 얼굴을 덮지 않음(P15)');
  it.todo('합격 기준: 15MB 초과·이미지 아닌 파일은 이유와 함께 거절');
});

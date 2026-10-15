// 계약 테스트: media 모듈. api-contract.json의 API와 루트 docs/dev/features.json의 서버 합격 기준을 할 일(it.todo)로 적어 두었다.
// 이 파일은 손으로 관리한다. API마다 'METHOD /api/경로: … → 상태' 형식의 todo나 테스트가 있어야 하고, 상태 코드는 api-contract.json과 같아야 한다(npm run check:server가 확인).
// 하나를 구현하면 그 todo를 it(…) 안에서 request(app.getHttpServer()).<method>('/api/…')로 부르는 실제 테스트로 바꾸고, api-contract.json의 status를 done으로 바꾼다.
// 실행: npm run test:e2e (todo는 실패가 아니라 '남은 일'로 표시된다)

describe('DEV-08 사진과 얼굴 연출', () => {
  // media.prepare · 접근: user · 응답: MediaUploadDto · 계약: P11
  it.todo('POST /api/media: 사진 올리기 준비(저장 위치 받기) → 201');
  it.todo('POST /api/media: 로그인 없이 부르면 → 401 AUTH_REQUIRED');
  it.todo('POST /api/media: 보낸 값의 형식이 맞지 않아요 → 400 VALIDATION');
  it.todo('POST /api/media: 사진이 너무 커요 → 413 MEDIA_TOO_LARGE');
  it.todo('POST /api/media: 사진 파일만 올릴 수 있어요 → 415 MEDIA_TYPE');
  // media.complete · 접근: owner · 응답: MediaOwnerDto · 계약: P11
  it.todo('POST /api/media/:id/complete: 사진 올리기 완료 확인과 검증 → 201');
  it.todo('POST /api/media/:id/complete: 로그인 없이 부르면 → 401 AUTH_REQUIRED');
  it.todo('POST /api/media/:id/complete: 남의 사진 → 403 FORBIDDEN');
  it.todo('POST /api/media/:id/complete: 없는 사진 → 404 NOT_FOUND');
  it.todo('POST /api/media/:id/complete: 사진이 너무 커요 → 413 MEDIA_TOO_LARGE');
  it.todo('POST /api/media/:id/complete: 사진 파일만 올릴 수 있어요 → 415 MEDIA_TYPE');
  it.todo('합격 기준: 이미지 파일은 PostgreSQL에 넣지 않고 저장 위치(storage_key)만 저장');
});

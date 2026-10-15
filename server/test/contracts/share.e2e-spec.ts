// 계약 테스트: share 모듈. api-contract.json의 API와 루트 docs/dev/features.json의 서버 합격 기준을 할 일(it.todo)로 적어 두었다.
// 이 파일은 손으로 관리한다. API마다 'METHOD /api/경로: … → 상태' 형식의 todo나 테스트가 있어야 하고, 상태 코드는 api-contract.json과 같아야 한다(npm run check:server가 확인).
// 하나를 구현하면 그 todo를 it(…) 안에서 request(app.getHttpServer()).<method>('/api/…')로 부르는 실제 테스트로 바꾸고, api-contract.json의 status를 done으로 바꾼다.
// 실행: npm run test:e2e (todo는 실패가 아니라 '남은 일'로 표시된다)

describe('DEV-18 공유', () => {
  // share.create · 접근: user · 응답: ShareLinkDto · 계약: P01, P02, P18
  it.todo('POST /api/share-links: 공개된 표지·공동 트윈의 공유 링크 만들기 → 201');
  it.todo('POST /api/share-links: 로그인 없이 부르면 → 401 AUTH_REQUIRED');
  it.todo('POST /api/share-links: 보낸 값의 형식이 맞지 않아요 → 400 VALIDATION');
  it.todo('POST /api/share-links: 없거나 나에게 잠긴 표지·트윈 → 404 NOT_FOUND');
  it.todo('POST /api/share-links: 공개된 표지만 공유할 수 있어요 → 422 SHARE_NOT_PUBLIC');
  // share.open · 접근: public · 응답: SharedIssuePublicDto · 계약: P01, P02, P18
  it.todo('GET /api/share-links/:token: 공유 링크 열기(열 때도 공개 권한 다시 검사) → 200');
  it.todo('GET /api/share-links/:token: 없거나 지운 링크, 또는 이제 볼 수 없는 표지 → 404 NOT_FOUND');
  it.todo('합격 기준: 발행 전 내 표지·비공개 트윈은 링크 발급 거절');
  it.todo('합격 기준(P18): 링크 응답에 숫자·사용자 내부 ID 없음');
  it.todo('합격 기준(P01): 로그인한 사람이 링크를 열면 그 사람 기준으로 같은 색 잠금을 다시 검사해, 잠긴 표지면 404');
});

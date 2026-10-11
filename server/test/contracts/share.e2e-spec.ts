// 계약 테스트: share 모듈. api-contract.json의 API와 docs/dev/FEATURES.md의 합격 기준을 할 일(it.todo)로 적어 두었다.
// 하나를 구현하면 그 it.todo를 실제 요청을 보내는 테스트로 바꾸고, api-contract.json의 status를 done으로 바꾼다.
// 실행: npm run test:e2e (todo는 실패가 아니라 '남은 일'로 표시된다)

describe('DEV-18 공유', () => {
  // share.create · 접근: user · 응답: ShareLinkDto · 계약: P01, P18
  it.todo('POST /api/share-links: 공개된 표지·공동 트윈의 공유 링크 만들기 → 201 또는 200');
  it.todo('POST /api/share-links: 로그인 없이 부르면 401 AUTH_REQUIRED');
  it.todo('POST /api/share-links: 찾을 수 없어요. → 404 NOT_FOUND');
  it.todo('POST /api/share-links: 공개된 표지만 공유할 수 있어요. → 422 SHARE_NOT_PUBLIC');
  // share.open · 접근: public · 응답: SharedIssuePublicDto · 계약: P01, P18
  it.todo('GET /api/share-links/:token: 공유 링크 열기(열 때도 공개 권한 다시 검사) → 200');
  it.todo('GET /api/share-links/:token: 찾을 수 없어요. → 404 NOT_FOUND');
  it.todo('합격 기준: 발행 전 내 표지·비공개 트윈은 링크 발급 거절');
  it.todo('합격 기준: 링크 응답에 숫자·사용자 내부 ID 없음');
});

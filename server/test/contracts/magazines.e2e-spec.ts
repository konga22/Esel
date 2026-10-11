// 계약 테스트: magazines 모듈. api-contract.json의 API와 docs/dev/FEATURES.md의 합격 기준을 할 일(it.todo)로 적어 두었다.
// 하나를 구현하면 그 it.todo를 실제 요청을 보내는 테스트로 바꾸고, api-contract.json의 status를 done으로 바꾼다.
// 실행: npm run test:e2e (todo는 실패가 아니라 '남은 일'로 표시된다)

describe('DEV-13 서가와 구독', () => {
  // magazines.get · 접근: user · 응답: MagazinePublicDto · 계약: P04, P18
  it.todo('GET /api/magazines/:masthead: 남의 잡지(서가)와 지난 호 → 200');
  it.todo('GET /api/magazines/:masthead: 로그인 없이 부르면 401 AUTH_REQUIRED');
  it.todo('GET /api/magazines/:masthead: 찾을 수 없어요. → 404 NOT_FOUND');
  // magazines.subscribe · 접근: user · 응답: SubscriptionStateDto · 계약: P12, P18
  it.todo('POST /api/magazines/:masthead/subscription: 구독 → 201 또는 200');
  it.todo('POST /api/magazines/:masthead/subscription: 로그인 없이 부르면 401 AUTH_REQUIRED');
  it.todo('POST /api/magazines/:masthead/subscription: 찾을 수 없어요. → 404 NOT_FOUND');
  // magazines.unsubscribe · 접근: user · 응답: SubscriptionStateDto · 계약: P12
  it.todo('DELETE /api/magazines/:masthead/subscription: 구독 취소 → 200 또는 204');
  it.todo('DELETE /api/magazines/:masthead/subscription: 로그인 없이 부르면 401 AUTH_REQUIRED');
  it.todo('DELETE /api/magazines/:masthead/subscription: 찾을 수 없어요. → 404 NOT_FOUND');
  it.todo('합격 기준: 서가 응답에 구독자 수가 없음');
  it.todo('합격 기준: 구독하면 피드 구독 탭에 나타남');
});

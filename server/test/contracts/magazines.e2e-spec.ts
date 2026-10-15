// 계약 테스트: magazines 모듈. api-contract.json의 API와 루트 docs/dev/features.json의 서버 합격 기준을 할 일(it.todo)로 적어 두었다.
// 이 파일은 손으로 관리한다. API마다 'METHOD /api/경로: … → 상태' 형식의 todo나 테스트가 있어야 하고, 상태 코드는 api-contract.json과 같아야 한다(npm run check:server가 확인).
// 하나를 구현하면 그 todo를 it(…) 안에서 request(app.getHttpServer()).<method>('/api/…')로 부르는 실제 테스트로 바꾸고, api-contract.json의 status를 done으로 바꾼다.
// 실행: npm run test:e2e (todo는 실패가 아니라 '남은 일'로 표시된다)

describe('DEV-13 서가와 구독', () => {
  // magazines.get · 접근: user · 응답: MagazinePublicDto · 계약: P01, P02, P04, P18
  it.todo('GET /api/magazines/:masthead: 남의 잡지(서가)와 지난 호 → 200');
  it.todo('GET /api/magazines/:masthead: 로그인 없이 부르면 → 401 AUTH_REQUIRED');
  it.todo('GET /api/magazines/:masthead: 없는 제호 → 404 NOT_FOUND');
  // magazines.subscribe · 접근: user · 응답: SubscriptionStateDto · 계약: P12, P18
  it.todo('POST /api/magazines/:masthead/subscription: 구독 → 201');
  it.todo('POST /api/magazines/:masthead/subscription: 로그인 없이 부르면 → 401 AUTH_REQUIRED');
  it.todo('POST /api/magazines/:masthead/subscription: 없는 제호 → 404 NOT_FOUND');
  // magazines.unsubscribe · 접근: user · 응답: SubscriptionStateDto · 계약: P12
  it.todo('DELETE /api/magazines/:masthead/subscription: 구독 취소 → 200');
  it.todo('DELETE /api/magazines/:masthead/subscription: 로그인 없이 부르면 → 401 AUTH_REQUIRED');
  it.todo('DELETE /api/magazines/:masthead/subscription: 없는 제호 → 404 NOT_FOUND');
  it.todo('합격 기준(P18): 서가 응답에 구독자 수가 없음');
  it.todo('합격 기준(P01): 그 사람의 오늘 호가 내 오늘 후보 색이고 미리보기 3장 밖이면 id·사진 없이 숨김(내가 발행하면 보임)');
  it.todo('합격 기준: 구독하면 GET /api/feed?tab=subs에 그 잡지의 호가 나옴');
});

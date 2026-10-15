// 계약 테스트: me 모듈. api-contract.json의 API와 루트 docs/dev/features.json의 서버 합격 기준을 할 일(it.todo)로 적어 두었다.
// 이 파일은 손으로 관리한다. API마다 'METHOD /api/경로: … → 상태' 형식의 todo나 테스트가 있어야 하고, 상태 코드는 api-contract.json과 같아야 한다(npm run check:server가 확인).
// 하나를 구현하면 그 todo를 it(…) 안에서 request(app.getHttpServer()).<method>('/api/…')로 부르는 실제 테스트로 바꾸고, api-contract.json의 status를 done으로 바꾼다.
// 실행: npm run test:e2e (todo는 실패가 아니라 '남은 일'로 표시된다)

describe('DEV-14 내 잡지와 반응', () => {
  // me.magazine · 접근: user · 응답: MagazineOwnerDto · 계약: P18
  it.todo('GET /api/me/magazine: 내 잡지(오늘 호, 지난 호, 나만 보는 숫자) → 200');
  it.todo('GET /api/me/magazine: 로그인 없이 부르면 → 401 AUTH_REQUIRED');
  // me.reactions · 접근: owner · 응답: IssueReactionsOwnerDto · 계약: P01, P18
  it.todo('GET /api/me/issues/:id/reactions: 내 표지의 반응 수와 목록 → 200');
  it.todo('GET /api/me/issues/:id/reactions: 로그인 없이 부르면 → 401 AUTH_REQUIRED');
  it.todo('GET /api/me/issues/:id/reactions: 남의 표지(나에게 보이는 것) → 403 FORBIDDEN');
  it.todo('GET /api/me/issues/:id/reactions: 없거나 나에게 잠긴 표지(P01) → 404 NOT_FOUND');
  it.todo('합격 기준: 남의 표지 id로 reactions를 부르면 403, 나에게 잠긴 표지면 404');
  it.todo('합격 기준(P18): 반응 숫자는 소유자 응답(…OwnerDto)에만 있음');
});

// 계약 테스트: me 모듈. api-contract.json의 API와 docs/dev/FEATURES.md의 합격 기준을 할 일(it.todo)로 적어 두었다.
// 하나를 구현하면 그 it.todo를 실제 요청을 보내는 테스트로 바꾸고, api-contract.json의 status를 done으로 바꾼다.
// 실행: npm run test:e2e (todo는 실패가 아니라 '남은 일'로 표시된다)

describe('DEV-14 내 잡지와 반응', () => {
  // me.magazine · 접근: user · 응답: MagazineOwnerDto · 계약: P18
  it.todo('GET /api/me/magazine: 내 잡지(오늘 호, 지난 호, 나만 보는 숫자) → 200');
  it.todo('GET /api/me/magazine: 로그인 없이 부르면 401 AUTH_REQUIRED');
  // me.reactions · 접근: owner · 응답: IssueReactionsOwnerDto · 계약: P18
  it.todo('GET /api/me/issues/:id/reactions: 내 표지의 반응 수와 목록 → 200');
  it.todo('GET /api/me/issues/:id/reactions: 로그인 없이 부르면 401 AUTH_REQUIRED');
  it.todo('GET /api/me/issues/:id/reactions: 찾을 수 없어요. → 404 NOT_FOUND');
  it.todo('GET /api/me/issues/:id/reactions: 이 작업을 할 권한이 없어요. → 403 FORBIDDEN');
  it.todo('합격 기준: 남의 issue id로 reactions를 부르면 403');
  it.todo('합격 기준: 소유자 응답에만 숫자가 있음');
});

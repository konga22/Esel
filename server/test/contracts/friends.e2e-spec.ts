// 계약 테스트: friends 모듈. api-contract.json의 API와 docs/dev/FEATURES.md의 합격 기준을 할 일(it.todo)로 적어 두었다.
// 하나를 구현하면 그 it.todo를 실제 요청을 보내는 테스트로 바꾸고, api-contract.json의 status를 done으로 바꾼다.
// 실행: npm run test:e2e (todo는 실패가 아니라 '남은 일'로 표시된다)

describe('DEV-16 친구', () => {
  // users.lookup · 접근: user · 응답: UserPublicDto · 계약: P18
  it.todo('GET /api/users/:masthead: 제호로 사람 찾기(친구 요청 전 확인) → 200');
  it.todo('GET /api/users/:masthead: 로그인 없이 부르면 401 AUTH_REQUIRED');
  it.todo('GET /api/users/:masthead: 찾을 수 없어요. → 404 NOT_FOUND');
  // friends.list · 접근: user · 응답: Page<FriendDto>
  it.todo('GET /api/friends: 내 친구 목록 → 200');
  it.todo('GET /api/friends: 로그인 없이 부르면 401 AUTH_REQUIRED');
  // friends.requests · 접근: user · 응답: Page<FriendRequestDto>
  it.todo('GET /api/friends/requests: 받은 친구 요청 → 200');
  it.todo('GET /api/friends/requests: 로그인 없이 부르면 401 AUTH_REQUIRED');
  // friends.request · 접근: user · 응답: FriendRequestDto · 계약: P12
  it.todo('POST /api/friends/requests: 친구 요청 보내기 → 201 또는 200');
  it.todo('POST /api/friends/requests: 로그인 없이 부르면 401 AUTH_REQUIRED');
  it.todo('POST /api/friends/requests: 찾을 수 없어요. → 404 NOT_FOUND');
  it.todo('POST /api/friends/requests: 이미 친구예요. → 409 ALREADY_FRIENDS');
  it.todo('POST /api/friends/requests: 이미 보낸 요청이 있어요. → 409 REQUEST_EXISTS');
  // friends.accept · 접근: user · 응답: FriendDto
  it.todo('POST /api/friends/requests/:id/accept: 받은 요청 수락 → 201 또는 200');
  it.todo('POST /api/friends/requests/:id/accept: 로그인 없이 부르면 401 AUTH_REQUIRED');
  it.todo('POST /api/friends/requests/:id/accept: 찾을 수 없어요. → 404 NOT_FOUND');
  it.todo('POST /api/friends/requests/:id/accept: 이 작업을 할 권한이 없어요. → 403 FORBIDDEN');
  // friends.decline · 접근: user · 응답: void
  it.todo('POST /api/friends/requests/:id/decline: 받은 요청 나중에(거절) → 201 또는 200');
  it.todo('POST /api/friends/requests/:id/decline: 로그인 없이 부르면 401 AUTH_REQUIRED');
  it.todo('POST /api/friends/requests/:id/decline: 찾을 수 없어요. → 404 NOT_FOUND');
  it.todo('POST /api/friends/requests/:id/decline: 이 작업을 할 권한이 없어요. → 403 FORBIDDEN');
  it.todo('합격 기준: 없는 아이디는 ’찾지 못했어요’와 철자 확인 안내');
  it.todo('합격 기준: 같은 요청 중복 생성 불가');
});

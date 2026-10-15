// 계약 테스트: friends 모듈. api-contract.json의 API와 루트 docs/dev/features.json의 서버 합격 기준을 할 일(it.todo)로 적어 두었다.
// 이 파일은 손으로 관리한다. API마다 'METHOD /api/경로: … → 상태' 형식의 todo나 테스트가 있어야 하고, 상태 코드는 api-contract.json과 같아야 한다(npm run check:server가 확인).
// 하나를 구현하면 그 todo를 it(…) 안에서 request(app.getHttpServer()).<method>('/api/…')로 부르는 실제 테스트로 바꾸고, api-contract.json의 status를 done으로 바꾼다.
// 실행: npm run test:e2e (todo는 실패가 아니라 '남은 일'로 표시된다)

describe('DEV-16 친구', () => {
  // users.lookup · 접근: user · 응답: UserPublicDto · 계약: P18
  it.todo('GET /api/users/:masthead: 제호로 사람 찾기(친구 요청 전 확인) → 200');
  it.todo('GET /api/users/:masthead: 로그인 없이 부르면 → 401 AUTH_REQUIRED');
  it.todo('GET /api/users/:masthead: 없는 제호 → 404 NOT_FOUND');
  // friends.list · 접근: user · 응답: Page<FriendDto>
  it.todo('GET /api/friends: 내 친구 목록 → 200');
  it.todo('GET /api/friends: 로그인 없이 부르면 → 401 AUTH_REQUIRED');
  // friends.requests · 접근: user · 응답: Page<FriendRequestDto>
  it.todo('GET /api/friends/requests: 받은 친구 요청 → 200');
  it.todo('GET /api/friends/requests: 로그인 없이 부르면 → 401 AUTH_REQUIRED');
  // friends.request · 접근: user · 응답: FriendRequestDto · 계약: P12
  it.todo('POST /api/friends/requests: 친구 요청 보내기 → 201');
  it.todo('POST /api/friends/requests: 로그인 없이 부르면 → 401 AUTH_REQUIRED');
  it.todo('POST /api/friends/requests: 보낸 값의 형식이 맞지 않아요 → 400 VALIDATION');
  it.todo('POST /api/friends/requests: 없는 제호 → 404 NOT_FOUND');
  it.todo('POST /api/friends/requests: 이미 친구예요 → 409 ALREADY_FRIENDS');
  it.todo('POST /api/friends/requests: 이미 보낸 요청이 있어요 → 409 REQUEST_EXISTS');
  // friends.accept · 접근: user · 응답: FriendDto
  it.todo('POST /api/friends/requests/:id/accept: 받은 요청 수락 → 201');
  it.todo('POST /api/friends/requests/:id/accept: 로그인 없이 부르면 → 401 AUTH_REQUIRED');
  it.todo('POST /api/friends/requests/:id/accept: 내가 보낸 요청을 내가 수락함 → 403 FORBIDDEN');
  it.todo('POST /api/friends/requests/:id/accept: 없거나 나와 상관없는 요청 → 404 NOT_FOUND');
  // friends.decline · 접근: user · 응답: void
  it.todo('POST /api/friends/requests/:id/decline: 받은 요청 나중에(거절) → 204');
  it.todo('POST /api/friends/requests/:id/decline: 로그인 없이 부르면 → 401 AUTH_REQUIRED');
  it.todo('POST /api/friends/requests/:id/decline: 내가 보낸 요청을 내가 거절함 → 403 FORBIDDEN');
  it.todo('POST /api/friends/requests/:id/decline: 없거나 나와 상관없는 요청 → 404 NOT_FOUND');
  it.todo('합격 기준: 같은 사람에게 친구 요청을 두 번 만들 수 없음(동시에 보내도 하나)');
});

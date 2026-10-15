// 계약 테스트: twins 모듈. api-contract.json의 API와 루트 docs/dev/features.json의 서버 합격 기준을 할 일(it.todo)로 적어 두었다.
// 이 파일은 손으로 관리한다. API마다 'METHOD /api/경로: … → 상태' 형식의 todo나 테스트가 있어야 하고, 상태 코드는 api-contract.json과 같아야 한다(npm run check:server가 확인).
// 하나를 구현하면 그 todo를 it(…) 안에서 request(app.getHttpServer()).<method>('/api/…')로 부르는 실제 테스트로 바꾸고, api-contract.json의 status를 done으로 바꾼다.
// 실행: npm run test:e2e (todo는 실패가 아니라 '남은 일'로 표시된다)

describe('DEV-17 트윈', () => {
  // twins.invite · 접근: user · 응답: TwinDto · 계약: P08
  it.todo('POST /api/twins: 친구를 오늘 트윈에 초대 → 201');
  it.todo('POST /api/twins: 로그인 없이 부르면 → 401 AUTH_REQUIRED');
  it.todo('POST /api/twins: 보낸 값의 형식이 맞지 않아요 → 400 VALIDATION');
  it.todo('POST /api/twins: 친구가 아니거나 없는 사람 → 404 NOT_FOUND');
  it.todo('POST /api/twins: 지금 단계에서는 할 수 없는 작업이에요 → 409 TWIN_STATE');
  // twins.get · 접근: member · 응답: TwinDto · 계약: P08, P10
  it.todo('GET /api/twins/:id: 트윈 현재 단계(상대 사진은 둘 다 게시 후에만) → 200');
  it.todo('GET /api/twins/:id: 로그인 없이 부르면 → 401 AUTH_REQUIRED');
  it.todo('GET /api/twins/:id: 참여자가 아니거나 없는 트윈 → 404 NOT_FOUND');
  // twins.accept · 접근: member · 응답: TwinDto · 계약: P08
  it.todo('POST /api/twins/:id/accept: 초대 수락 → 201');
  it.todo('POST /api/twins/:id/accept: 로그인 없이 부르면 → 401 AUTH_REQUIRED');
  it.todo('POST /api/twins/:id/accept: 참여자가 아니거나 없는 트윈 → 404 NOT_FOUND');
  it.todo('POST /api/twins/:id/accept: 지금 단계에서는 할 수 없는 작업이에요 → 409 TWIN_STATE');
  // twins.choose · 접근: member · 응답: TwinDto · 계약: P08, P09
  it.todo('PUT /api/twins/:id/choice: 내 트윈 색 고르기(내 후보 3개 중) → 200');
  it.todo('PUT /api/twins/:id/choice: 로그인 없이 부르면 → 401 AUTH_REQUIRED');
  it.todo('PUT /api/twins/:id/choice: 보낸 값의 형식이 맞지 않아요 → 400 VALIDATION');
  it.todo('PUT /api/twins/:id/choice: 참여자가 아니거나 없는 트윈 → 404 NOT_FOUND');
  it.todo('PUT /api/twins/:id/choice: 지금 단계에서는 할 수 없는 작업이에요 → 409 TWIN_STATE');
  it.todo('PUT /api/twins/:id/choice: 오늘 후보에 없는 색이에요 → 422 COLOR_NOT_CANDIDATE');
  // twins.post · 접근: member · 응답: TwinDto · 계약: P01, P09, P10
  it.todo('POST /api/twins/:id/posts: 내 트윈 표지 올리기(명시적 업로드) → 201');
  it.todo('POST /api/twins/:id/posts: 로그인 없이 부르면 → 401 AUTH_REQUIRED');
  it.todo('POST /api/twins/:id/posts: 보낸 값의 형식이 맞지 않아요 → 400 VALIDATION');
  it.todo('POST /api/twins/:id/posts: 참여자가 아니거나 없는 트윈 → 404 NOT_FOUND');
  it.todo('POST /api/twins/:id/posts: 사진 올리기가 아직 끝나지 않았어요 → 409 MEDIA_NOT_READY');
  it.todo('POST /api/twins/:id/posts: 지금 단계에서는 할 수 없는 작업이에요 → 409 TWIN_STATE');
  // twins.visibility · 접근: member · 응답: TwinDto · 계약: P10
  it.todo('PUT /api/twins/:id/visibility: 공개 범위 정하기(private·solo·joint) → 200');
  it.todo('PUT /api/twins/:id/visibility: 로그인 없이 부르면 → 401 AUTH_REQUIRED');
  it.todo('PUT /api/twins/:id/visibility: 보낸 값의 형식이 맞지 않아요 → 400 VALIDATION');
  it.todo('PUT /api/twins/:id/visibility: 참여자가 아니거나 없는 트윈 → 404 NOT_FOUND');
  it.todo('PUT /api/twins/:id/visibility: 지금 단계에서는 할 수 없는 작업이에요 → 409 TWIN_STATE');
  // twins.consent · 접근: member · 응답: TwinDto · 계약: P10
  it.todo('POST /api/twins/:id/consent: 공동 공개에 동의 → 201');
  it.todo('POST /api/twins/:id/consent: 로그인 없이 부르면 → 401 AUTH_REQUIRED');
  it.todo('POST /api/twins/:id/consent: 참여자가 아니거나 없는 트윈 → 404 NOT_FOUND');
  it.todo('POST /api/twins/:id/consent: 지금 단계에서는 할 수 없는 작업이에요 → 409 TWIN_STATE');
  // twins.publish · 접근: member · 응답: TwinDto · 계약: P01, P09, P10
  it.todo('POST /api/twins/:id/publish: 공동 표지 발행(두 사람 동의 후) → 201');
  it.todo('POST /api/twins/:id/publish: 로그인 없이 부르면 → 401 AUTH_REQUIRED');
  it.todo('POST /api/twins/:id/publish: 참여자가 아니거나 없는 트윈 → 404 NOT_FOUND');
  it.todo('POST /api/twins/:id/publish: 지금 단계에서는 할 수 없는 작업이에요 → 409 TWIN_STATE');
  it.todo('POST /api/twins/:id/publish: 두 사람 모두 동의해야 공개할 수 있어요 → 409 TWIN_CONSENT_REQUIRED');
  it.todo('합격 기준(P08): 두 사람 후보 3색 중 겹치는 색은 1개이고, 서로 다른 색을 골라도 됨');
  it.todo('합격 기준(P10): 한 사람만 게시한 동안 상대 사진 URL이 응답에 없음');
  it.todo('합격 기준(P10): joint 공개는 두 사람 consent 전에는 거절');
  it.todo('합격 기준(P10): 상대 사진을 혼자 공개할 수 없음');
  it.todo('합격 기준(P09): 트윈 게시·발행으로는 같은 색 방이 열리지 않고 개인 호수도 그대로');
});

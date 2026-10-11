// 계약 테스트: issues 모듈. api-contract.json의 API와 docs/dev/FEATURES.md의 합격 기준을 할 일(it.todo)로 적어 두었다.
// 하나를 구현하면 그 it.todo를 실제 요청을 보내는 테스트로 바꾸고, api-contract.json의 status를 done으로 바꾼다.
// 실행: npm run test:e2e (todo는 실패가 아니라 '남은 일'로 표시된다)

describe('DEV-09 오늘 호 발행', () => {
  // issues.publish · 접근: user · 응답: IssueOwnerDto · 계약: P04, P01
  it.todo('POST /api/issues: 오늘 호 발행(하루 한 번, 호수 +1) → 201 또는 200');
  it.todo('POST /api/issues: 로그인 없이 부르면 401 AUTH_REQUIRED');
  it.todo('POST /api/issues: 보낸 값의 형식이 맞지 않아요. → 400 VALIDATION');
  it.todo('POST /api/issues: 사진 올리기가 아직 끝나지 않았어요. → 409 MEDIA_NOT_READY');
  it.todo('POST /api/issues: 오늘 호는 이미 발행했어요. → 409 ISSUE_ALREADY_PUBLISHED');
  it.todo('합격 기준: 동시에 두 번 눌러도 호가 하나만 생김(DB unique)');
  it.todo('합격 기준: 실패하면 호수가 오르지 않고 다시 시도할 수 있음');
  it.todo('합격 기준: 발행 후 가판대의 내 색 칩 자물쇠가 사라짐');
});

describe('DEV-11 펼침면과 독자 한 줄', () => {
  // issues.get · 접근: user · 응답: IssuePublicDto | IssueOwnerDto · 계약: P01, P02, P18
  it.todo('GET /api/issues/:id: 표지 펼쳐 보기(주인이면 숫자 포함) → 200');
  it.todo('GET /api/issues/:id: 로그인 없이 부르면 401 AUTH_REQUIRED');
  it.todo('GET /api/issues/:id: 찾을 수 없어요. → 404 NOT_FOUND');
  // issues.like · 접근: user · 응답: ReactionStateDto · 계약: P12, P18
  it.todo('POST /api/issues/:id/like: 좋아요(두 번 보내도 한 번) → 201 또는 200');
  it.todo('POST /api/issues/:id/like: 로그인 없이 부르면 401 AUTH_REQUIRED');
  it.todo('POST /api/issues/:id/like: 찾을 수 없어요. → 404 NOT_FOUND');
  // issues.unlike · 접근: user · 응답: ReactionStateDto · 계약: P12
  it.todo('DELETE /api/issues/:id/like: 좋아요 취소 → 200 또는 204');
  it.todo('DELETE /api/issues/:id/like: 로그인 없이 부르면 401 AUTH_REQUIRED');
  it.todo('DELETE /api/issues/:id/like: 찾을 수 없어요. → 404 NOT_FOUND');
  // issues.scrap · 접근: user · 응답: ReactionStateDto · 계약: P12, P18
  it.todo('POST /api/issues/:id/scrap: 스크랩 → 201 또는 200');
  it.todo('POST /api/issues/:id/scrap: 로그인 없이 부르면 401 AUTH_REQUIRED');
  it.todo('POST /api/issues/:id/scrap: 찾을 수 없어요. → 404 NOT_FOUND');
  // issues.unscrap · 접근: user · 응답: ReactionStateDto · 계약: P12
  it.todo('DELETE /api/issues/:id/scrap: 스크랩 취소 → 200 또는 204');
  it.todo('DELETE /api/issues/:id/scrap: 로그인 없이 부르면 401 AUTH_REQUIRED');
  it.todo('DELETE /api/issues/:id/scrap: 찾을 수 없어요. → 404 NOT_FOUND');
  // issues.lines · 접근: user · 응답: Page<ReaderLinePublicDto> · 계약: P18
  it.todo('GET /api/issues/:id/lines: 독자 한 줄 목록(개수 없이 cursor로) → 200');
  it.todo('GET /api/issues/:id/lines: 로그인 없이 부르면 401 AUTH_REQUIRED');
  it.todo('GET /api/issues/:id/lines: 찾을 수 없어요. → 404 NOT_FOUND');
  // issues.addLine · 접근: user · 응답: ReaderLinePublicDto · 계약: P12
  it.todo('POST /api/issues/:id/lines: 독자 한 줄 남기기(60자 이내) → 201 또는 200');
  it.todo('POST /api/issues/:id/lines: 로그인 없이 부르면 401 AUTH_REQUIRED');
  it.todo('POST /api/issues/:id/lines: 보낸 값의 형식이 맞지 않아요. → 400 VALIDATION');
  it.todo('POST /api/issues/:id/lines: 찾을 수 없어요. → 404 NOT_FOUND');
  it.todo('POST /api/issues/:id/lines: 요청이 너무 많아요. → 429 RATE_LIMITED');
  it.todo('합격 기준: 남의 표지 응답에 숫자 필드가 없음');
  it.todo('합격 기준: 잠긴 표지(P01)의 id로 직접 요청하면 403/404');
  it.todo('합격 기준: 한 줄은 60자 이내, 빈 줄 거절');
});

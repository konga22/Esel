// 계약 테스트: moderation 모듈. api-contract.json의 API와 루트 docs/dev/features.json의 서버 합격 기준을 할 일(it.todo)로 적어 두었다.
// 이 파일은 손으로 관리한다. API마다 'METHOD /api/경로: … → 상태' 형식의 todo나 테스트가 있어야 하고, 상태 코드는 api-contract.json과 같아야 한다(npm run check:server가 확인).
// 하나를 구현하면 그 todo를 it(…) 안에서 request(app.getHttpServer()).<method>('/api/…')로 부르는 실제 테스트로 바꾸고, api-contract.json의 status를 done으로 바꾼다.
// 실행: npm run test:e2e (todo는 실패가 아니라 '남은 일'로 표시된다)

describe('DEV-20 신고·차단·삭제', () => {
  // moderation.reportIssue · 접근: user · 응답: ReportReceiptDto · 계약: P01
  it.todo('POST /api/issues/:id/reports: 표지 신고 → 201');
  it.todo('POST /api/issues/:id/reports: 로그인 없이 부르면 → 401 AUTH_REQUIRED');
  it.todo('POST /api/issues/:id/reports: 보낸 값의 형식이 맞지 않아요 → 400 VALIDATION');
  it.todo('POST /api/issues/:id/reports: 없거나 나에게 잠긴 표지(P01) → 404 NOT_FOUND');
  it.todo('POST /api/issues/:id/reports: 요청이 너무 많아요 → 429 RATE_LIMITED');
  // moderation.reportLine · 접근: user · 응답: ReportReceiptDto · 계약: P01
  it.todo('POST /api/issues/:id/lines/:lineId/reports: 독자 한 줄 신고 → 201');
  it.todo('POST /api/issues/:id/lines/:lineId/reports: 로그인 없이 부르면 → 401 AUTH_REQUIRED');
  it.todo('POST /api/issues/:id/lines/:lineId/reports: 보낸 값의 형식이 맞지 않아요 → 400 VALIDATION');
  it.todo('POST /api/issues/:id/lines/:lineId/reports: 없는 한 줄이거나 나에게 잠긴 표지(P01) → 404 NOT_FOUND');
  it.todo('POST /api/issues/:id/lines/:lineId/reports: 요청이 너무 많아요 → 429 RATE_LIMITED');
  // moderation.block · 접근: user · 응답: BlockStateDto
  it.todo('POST /api/users/:masthead/block: 사람 차단(그 사람의 표지·한 줄이 내 피드·가판대·서가에 안 나옴) → 201');
  it.todo('POST /api/users/:masthead/block: 로그인 없이 부르면 → 401 AUTH_REQUIRED');
  it.todo('POST /api/users/:masthead/block: 없는 제호 → 404 NOT_FOUND');
  // moderation.unblock · 접근: user · 응답: BlockStateDto
  it.todo('DELETE /api/users/:masthead/block: 차단 풀기 → 200');
  it.todo('DELETE /api/users/:masthead/block: 로그인 없이 부르면 → 401 AUTH_REQUIRED');
  it.todo('DELETE /api/users/:masthead/block: 없는 제호 → 404 NOT_FOUND');
  // moderation.blocks · 접근: user · 응답: Page<BlockedUserDto>
  it.todo('GET /api/me/blocks: 내가 차단한 사람 목록(개수 없이 cursor로) → 200');
  it.todo('GET /api/me/blocks: 로그인 없이 부르면 → 401 AUTH_REQUIRED');
  // moderation.deleteIssue · 접근: owner · 응답: void · 계약: P01, P02
  it.todo('DELETE /api/issues/:id: 내 호 삭제(공개 응답·공유 링크·이미지 주소에서 모두 사라짐) → 204');
  it.todo('DELETE /api/issues/:id: 로그인 없이 부르면 → 401 AUTH_REQUIRED');
  it.todo('DELETE /api/issues/:id: 남의 호 → 403 FORBIDDEN');
  it.todo('DELETE /api/issues/:id: 없거나 이미 지운 호 → 404 NOT_FOUND');
  it.todo('합격 기준: 지운 호는 피드·가판대·서가·펼침면·공유 링크·이미지 URL에서 모두 사라짐(404)');
  it.todo('합격 기준(P01): 호를 지우면 같은 색 방의 미리보기 3장과 hiddenCount를 다시 계산함');
  it.todo('합격 기준: 차단한 사람의 표지·독자 한 줄이 피드·가판대·서가에 나오지 않음');
});

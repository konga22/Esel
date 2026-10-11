// 계약 테스트: feed 모듈. api-contract.json의 API와 docs/dev/FEATURES.md의 합격 기준을 할 일(it.todo)로 적어 두었다.
// 하나를 구현하면 그 it.todo를 실제 요청을 보내는 테스트로 바꾸고, api-contract.json의 status를 done으로 바꾼다.
// 실행: npm run test:e2e (todo는 실패가 아니라 '남은 일'로 표시된다)

describe('DEV-10 표지 피드', () => {
  // feed.list · 접근: user · 응답: FeedPageDto · 계약: P01, P02, P16, P18
  it.todo('GET /api/feed: 표지 피드(첫 장 표지 + 안쪽 지면, 공개 권한 먼저 거름) → 200');
  it.todo('GET /api/feed: 로그인 없이 부르면 401 AUTH_REQUIRED');
  it.todo('GET /api/feed: 보낸 값의 형식이 맞지 않아요. → 400 VALIDATION');
  it.todo('합격 기준: 발행 전 응답에 오늘 내 색 표지가 없음');
  it.todo('합격 기준: 미래 날짜·잘못된 날짜 지면은 오지 않음');
  it.todo('합격 기준: 30초 뒤 인기 혼합이 들어와도 이미 본 지면 순서가 바뀌지 않음');
});

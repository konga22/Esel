// 계약 테스트: feed 모듈. api-contract.json의 API와 루트 docs/dev/features.json의 서버 합격 기준을 할 일(it.todo)로 적어 두었다.
// 이 파일은 손으로 관리한다. API마다 'METHOD /api/경로: … → 상태' 형식의 todo나 테스트가 있어야 하고, 상태 코드는 api-contract.json과 같아야 한다(npm run check:server가 확인).
// 하나를 구현하면 그 todo를 it(…) 안에서 request(app.getHttpServer()).<method>('/api/…')로 부르는 실제 테스트로 바꾸고, api-contract.json의 status를 done으로 바꾼다.
// 실행: npm run test:e2e (todo는 실패가 아니라 '남은 일'로 표시된다)

describe('DEV-10 표지 피드', () => {
  // feed.list · 접근: user · 응답: FeedPageDto · 계약: P01, P02, P16, P18
  it.todo('GET /api/feed: 표지 피드(첫 장 표지 + 안쪽 지면, 공개 권한 먼저 거름) → 200');
  it.todo('GET /api/feed: 로그인 없이 부르면 → 401 AUTH_REQUIRED');
  it.todo('GET /api/feed: 보낸 값의 형식이 맞지 않아요 → 400 VALIDATION');
  it.todo('합격 기준(P01): 오늘 발행 전에는 오늘 후보 3색의 표지가 피드에 없음(고른 색·바꾼 색과 무관). 발행하면 들어옴');
  it.todo('합격 기준(P02): 후보가 아닌 색과 지난 날짜 표지는 발행 전에도 나오고, 미래·잘못된 날짜 지면은 오지 않음');
  it.todo('합격 기준: 다음 페이지(cursor)를 불러도 이미 보낸 지면의 순서가 바뀌지 않음(인기 혼합은 공개 권한 필터 뒤, 뒤에만 붙음)');
  it.todo('합격 기준(P18): 응답에 반응 숫자·순위가 없음');
});

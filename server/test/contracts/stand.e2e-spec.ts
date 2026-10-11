// 계약 테스트: stand 모듈. api-contract.json의 API와 docs/dev/FEATURES.md의 합격 기준을 할 일(it.todo)로 적어 두었다.
// 하나를 구현하면 그 it.todo를 실제 요청을 보내는 테스트로 바꾸고, api-contract.json의 status를 done으로 바꾼다.
// 실행: npm run test:e2e (todo는 실패가 아니라 '남은 일'로 표시된다)

describe('DEV-12 가판대와 같은 색', () => {
  // stand.get · 접근: user · 응답: StandDto · 계약: P01, P02, P18
  it.todo('GET /api/stand: 가판대·같은 색 방(발행 전 내 색은 3장 + 숨긴 개수) → 200');
  it.todo('GET /api/stand: 로그인 없이 부르면 401 AUTH_REQUIRED');
  it.todo('GET /api/stand: 보낸 값의 형식이 맞지 않아요. → 400 VALIDATION');
  it.todo('합격 기준: 발행 전 내 색 요청에 표지 3장과 hiddenCount만 옴');
  it.todo('합격 기준: 발행·자정 이후에는 전체');
  it.todo('합격 기준: 다른 색·지난 날짜는 발행 전에도 전체');
});

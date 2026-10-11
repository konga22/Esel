// 계약 테스트: today 모듈. api-contract.json의 API와 docs/dev/FEATURES.md의 합격 기준을 할 일(it.todo)로 적어 두었다.
// 하나를 구현하면 그 it.todo를 실제 요청을 보내는 테스트로 바꾸고, api-contract.json의 status를 done으로 바꾼다.
// 실행: npm run test:e2e (todo는 실패가 아니라 '남은 일'로 표시된다)

describe('DEV-04 비로그인 첫 표지와 로그인 바', () => {
  // today.cover · 접근: public · 응답: TodayCoverPublicDto · 계약: P12, P18
  it.todo('GET /api/today/cover: 비로그인용 오늘의 표지와 안쪽 2쪽 → 200');
  it.todo('합격 기준: 비로그인에서 3번째 안쪽 지면 이후는 받지 않음(서버가 2쪽까지만 응답)');
  it.todo('합격 기준: 반응·구독·스크랩·만들기를 누르면 로그인 시트가 열림');
  it.todo('합격 기준: 작은 로고를 누르면 맨 위로 이동하고 제호로 녹아듦');
});

describe('DEV-07 오늘의 색', () => {
  // today.get · 접근: user · 응답: TodayDto · 계약: P05, P17
  it.todo('GET /api/today: 오늘의 날짜, 후보 3색, 내 선택, 발행 여부 → 200');
  it.todo('GET /api/today: 로그인 없이 부르면 401 AUTH_REQUIRED');
  // today.choose · 접근: user · 응답: TodayDto · 계약: P03, P05
  it.todo('PUT /api/today/choice: 오늘의 색 고르기(발행 전까지 바꿀 수 있음) → 200');
  it.todo('PUT /api/today/choice: 로그인 없이 부르면 401 AUTH_REQUIRED');
  it.todo('PUT /api/today/choice: 보낸 값의 형식이 맞지 않아요. → 400 VALIDATION');
  it.todo('PUT /api/today/choice: 오늘 후보에 없는 색이에요. → 422 COLOR_NOT_CANDIDATE');
  it.todo('PUT /api/today/choice: 오늘 호를 발행해서 색을 바꿀 수 없어요. → 409 CHOICE_LOCKED');
  it.todo('합격 기준: 후보 밖의 색은 고를 수 없음');
  it.todo('합격 기준: 색 고르기·확정만으로는 같은 색 방이 열리지 않음(P03)');
  it.todo('합격 기준: 발행 후 색 변경은 거절');
});

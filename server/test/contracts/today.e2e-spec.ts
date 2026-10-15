// 계약 테스트: today 모듈. api-contract.json의 API와 루트 docs/dev/features.json의 서버 합격 기준을 할 일(it.todo)로 적어 두었다.
// 이 파일은 손으로 관리한다. API마다 'METHOD /api/경로: … → 상태' 형식의 todo나 테스트가 있어야 하고, 상태 코드는 api-contract.json과 같아야 한다(npm run check:server가 확인).
// 하나를 구현하면 그 todo를 it(…) 안에서 request(app.getHttpServer()).<method>('/api/…')로 부르는 실제 테스트로 바꾸고, api-contract.json의 status를 done으로 바꾼다.
// 실행: npm run test:e2e (todo는 실패가 아니라 '남은 일'로 표시된다)

describe('DEV-04 비로그인 첫 표지와 로그인 바', () => {
  // today.cover · 접근: public · 응답: TodayCoverPublicDto · 계약: P01, P12, P18
  it.todo('GET /api/today/cover: 비로그인용 오늘의 표지와 안쪽 2쪽 → 200');
  it.todo('합격 기준(P12): 비로그인에게는 표지 1장과 안쪽 2쪽까지만 줌(3번째 지면 이후는 응답에 없음)');
  it.todo('합격 기준(P01): 오늘 후보 색 표지는 각 방의 미리보기(최신 3장) 안에서만 고름. 로그인 없이 불러 잠긴 표지를 보는 우회를 막음');
  it.todo('합격 기준(P18): 응답에 반응 숫자가 없음');
});

describe('DEV-07 오늘의 색', () => {
  // today.get · 접근: user · 응답: TodayDto · 계약: P05, P17
  it.todo('GET /api/today: 오늘의 날짜, 후보 3색, 내 선택, 발행 여부 → 200');
  it.todo('GET /api/today: 로그인 없이 부르면 → 401 AUTH_REQUIRED');
  // today.choose · 접근: user · 응답: TodayDto · 계약: P01, P03, P05
  it.todo('PUT /api/today/choice: 오늘의 색 고르기(발행 전까지 바꿀 수 있음) → 200');
  it.todo('PUT /api/today/choice: 로그인 없이 부르면 → 401 AUTH_REQUIRED');
  it.todo('PUT /api/today/choice: 보낸 값의 형식이 맞지 않아요 → 400 VALIDATION');
  it.todo('PUT /api/today/choice: 오늘 호를 발행해서 색을 바꿀 수 없어요 → 409 CHOICE_LOCKED');
  it.todo('PUT /api/today/choice: 오늘 후보에 없는 색이에요 → 422 COLOR_NOT_CANDIDATE');
  it.todo('합격 기준(P17): 후보는 12색 중 서로 다른 3색이고 서비스 날짜(SERVICE_TIME_ZONE 자정 기준)로 정해짐');
  it.todo('합격 기준: 후보 밖의 색은 고를 수 없음');
  it.todo('합격 기준(P01·P03): 색을 고르거나 바꾸기만 해서는 어느 같은 색 방도 열리지 않음');
  it.todo('합격 기준: 발행 후 색 변경은 거절');
});

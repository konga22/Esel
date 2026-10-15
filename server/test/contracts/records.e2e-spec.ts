// 계약 테스트: records 모듈. api-contract.json의 API와 루트 docs/dev/features.json의 서버 합격 기준을 할 일(it.todo)로 적어 두었다.
// 이 파일은 손으로 관리한다. API마다 'METHOD /api/경로: … → 상태' 형식의 todo나 테스트가 있어야 하고, 상태 코드는 api-contract.json과 같아야 한다(npm run check:server가 확인).
// 하나를 구현하면 그 todo를 it(…) 안에서 request(app.getHttpServer()).<method>('/api/…')로 부르는 실제 테스트로 바꾸고, api-contract.json의 status를 done으로 바꾼다.
// 실행: npm run test:e2e (todo는 실패가 아니라 '남은 일'로 표시된다)

describe('DEV-15 월간 색 기록과 복원', () => {
  // records.month · 접근: user · 응답: MonthRecordDto · 계약: P06, P07
  it.todo('GET /api/me/records: 한 달 색 기록(사진 기록과 색 복원 구분) → 200');
  it.todo('GET /api/me/records: 로그인 없이 부르면 → 401 AUTH_REQUIRED');
  it.todo('GET /api/me/records: 보낸 값의 형식이 맞지 않아요 → 400 VALIDATION');
  // records.restore · 접근: user · 응답: DayRecordDto · 계약: P01, P03, P06, P07
  it.todo('POST /api/me/records/:date/restore: 지난 빈 날의 색 복원(월 2회) → 201');
  it.todo('POST /api/me/records/:date/restore: 로그인 없이 부르면 → 401 AUTH_REQUIRED');
  it.todo('POST /api/me/records/:date/restore: 보낸 값의 형식이 맞지 않아요 → 400 VALIDATION');
  it.todo('POST /api/me/records/:date/restore: 이번 달 복원 기회를 모두 썼어요 → 409 RESTORE_LIMIT');
  it.todo('POST /api/me/records/:date/restore: 오늘 후보에 없는 색이에요 → 422 COLOR_NOT_CANDIDATE');
  it.todo('POST /api/me/records/:date/restore: 이 날짜는 복원할 수 없어요 → 422 RESTORE_NOT_ALLOWED');
  it.todo('합격 기준(P06): 오늘·미래·다른 달·이미 기록된 날 복원은 거절');
  it.todo('합격 기준: 세 번째 복원은 거절');
  it.todo('합격 기준(P07): 복원으로 issue_count가 바뀌지 않음');
  it.todo('합격 기준(P01·P03): 복원해도 같은 색 방이 열리지 않음');
});

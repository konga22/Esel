// 계약 테스트: stand 모듈. api-contract.json의 API와 루트 docs/dev/features.json의 서버 합격 기준을 할 일(it.todo)로 적어 두었다.
// 이 파일은 손으로 관리한다. API마다 'METHOD /api/경로: … → 상태' 형식의 todo나 테스트가 있어야 하고, 상태 코드는 api-contract.json과 같아야 한다(npm run check:server가 확인).
// 하나를 구현하면 그 todo를 it(…) 안에서 request(app.getHttpServer()).<method>('/api/…')로 부르는 실제 테스트로 바꾸고, api-contract.json의 status를 done으로 바꾼다.
// 실행: npm run test:e2e (todo는 실패가 아니라 '남은 일'로 표시된다)

describe('DEV-12 가판대와 같은 색', () => {
  // stand.get · 접근: user · 응답: StandDto · 계약: P01, P02, P18
  it.todo('GET /api/stand: 가판대·같은 색 방(오늘 발행 전 후보 3색 방은 3장 + 숨긴 개수) → 200');
  it.todo('GET /api/stand: 로그인 없이 부르면 → 401 AUTH_REQUIRED');
  it.todo('GET /api/stand: 보낸 값의 형식이 맞지 않아요 → 400 VALIDATION');
  it.todo('합격 기준(P01): 오늘 발행 전에는 오늘 후보 3색 방이 모두 미리보기: 최신 3장 + hiddenCount만(숨긴 표지의 id·이름·이미지 URL 없음)');
  it.todo('합격 기준(P01): 고른 색을 바꿔도 어느 방도 열리지 않음(후보 3색 모두 그대로 미리보기)');
  it.todo('합격 기준(P02): 후보가 아닌 색 방과 지난 날짜 방은 발행 전에도 전부 열림. 미래 날짜 방은 표지 없이 closed');
  it.todo('합격 기준(P01): 오늘 발행하면 후보 3색 방이 모두 열림');
  it.todo('합격 기준(P01): 서비스 날짜(SERVICE_TIME_ZONE) 자정이 지나면 어제 방은 지난 날짜라 열림');
  it.todo('합격 기준(P01): 미성년자는 잠금 없이 전부 열림(판별 방법은 미정, DEV-02)');
  it.todo('합격 기준(P01·P03·P09): 색 확정·색 복원·트윈 게시로는 어느 방도 열리지 않음');
  it.todo('합격 기준(P18): 같은 색 인원 수는 보여도 반응 숫자는 없음');
});

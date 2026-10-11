// 계약 테스트: auth 모듈. api-contract.json의 API와 docs/dev/FEATURES.md의 합격 기준을 할 일(it.todo)로 적어 두었다.
// 하나를 구현하면 그 it.todo를 실제 요청을 보내는 테스트로 바꾸고, api-contract.json의 status를 done으로 바꾼다.
// 실행: npm run test:e2e (todo는 실패가 아니라 '남은 일'로 표시된다)

describe('DEV-05 로그인', () => {
  // auth.signup · 접근: public · 응답: SessionDto · 계약: P12
  it.todo('POST /api/auth/email/signup: 이메일로 가입 → 201 또는 200');
  it.todo('POST /api/auth/email/signup: 보낸 값의 형식이 맞지 않아요. → 400 VALIDATION');
  it.todo('POST /api/auth/email/signup: 이미 가입한 이메일이에요. → 409 EMAIL_TAKEN');
  it.todo('POST /api/auth/email/signup: 요청이 너무 많아요. → 429 RATE_LIMITED');
  // auth.login · 접근: public · 응답: SessionDto · 계약: P12
  it.todo('POST /api/auth/email/login: 이메일로 로그인 → 201 또는 200');
  it.todo('POST /api/auth/email/login: 보낸 값의 형식이 맞지 않아요. → 400 VALIDATION');
  it.todo('POST /api/auth/email/login: 이메일 또는 비밀번호가 맞지 않아요. → 401 WRONG_CREDENTIALS');
  it.todo('POST /api/auth/email/login: 요청이 너무 많아요. → 429 RATE_LIMITED');
  // auth.refresh · 접근: public · 응답: SessionDto · 계약: P12
  it.todo('POST /api/auth/refresh: refresh token을 회전해 새 토큰 받기 → 201 또는 200');
  it.todo('POST /api/auth/refresh: 로그인이 만료됐어요. → 401 TOKEN_EXPIRED');
  // auth.logout · 접근: user · 응답: void · 계약: P12
  it.todo('POST /api/auth/logout: 이 기기의 로그인 끝내기 → 201 또는 200');
  it.todo('POST /api/auth/logout: 로그인 없이 부르면 401 AUTH_REQUIRED');
  it.todo('합격 기준: 잘못된 비밀번호는 원인과 다시 할 방법을 한 줄로 알림');
  it.todo('합격 기준: refresh token 재사용 시 세션 전체 무효화');
  it.todo('합격 기준: 로그인 후 원래 하려던 동작(예: 좋아요)으로 돌아감');
});

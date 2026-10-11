// 계약 테스트: account 모듈. api-contract.json의 API와 docs/dev/FEATURES.md의 합격 기준을 할 일(it.todo)로 적어 두었다.
// 하나를 구현하면 그 it.todo를 실제 요청을 보내는 테스트로 바꾸고, api-contract.json의 status를 done으로 바꾼다.
// 실행: npm run test:e2e (todo는 실패가 아니라 '남은 일'로 표시된다)

describe('DEV-19 설정과 계정', () => {
  // account.updateProfile · 접근: user · 응답: ProfileOwnerDto · 계약: P14
  it.todo('PATCH /api/me/profile: 제호·소개 바꾸기 → 200');
  it.todo('PATCH /api/me/profile: 로그인 없이 부르면 401 AUTH_REQUIRED');
  it.todo('PATCH /api/me/profile: 보낸 값의 형식이 맞지 않아요. → 400 VALIDATION');
  it.todo('PATCH /api/me/profile: 이름은 영문 소문자 2~10자예요. → 422 MASTHEAD_INVALID');
  it.todo('PATCH /api/me/profile: 이미 있는 이름이에요. → 409 MASTHEAD_TAKEN');
  // account.notifications · 접근: user · 응답: NotificationSettingsDto
  it.todo('GET /api/me/notifications: 알림 설정 보기 → 200');
  it.todo('GET /api/me/notifications: 로그인 없이 부르면 401 AUTH_REQUIRED');
  // account.setNotifications · 접근: user · 응답: NotificationSettingsDto
  it.todo('PUT /api/me/notifications: 알림 설정 바꾸기 → 200');
  it.todo('PUT /api/me/notifications: 로그인 없이 부르면 401 AUTH_REQUIRED');
  it.todo('PUT /api/me/notifications: 보낸 값의 형식이 맞지 않아요. → 400 VALIDATION');
  // account.delete · 접근: user · 응답: void
  it.todo('DELETE /api/me: 탈퇴(삭제 내용 확인 후) → 200 또는 204');
  it.todo('DELETE /api/me: 로그인 없이 부르면 401 AUTH_REQUIRED');
  it.todo('DELETE /api/me: 보낸 값의 형식이 맞지 않아요. → 400 VALIDATION');
  it.todo('합격 기준: 삭제 내용 확인 체크 전에는 다음 단계 비활성');
  it.todo('합격 기준: 탈퇴는 되돌릴 수 없음을 두 번 확인');
  it.todo('합격 기준: 알림을 끄면 하위 알림이 비활성');
});

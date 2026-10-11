// 계약 테스트: profile 모듈. api-contract.json의 API와 docs/dev/FEATURES.md의 합격 기준을 할 일(it.todo)로 적어 두었다.
// 하나를 구현하면 그 it.todo를 실제 요청을 보내는 테스트로 바꾸고, api-contract.json의 status를 done으로 바꾼다.
// 실행: npm run test:e2e (todo는 실패가 아니라 '남은 일'로 표시된다)

describe('DEV-06 창간', () => {
  // mastheads.availability · 접근: user · 응답: MastheadAvailabilityDto · 계약: P14
  it.todo('GET /api/mastheads/:name/availability: 제호(영문 닉네임)를 쓸 수 있는지 확인 → 200');
  it.todo('GET /api/mastheads/:name/availability: 로그인 없이 부르면 401 AUTH_REQUIRED');
  it.todo('GET /api/mastheads/:name/availability: 이름은 영문 소문자 2~10자예요. → 422 MASTHEAD_INVALID');
  // profile.create · 접근: user · 응답: ProfileOwnerDto · 계약: P13, P14
  it.todo('POST /api/profile: 제호를 정해 내 잡지 만들기(창간) → 201 또는 200');
  it.todo('POST /api/profile: 로그인 없이 부르면 401 AUTH_REQUIRED');
  it.todo('POST /api/profile: 보낸 값의 형식이 맞지 않아요. → 400 VALIDATION');
  it.todo('POST /api/profile: 이름은 영문 소문자 2~10자예요. → 422 MASTHEAD_INVALID');
  it.todo('POST /api/profile: 이미 있는 이름이에요. → 409 MASTHEAD_TAKEN');
  it.todo('POST /api/profile: 이미 잡지를 만들었어요. → 409 PROFILE_EXISTS');
  it.todo('합격 기준: 이미 있는 제호는 오류 문구와 함께 다음 버튼 비활성');
  it.todo('합격 기준: 창간 완료 시 개인 호수 Nº 001, 같은 색 방이 열림');
  it.todo('합격 기준: 중간에 앱을 닫았다 열면 마지막 단계부터 이어감');
});

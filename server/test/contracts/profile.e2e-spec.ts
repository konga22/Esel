// 계약 테스트: profile 모듈. api-contract.json의 API와 루트 docs/dev/features.json의 서버 합격 기준을 할 일(it.todo)로 적어 두었다.
// 이 파일은 손으로 관리한다. API마다 'METHOD /api/경로: … → 상태' 형식의 todo나 테스트가 있어야 하고, 상태 코드는 api-contract.json과 같아야 한다(npm run check:server가 확인).
// 하나를 구현하면 그 todo를 it(…) 안에서 request(app.getHttpServer()).<method>('/api/…')로 부르는 실제 테스트로 바꾸고, api-contract.json의 status를 done으로 바꾼다.
// 실행: npm run test:e2e (todo는 실패가 아니라 '남은 일'로 표시된다)

describe('DEV-06 창간', () => {
  // mastheads.availability · 접근: user · 응답: MastheadAvailabilityDto · 계약: P14
  it.todo('GET /api/mastheads/:name/availability: 제호(영문 닉네임)를 쓸 수 있는지 확인 → 200');
  it.todo('GET /api/mastheads/:name/availability: 로그인 없이 부르면 → 401 AUTH_REQUIRED');
  it.todo('GET /api/mastheads/:name/availability: 이름은 영문 소문자 2~10자예요 → 422 MASTHEAD_INVALID');
  // profile.create · 접근: user · 응답: ProfileOwnerDto · 계약: P13, P14
  it.todo('POST /api/profile: 제호를 정해 내 잡지 만들기(창간) → 201');
  it.todo('POST /api/profile: 로그인 없이 부르면 → 401 AUTH_REQUIRED');
  it.todo('POST /api/profile: 보낸 값의 형식이 맞지 않아요 → 400 VALIDATION');
  it.todo('POST /api/profile: 이미 있는 이름이에요 → 409 MASTHEAD_TAKEN');
  it.todo('POST /api/profile: 이미 잡지를 만들었어요 → 409 PROFILE_EXISTS');
  it.todo('POST /api/profile: 이름은 영문 소문자 2~10자예요 → 422 MASTHEAD_INVALID');
  it.todo('합격 기준(P14): 같은 제호를 동시에 요청해도 하나만 성공(profiles.masthead unique)');
  it.todo('합격 기준(P04·P01): 창간호를 발행하면 개인 호수 1호(Nº 001)가 되고 오늘 후보 3색 방이 열림');
});

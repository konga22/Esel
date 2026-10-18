// 계약 테스트: garments 모듈. api-contract.json의 API와 루트 docs/dev/features.json의 서버 합격 기준을 할 일(it.todo)로 적어 두었다.
// 이 파일은 손으로 관리한다. API마다 'METHOD /api/경로: … → 상태' 형식의 todo나 테스트가 있어야 하고, 상태 코드는 api-contract.json과 같아야 한다(npm run check:server가 확인).
// 하나를 구현하면 그 todo를 it(…) 안에서 request(app.getHttpServer()).<method>('/api/…')로 부르는 실제 테스트로 바꾸고, api-contract.json의 status를 done으로 바꾼다.
// 실행: npm run test:e2e (todo는 실패가 아니라 '남은 일'로 표시된다)

describe('DEV-24 착용 정보', () => {
  // garments.mine · 접근: user · 응답: Page<GarmentOwnerDto> · 계약: P19
  it.todo(
    'GET /api/me/garments: 내 옷 목록(같은 옷, 다른 코디에서 다시 고르기, cursor) → 200',
  );
  it.todo('GET /api/me/garments: 로그인 없이 부르면 → 401 AUTH_REQUIRED');
  it.todo(
    'GET /api/me/garments: 보낸 값의 형식이 맞지 않아요 → 400 VALIDATION',
  );
  it.todo('합격 기준(P19): 내 옷만 돌려줌. 다른 사람의 옷은 섞이지 않음');
  it.todo(
    '합격 기준(P19): 응답에 가격·쇼핑 링크 필드가 없음(publicForbiddenFields)',
  );
  it.todo('합격 기준: 탈퇴하면 내 옷과 호에 붙은 착용 정보가 함께 지워짐');
});

import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { App } from 'supertest/types.js';
import { hashToken } from '../../src/auth/session-token.js';
import { PrismaService } from '../../src/prisma/prisma.service.js';
import { createTestApp } from '../create-app.js';

// 계약 테스트: auth 모듈. api-contract.json의 API와 루트 docs/dev/features.json의 서버 합격 기준을 할 일(it.todo)로 적어 두었다.
// 이 파일은 손으로 관리한다. API마다 'METHOD /api/경로: … → 상태' 형식의 todo나 테스트가 있어야 하고, 상태 코드는 api-contract.json과 같아야 한다(npm run check:server가 확인).
// 하나를 구현하면 그 todo를 it(…) 안에서 request(app.getHttpServer()).<method>('/api/…')로 부르는 실제 테스트로 바꾸고, api-contract.json의 status를 done으로 바꾼다.
// 실행: npm run test:e2e (todo는 실패가 아니라 '남은 일'로 표시된다)

describe('DEV-05 로그인', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;

  beforeAll(async () => {
    app = await createTestApp();
    prisma = app.get(PrismaService);
    await cleanupSignupFixtures();
  });

  afterEach(async () => {
    await cleanupSignupFixtures();
  });

  async function cleanupSignupFixtures() {
    await prisma.user.deleteMany({
      where: { email: { endsWith: '@signup.e2e.test' } },
    });
  }

  afterAll(async () => {
    await app.close();
  });

  // auth.signup · 접근: public · 응답: SessionDto · 계약: P12
  it('POST /api/auth/email/signup: 이메일로 가입 → 201', async () => {
    const password = 'correct horse battery staple';
    const response = await request(app.getHttpServer())
      .post('/api/auth/email/signup')
      .send({ email: 'new@signup.e2e.test', password })
      .expect(201);

    expect(response.body).toMatchObject({
      email: 'new@signup.e2e.test',
      masthead: '',
      profileImageUrl: null,
      hasPublishedToday: false,
      issueCount: 0,
      isMinor: false,
    });
    expect(response.body.userId).toMatch(
      /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i,
    );
    expect(response.body.accessToken).toEqual(expect.any(String));
    expect(response.body.refreshToken).toEqual(expect.any(String));

    const user = await prisma.user.findUniqueOrThrow({
      where: { email: 'new@signup.e2e.test' },
      include: { emailCredential: true, authSessions: true },
    });
    expect(user.emailCredential?.passwordHash).not.toContain(password);
    expect(user.authSessions).toHaveLength(1);
    expect(user.authSessions[0]?.accessTokenHash).toBe(
      hashToken(response.body.accessToken as string),
    );
    expect(user.authSessions[0]?.refreshTokenHash).toBe(
      hashToken(response.body.refreshToken as string),
    );
    expect(JSON.stringify(user)).not.toContain(response.body.refreshToken);
  });

  it('POST /api/auth/email/signup: 보낸 값의 형식이 맞지 않아요 → 400 VALIDATION', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/auth/email/signup')
      .send({ email: 'not-an-email', password: 'short' })
      .expect(400);

    expect(response.body.error).toMatchObject({
      code: 'VALIDATION',
      message: '보낸 값의 형식이 맞지 않아요.',
    });
    expect(response.body.error.details).toBeDefined();
  });

  it('POST /api/auth/email/signup: 이미 가입한 이메일이에요 → 409 EMAIL_TAKEN', async () => {
    await request(app.getHttpServer())
      .post('/api/auth/email/signup')
      .send({
        email: 'duplicate@signup.e2e.test',
        password: 'first password',
      })
      .expect(201);

    const response = await request(app.getHttpServer())
      .post('/api/auth/email/signup')
      .send({
        email: ' DUPLICATE@signup.e2e.test ',
        password: 'second password',
      })
      .expect(409);

    expect(response.body.error.code).toBe('EMAIL_TAKEN');
  });

  it('POST /api/auth/email/signup: 요청이 너무 많아요 → 429 RATE_LIMITED', async () => {
    const payload = {
      email: 'limited@signup.e2e.test',
      password: 'long enough password',
    };
    await request(app.getHttpServer())
      .post('/api/auth/email/signup')
      .send(payload)
      .expect(201);
    for (let attempt = 0; attempt < 4; attempt += 1) {
      await request(app.getHttpServer())
        .post('/api/auth/email/signup')
        .send(payload)
        .expect(409);
    }
    const response = await request(app.getHttpServer())
      .post('/api/auth/email/signup')
      .send(payload)
      .expect(429);

    expect(response.body.error.code).toBe('RATE_LIMITED');
  });
  // auth.login · 접근: public · 응답: SessionDto · 계약: P12
  it.todo('POST /api/auth/email/login: 이메일로 로그인 → 201');
  it.todo(
    'POST /api/auth/email/login: 보낸 값의 형식이 맞지 않아요 → 400 VALIDATION',
  );
  it.todo(
    'POST /api/auth/email/login: 이메일 또는 비밀번호가 맞지 않아요 → 401 WRONG_CREDENTIALS',
  );
  it.todo('POST /api/auth/email/login: 요청이 너무 많아요 → 429 RATE_LIMITED');
  // auth.refresh · 접근: public · 응답: SessionDto · 계약: P12
  it.todo('POST /api/auth/refresh: refresh token을 회전해 새 토큰 받기 → 201');
  it.todo(
    'POST /api/auth/refresh: 보낸 값의 형식이 맞지 않아요 → 400 VALIDATION',
  );
  it.todo('POST /api/auth/refresh: 로그인이 필요해요 → 401 AUTH_REQUIRED');
  it.todo('POST /api/auth/refresh: 로그인이 만료됐어요 → 401 TOKEN_EXPIRED');
  // auth.logout · 접근: user · 응답: void · 계약: P12
  it.todo('POST /api/auth/logout: 이 기기의 로그인 끝내기 → 204');
  it.todo('POST /api/auth/logout: 로그인 없이 부르면 → 401 AUTH_REQUIRED');
  it.todo(
    '합격 기준: refresh token을 다시 쓰면(재사용) 그 사용자의 세션 전체가 무효가 됨',
  );
  it.todo('합격 기준: 비밀번호와 refresh token 원문은 DB에 없음(해시만 저장)');
});

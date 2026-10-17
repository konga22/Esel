import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { App } from 'supertest/types.js';
import { PrismaService } from '../../src/prisma/prisma.service.js';
import { createTestApp } from '../create-app.js';

// 계약 테스트: profile 모듈. api-contract.json의 API와 루트 docs/dev/features.json의 서버 합격 기준을 할 일(it.todo)로 적어 두었다.
// 이 파일은 손으로 관리한다. API마다 'METHOD /api/경로: … → 상태' 형식의 todo나 테스트가 있어야 하고, 상태 코드는 api-contract.json과 같아야 한다(npm run check:server가 확인).
// 하나를 구현하면 그 todo를 it(…) 안에서 request(app.getHttpServer()).<method>('/api/…')로 부르는 실제 테스트로 바꾸고, api-contract.json의 status를 done으로 바꾼다.
// 실행: npm run test:e2e (todo는 실패가 아니라 '남은 일'로 표시된다)

describe('DEV-06 창간', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;

  beforeAll(async () => {
    app = await createTestApp();
    prisma = app.get(PrismaService);
    await cleanupFixtures();
  });

  afterEach(cleanupFixtures);

  afterAll(async () => {
    await app.close();
  });

  async function cleanupFixtures() {
    await prisma.user.deleteMany({
      where: { email: { endsWith: '@profile.e2e.test' } },
    });
  }

  async function signup(name: string) {
    const response = await request(app.getHttpServer())
      .post('/api/auth/email/signup')
      .send({
        email: `${name}@profile.e2e.test`,
        password: 'correct horse battery staple',
      })
      .expect(201);
    return {
      userId: response.body.userId as string,
      token: response.body.accessToken as string,
    };
  }

  // mastheads.availability · 접근: user · 응답: MastheadAvailabilityDto · 계약: P14
  it('GET /api/mastheads/:name/availability: 제호(영문 닉네임)를 쓸 수 있는지 확인 → 200', async () => {
    const checking = await signup('checking');
    const owner = await signup('owner');
    await prisma.profile.create({
      data: { userId: owner.userId, masthead: 'taken' },
    });

    const available = await request(app.getHttpServer())
      .get('/api/mastheads/fresh/availability')
      .set('Authorization', `Bearer ${checking.token}`)
      .expect(200);
    const unavailable = await request(app.getHttpServer())
      .get('/api/mastheads/taken/availability')
      .set('Authorization', `Bearer ${checking.token}`)
      .expect(200);

    expect(available.body).toEqual({ masthead: 'fresh', available: true });
    expect(unavailable.body).toEqual({ masthead: 'taken', available: false });
  });

  it('GET /api/mastheads/:name/availability: 로그인 없이 부르면 → 401 AUTH_REQUIRED', async () => {
    const response = await request(app.getHttpServer())
      .get('/api/mastheads/fresh/availability')
      .expect(401);
    expect(response.body.error.code).toBe('AUTH_REQUIRED');
  });

  it('GET /api/mastheads/:name/availability: 이름은 영문 소문자 2~10자예요 → 422 MASTHEAD_INVALID', async () => {
    const user = await signup('invalid-name');
    for (const name of ['A', 'UPPERCASE', 'name-1', 'abcdefghijkl']) {
      const response = await request(app.getHttpServer())
        .get(`/api/mastheads/${name}/availability`)
        .set('Authorization', `Bearer ${user.token}`)
        .expect(422);
      expect(response.body.error.code).toBe('MASTHEAD_INVALID');
    }
  });
  // profile.create · 접근: user · 응답: ProfileOwnerDto · 계약: P13, P14
  it('POST /api/profile: 제호를 정해 내 잡지 만들기(창간) → 201', async () => {
    const user = await signup('create');
    const response = await request(app.getHttpServer())
      .post('/api/profile')
      .set('Authorization', `Bearer ${user.token}`)
      .send({ masthead: 'selin' })
      .expect(201);

    expect(response.body).toEqual({
      id: expect.any(String),
      masthead: 'selin',
      issueCount: 0,
    });
    expect(
      await prisma.profile.findUnique({ where: { userId: user.userId } }),
    ).toMatchObject({ masthead: 'selin', issueCount: 0 });
  });

  it('POST /api/profile: 로그인 없이 부르면 → 401 AUTH_REQUIRED', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/profile')
      .send({ masthead: 'selin' })
      .expect(401);
    expect(response.body.error.code).toBe('AUTH_REQUIRED');
  });

  it('POST /api/profile: 보낸 값의 형식이 맞지 않아요 → 400 VALIDATION', async () => {
    const user = await signup('validation');
    const response = await request(app.getHttpServer())
      .post('/api/profile')
      .set('Authorization', `Bearer ${user.token}`)
      .send({ masthead: 123 })
      .expect(400);
    expect(response.body.error.code).toBe('VALIDATION');
  });

  it('POST /api/profile: 이미 있는 이름이에요 → 409 MASTHEAD_TAKEN', async () => {
    const owner = await signup('taken-owner');
    const checking = await signup('taken-checking');
    await prisma.profile.create({
      data: { userId: owner.userId, masthead: 'taken' },
    });
    const response = await request(app.getHttpServer())
      .post('/api/profile')
      .set('Authorization', `Bearer ${checking.token}`)
      .send({ masthead: 'taken' })
      .expect(409);
    expect(response.body.error.code).toBe('MASTHEAD_TAKEN');
  });

  it('POST /api/profile: 이미 잡지를 만들었어요 → 409 PROFILE_EXISTS', async () => {
    const user = await signup('existing');
    await prisma.profile.create({
      data: { userId: user.userId, masthead: 'first' },
    });
    const response = await request(app.getHttpServer())
      .post('/api/profile')
      .set('Authorization', `Bearer ${user.token}`)
      .send({ masthead: 'second' })
      .expect(409);
    expect(response.body.error.code).toBe('PROFILE_EXISTS');
  });

  it('POST /api/profile: 이름은 영문 소문자 2~10자예요 → 422 MASTHEAD_INVALID', async () => {
    const user = await signup('invalid-create');
    const response = await request(app.getHttpServer())
      .post('/api/profile')
      .set('Authorization', `Bearer ${user.token}`)
      .send({ masthead: 'Selin' })
      .expect(422);
    expect(response.body.error.code).toBe('MASTHEAD_INVALID');
  });

  it('합격 기준(P14): 같은 제호를 동시에 요청해도 하나만 성공(profiles.masthead unique)', async () => {
    const first = await signup('race-a');
    const second = await signup('race-b');
    const responses = await Promise.all([
      request(app.getHttpServer())
        .post('/api/profile')
        .set('Authorization', `Bearer ${first.token}`)
        .send({ masthead: 'shared' }),
      request(app.getHttpServer())
        .post('/api/profile')
        .set('Authorization', `Bearer ${second.token}`)
        .send({ masthead: 'shared' }),
    ]);

    expect(responses.map(({ status }) => status).sort((a, b) => a - b)).toEqual(
      [201, 409],
    );
    expect(
      responses.find(({ status }) => status === 409)?.body.error.code,
    ).toBe('MASTHEAD_TAKEN');
    expect(await prisma.profile.count({ where: { masthead: 'shared' } })).toBe(
      1,
    );
  });
  it.todo(
    '합격 기준(P04·P01): 창간호를 발행하면 개인 호수 1호(Nº 001)가 되고 오늘 후보 3색 방이 열림',
  );
});

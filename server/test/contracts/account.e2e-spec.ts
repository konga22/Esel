import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { App } from 'supertest/types.js';
import { PrismaService } from '../../src/prisma/prisma.service.js';
import { createTestApp } from '../create-app.js';

// 계약 테스트: account 모듈. api-contract.json의 API와 루트 docs/dev/features.json의 서버 합격 기준을 할 일(it.todo)로 적어 두었다.
// 이 파일은 손으로 관리한다. API마다 'METHOD /api/경로: … → 상태' 형식의 todo나 테스트가 있어야 하고, 상태 코드는 api-contract.json과 같아야 한다(npm run check:server가 확인).
// 하나를 구현하면 그 todo를 it(…) 안에서 request(app.getHttpServer()).<method>('/api/…')로 부르는 실제 테스트로 바꾸고, api-contract.json의 status를 done으로 바꾼다.
// 실행: npm run test:e2e (todo는 실패가 아니라 '남은 일'로 표시된다)

describe('DEV-19 설정과 계정', () => {
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
      where: { email: { endsWith: '@account.e2e.test' } },
    });
  }

  async function signup(name: string) {
    const response = await request(app.getHttpServer())
      .post('/api/auth/email/signup')
      .send({
        email: `${name}@account.e2e.test`,
        password: 'correct horse battery staple',
      })
      .expect(201);
    return {
      userId: response.body.userId as string,
      token: response.body.accessToken as string,
    };
  }

  // account.updateProfile · 접근: user · 응답: ProfileOwnerDto · 계약: P14
  it.todo('PATCH /api/me/profile: 제호·소개 바꾸기 → 200');
  it.todo('PATCH /api/me/profile: 로그인 없이 부르면 → 401 AUTH_REQUIRED');
  it.todo(
    'PATCH /api/me/profile: 보낸 값의 형식이 맞지 않아요 → 400 VALIDATION',
  );
  it.todo('PATCH /api/me/profile: 이미 있는 이름이에요 → 409 MASTHEAD_TAKEN');
  it.todo(
    'PATCH /api/me/profile: 이름은 영문 소문자 2~10자예요 → 422 MASTHEAD_INVALID',
  );
  // account.notifications · 접근: user · 응답: NotificationSettingsDto
  it('GET /api/me/notifications: 알림 설정 보기 → 200', async () => {
    const user = await signup('notifications-get');
    const response = await request(app.getHttpServer())
      .get('/api/me/notifications')
      .set('Authorization', `Bearer ${user.token}`)
      .expect(200);

    expect(response.body).toEqual({
      enabled: true,
      newIssue: true,
      reactions: true,
    });
    expect(
      await prisma.notificationSettings.count({
        where: { userId: user.userId },
      }),
    ).toBe(0);
  });

  it('GET /api/me/notifications: 로그인 없이 부르면 → 401 AUTH_REQUIRED', async () => {
    const response = await request(app.getHttpServer())
      .get('/api/me/notifications')
      .expect(401);
    expect(response.body.error.code).toBe('AUTH_REQUIRED');
  });

  // account.setNotifications · 접근: user · 응답: NotificationSettingsDto
  it('PUT /api/me/notifications: 알림 설정 바꾸기 → 200', async () => {
    const user = await signup('notifications-put');
    const input = { enabled: true, newIssue: false, reactions: true };
    const response = await request(app.getHttpServer())
      .put('/api/me/notifications')
      .set('Authorization', `Bearer ${user.token}`)
      .send(input)
      .expect(200);

    expect(response.body).toEqual(input);
    expect(
      await prisma.notificationSettings.findUnique({
        where: { userId: user.userId },
      }),
    ).toMatchObject(input);
  });

  it('PUT /api/me/notifications: 로그인 없이 부르면 → 401 AUTH_REQUIRED', async () => {
    const response = await request(app.getHttpServer())
      .put('/api/me/notifications')
      .send({ enabled: true, newIssue: true, reactions: true })
      .expect(401);
    expect(response.body.error.code).toBe('AUTH_REQUIRED');
  });

  it('PUT /api/me/notifications: 보낸 값의 형식이 맞지 않아요 → 400 VALIDATION', async () => {
    const user = await signup('notifications-invalid');
    const response = await request(app.getHttpServer())
      .put('/api/me/notifications')
      .set('Authorization', `Bearer ${user.token}`)
      .send({ enabled: 'yes', newIssue: true })
      .expect(400);
    expect(response.body.error.code).toBe('VALIDATION');
  });
  // account.delete · 접근: user · 응답: void
  it.todo('DELETE /api/me: 탈퇴(삭제 내용 확인 후) → 204');
  it.todo('DELETE /api/me: 로그인 없이 부르면 → 401 AUTH_REQUIRED');
  it.todo('DELETE /api/me: 보낸 값의 형식이 맞지 않아요 → 400 VALIDATION');
});

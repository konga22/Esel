import { INestApplication } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import { App } from 'supertest/types.js';
import { PrismaService } from '../../src/prisma/prisma.service.js';
import { createTestApp } from '../create-app.js';

describe('DEV-18 공유', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  let mastheadSequence = 0;

  beforeAll(async () => {
    app = await createTestApp();
    prisma = app.get(PrismaService);
    await cleanup();
  });
  afterEach(cleanup);
  afterAll(async () => app.close());

  async function cleanup() {
    await prisma.issue.deleteMany({
      where: { author: { email: { endsWith: '@share.e2e.test' } } },
    });
    await prisma.user.deleteMany({
      where: { email: { endsWith: '@share.e2e.test' } },
    });
  }

  async function signup(label: string) {
    const response = await request(app.getHttpServer())
      .post('/api/auth/email/signup')
      .send({
        email: `${label}-${randomUUID()}@share.e2e.test`,
        password: 'correct horse battery staple',
      })
      .expect(201);
    const user = {
      id: response.body.userId as string,
      token: response.body.accessToken as string,
      masthead: `share${String.fromCharCode(97 + mastheadSequence++)}`,
    };
    await prisma.profile.create({
      data: { userId: user.id, masthead: user.masthead },
    });
    return user;
  }

  async function pastIssue(userId: string) {
    const media = await prisma.mediaAsset.create({
      data: {
        ownerId: userId,
        storageKey: `share/${randomUUID()}`,
        status: 'READY',
        mimeType: 'image/jpeg',
        sizeBytes: 24,
      },
    });
    return prisma.issue.create({
      data: {
        authorId: userId,
        serviceDate: new Date('2020-01-01T00:00:00.000Z'),
        issueNumber: 1,
        colorId: 'sage',
        mediaId: media.id,
        caption: '공유할 표지',
        faceMode: 'PLAIN',
      },
    });
  }

  const auth = (token: string) => ({ Authorization: `Bearer ${token}` });

  it('POST /api/share-links: 공개된 표지·공동 트윈의 공유 링크 만들기 → 201', async () => {
    const owner = await signup('owner');
    const issue = await pastIssue(owner.id);
    const response = await request(app.getHttpServer())
      .post('/api/share-links')
      .set(auth(owner.token))
      .send({ issueId: issue.id })
      .expect(201);
    expect(response.body).toEqual({
      token: expect.any(String),
      path: `/api/share-links/${response.body.token}`,
      createdAt: expect.any(String),
    });
    expect(JSON.stringify(response.body)).not.toMatch(
      /userId|issueId|twinId|Count|rank/,
    );
  });

  it('POST /api/share-links: 로그인 없이 부르면 → 401 AUTH_REQUIRED', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/share-links')
      .send({ issueId: randomUUID() })
      .expect(401);
    expect(response.body.error.code).toBe('AUTH_REQUIRED');
  });

  it('POST /api/share-links: 보낸 값의 형식이 맞지 않아요 → 400 VALIDATION', async () => {
    const owner = await signup('invalid');
    for (const body of [
      {},
      { issueId: 'bad' },
      { issueId: randomUUID(), twinId: randomUUID() },
    ]) {
      const response = await request(app.getHttpServer())
        .post('/api/share-links')
        .set(auth(owner.token))
        .send(body)
        .expect(400);
      expect(response.body.error.code).toBe('VALIDATION');
    }
  });

  it('POST /api/share-links: 없거나 나에게 잠긴 표지·트윈 → 404 NOT_FOUND', async () => {
    const owner = await signup('missing');
    const response = await request(app.getHttpServer())
      .post('/api/share-links')
      .set(auth(owner.token))
      .send({ issueId: randomUUID() })
      .expect(404);
    expect(response.body.error.code).toBe('NOT_FOUND');
  });

  it('POST /api/share-links: 공개된 표지만 공유할 수 있어요 → 422 SHARE_NOT_PUBLIC', async () => {
    const owner = await signup('private-twin');
    const twin = await prisma.twin.create({
      data: {
        serviceDate: new Date('2020-01-01T00:00:00.000Z'),
        participations: {
          create: {
            userId: owner.id,
            serviceDate: new Date('2020-01-01T00:00:00.000Z'),
            role: 'INVITER',
          },
        },
      },
    });
    const response = await request(app.getHttpServer())
      .post('/api/share-links')
      .set(auth(owner.token))
      .send({ twinId: twin.id })
      .expect(422);
    expect(response.body.error.code).toBe('SHARE_NOT_PUBLIC');
  });

  // 비로그인 오늘 표지 공개 정책을 정한 뒤 구현한다.
  it.todo(
    'GET /api/share-links/:token: 공유 링크 열기(열 때도 공개 권한 다시 검사) → 200',
  );
  it.todo(
    'GET /api/share-links/:token: 없거나 지운 링크, 또는 이제 볼 수 없는 표지 → 404 NOT_FOUND',
  );
  it.todo(
    '합격 기준(P01): 로그인한 사람이 링크를 열면 그 사람 기준으로 같은 색 잠금을 다시 검사해, 잠긴 표지면 404',
  );
});

import { INestApplication } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import { App } from 'supertest/types.js';
import { PrismaService } from '../../src/prisma/prisma.service.js';
import { serviceDate } from '../../src/common/service-date.js';
import { createTestApp } from '../create-app.js';

describe('DEV-18 공유', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  let mastheadSequence = 0;
  let timeZone: string;

  beforeAll(async () => {
    app = await createTestApp();
    prisma = app.get(PrismaService);
    timeZone = app.get(ConfigService).getOrThrow<string>('SERVICE_TIME_ZONE');
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

  async function issue(
    userId: string,
    options: {
      date: Date;
      colorId?: string;
      publishedAt?: Date;
      issueNumber?: number;
    },
  ) {
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
        serviceDate: options.date,
        issueNumber: options.issueNumber ?? 1,
        colorId: options.colorId ?? 'sage',
        mediaId: media.id,
        caption: '공유할 표지',
        faceMode: 'PLAIN',
        publishedAt: options.publishedAt,
      },
    });
  }

  const pastIssue = (userId: string) =>
    issue(userId, { date: new Date('2020-01-01T00:00:00.000Z') });

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

  it('GET /api/share-links/:token: 공유 링크 열기(열 때도 공개 권한 다시 검사) → 200', async () => {
    const owner = await signup('open-owner');
    const target = await pastIssue(owner.id);
    const created = await request(app.getHttpServer())
      .post('/api/share-links')
      .set(auth(owner.token))
      .send({ issueId: target.id })
      .expect(201);
    const response = await request(app.getHttpServer())
      .get(`/api/share-links/${created.body.token}`)
      .expect(200);
    expect(response.body).toMatchObject({
      kind: 'ISSUE',
      issue: { masthead: owner.masthead, caption: '공유할 표지' },
      twin: null,
    });
    expect(JSON.stringify(response.body)).not.toMatch(
      /userId|likeCount|scrapCount|lineCount|rank/,
    );
  });

  it('GET /api/share-links/:token: 없거나 지운 링크, 또는 이제 볼 수 없는 표지 → 404 NOT_FOUND', async () => {
    const response = await request(app.getHttpServer())
      .get('/api/share-links/not-a-link')
      .expect(404);
    expect(response.body.error.code).toBe('NOT_FOUND');
  });

  it('합격 기준(P01): 로그인한 사람이 링크를 열면 그 사람 기준으로 같은 색 잠금을 다시 검사해, 잠긴 표지면 404', async () => {
    const reader = await signup('locked-reader');
    const today = await request(app.getHttpServer())
      .get('/api/today')
      .set(auth(reader.token))
      .expect(200);
    const colorId = today.body.candidates[0].id as string;
    const date = new Date(`${serviceDate(new Date(), timeZone)}T00:00:00.000Z`);
    let oldest: Awaited<ReturnType<typeof issue>> | null = null;
    let oldestOwner: Awaited<ReturnType<typeof signup>> | null = null;
    for (let index = 0; index < 4; index += 1) {
      const author = await signup(`locked-author-${index}`);
      const created = await issue(author.id, {
        date,
        colorId,
        publishedAt: new Date(10_000 + index),
      });
      if (index === 0) {
        oldest = created;
        oldestOwner = author;
      }
    }
    const link = await request(app.getHttpServer())
      .post('/api/share-links')
      .set(auth(oldestOwner!.token))
      .send({ issueId: oldest!.id })
      .expect(201);
    const response = await request(app.getHttpServer())
      .get(`/api/share-links/${link.body.token}`)
      .set(auth(reader.token))
      .expect(404);
    expect(response.body.error.code).toBe('NOT_FOUND');
  });
});

import { INestApplication } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import { App } from 'supertest/types.js';
import { serviceDate } from '../../src/common/service-date.js';
import { PrismaService } from '../../src/prisma/prisma.service.js';
import { createTestApp } from '../create-app.js';

// 계약 테스트: magazines 모듈. api-contract.json의 API와 루트 docs/dev/features.json의 서버 합격 기준을 할 일(it.todo)로 적어 두었다.
// 이 파일은 손으로 관리한다. API마다 'METHOD /api/경로: … → 상태' 형식의 todo나 테스트가 있어야 하고, 상태 코드는 api-contract.json과 같아야 한다(npm run check:server가 확인).
// 하나를 구현하면 그 todo를 it(…) 안에서 request(app.getHttpServer()).<method>('/api/…')로 부르는 실제 테스트로 바꾸고, api-contract.json의 status를 done으로 바꾼다.
// 실행: npm run test:e2e (todo는 실패가 아니라 '남은 일'로 표시된다)

describe('DEV-13 서가와 구독', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  let timeZone: string;
  let mastheadSequence = 0;

  beforeAll(async () => {
    app = await createTestApp();
    prisma = app.get(PrismaService);
    timeZone = app.get(ConfigService).getOrThrow<string>('SERVICE_TIME_ZONE');
    await cleanupFixtures();
  });

  afterEach(cleanupFixtures);
  afterAll(async () => app.close());

  async function cleanupFixtures() {
    await prisma.issue.deleteMany({
      where: { author: { email: { endsWith: '@magazines.e2e.test' } } },
    });
    await prisma.user.deleteMany({
      where: { email: { endsWith: '@magazines.e2e.test' } },
    });
  }

  function nextMasthead(): string {
    let number = mastheadSequence++;
    let suffix = '';
    do {
      suffix = String.fromCharCode(97 + (number % 26)) + suffix;
      number = Math.floor(number / 26) - 1;
    } while (number >= 0);
    return `shelf${suffix}`;
  }

  async function signup(name: string) {
    const response = await request(app.getHttpServer())
      .post('/api/auth/email/signup')
      .send({
        email: `${name}-${randomUUID()}@magazines.e2e.test`,
        password: 'correct horse battery staple',
      })
      .expect(201);
    const user = {
      userId: response.body.userId as string,
      token: response.body.accessToken as string,
      masthead: nextMasthead(),
    };
    await prisma.profile.create({
      data: { userId: user.userId, masthead: user.masthead },
    });
    return user;
  }

  function dateAt(offsetDays: number): Date {
    const key = serviceDate(new Date(), timeZone);
    const date = new Date(`${key}T00:00:00.000Z`);
    date.setUTCDate(date.getUTCDate() + offsetDays);
    return date;
  }

  async function createIssue(
    author: { userId: string },
    options: {
      serviceDate?: Date;
      colorId?: string;
      issueNumber?: number;
      publishedAt?: Date;
    } = {},
  ) {
    const media = await prisma.mediaAsset.create({
      data: {
        ownerId: author.userId,
        storageKey: `magazines-e2e/${randomUUID()}`,
        status: 'READY',
        mimeType: 'image/png',
        sizeBytes: 24,
        width: 1080,
        height: 1440,
      },
    });
    return prisma.issue.create({
      data: {
        authorId: author.userId,
        serviceDate: options.serviceDate ?? dateAt(-1),
        issueNumber: options.issueNumber ?? 1,
        colorId: options.colorId ?? 'sage',
        mediaId: media.id,
        caption: '서가의 한 호',
        faceCrop: 'ORIGINAL',
        paintStroke: false,
        publishedAt: options.publishedAt,
      },
    });
  }

  const auth = (token: string) => ({ Authorization: `Bearer ${token}` });

  // magazines.get · 접근: user · 응답: MagazinePublicDto · 계약: P01, P02, P04, P18
  it('GET /api/magazines/:masthead: 남의 잡지(서가)와 지난 호 → 200', async () => {
    const owner = await signup('get-owner');
    const reader = await signup('get-reader');
    const issue = await createIssue(owner);
    await prisma.profile.update({
      where: { userId: owner.userId },
      data: { issueCount: 1 },
    });

    const response = await request(app.getHttpServer())
      .get(`/api/magazines/${owner.masthead}`)
      .set(auth(reader.token))
      .expect(200);
    expect(response.body).toMatchObject({
      masthead: owner.masthead,
      issueCount: 1,
      isSubscribed: false,
      nextCursor: null,
      issues: [{ id: issue.id, issueNumber: 1 }],
    });
    expect(response.body).not.toHaveProperty('subscriberCount');
    expect(response.body.issues[0]).not.toHaveProperty('likeCount');
  });

  it('GET /api/magazines/:masthead: 로그인 없이 부르면 → 401 AUTH_REQUIRED', async () => {
    const response = await request(app.getHttpServer())
      .get('/api/magazines/unknown')
      .expect(401);
    expect(response.body.error.code).toBe('AUTH_REQUIRED');
  });

  it('GET /api/magazines/:masthead: 없는 제호 → 404 NOT_FOUND', async () => {
    const reader = await signup('get-missing');
    const response = await request(app.getHttpServer())
      .get('/api/magazines/unknown')
      .set(auth(reader.token))
      .expect(404);
    expect(response.body.error.code).toBe('NOT_FOUND');
  });

  it('서가는 20호씩 cursor로 이어지고 cursor에 숨은 호 ID를 넣지 않음', async () => {
    const owner = await signup('cursor-owner');
    const reader = await signup('cursor-reader');
    for (let issueNumber = 1; issueNumber <= 21; issueNumber += 1) {
      await createIssue(owner, {
        serviceDate: dateAt(-issueNumber),
        issueNumber,
      });
    }
    await prisma.profile.update({
      where: { userId: owner.userId },
      data: { issueCount: 21 },
    });

    const first = await request(app.getHttpServer())
      .get(`/api/magazines/${owner.masthead}`)
      .set(auth(reader.token))
      .expect(200);
    expect(first.body.issues).toHaveLength(20);
    expect(first.body.nextCursor).toEqual(expect.any(String));
    const cursorBody = JSON.parse(
      Buffer.from(first.body.nextCursor, 'base64url').toString('utf8'),
    ) as Record<string, unknown>;
    expect(cursorBody).toEqual({ before: 2 });

    const second = await request(app.getHttpServer())
      .get(`/api/magazines/${owner.masthead}`)
      .query({ cursor: first.body.nextCursor })
      .set(auth(reader.token))
      .expect(200);
    expect(second.body.issues).toEqual([
      expect.objectContaining({ issueNumber: 1 }),
    ]);
    expect(second.body.nextCursor).toBeNull();
  });

  // magazines.subscribe · 접근: user · 응답: SubscriptionStateDto · 계약: P12, P18
  it('POST /api/magazines/:masthead/subscription: 구독 → 201', async () => {
    const owner = await signup('subscribe-owner');
    const reader = await signup('subscribe-reader');
    for (let attempt = 0; attempt < 2; attempt += 1) {
      const response = await request(app.getHttpServer())
        .post(`/api/magazines/${owner.masthead}/subscription`)
        .set(auth(reader.token))
        .expect(201);
      expect(response.body).toEqual({ subscribed: true });
    }
    expect(
      await prisma.subscription.count({
        where: { subscriberId: reader.userId, magazineId: owner.userId },
      }),
    ).toBe(1);
    const magazine = await request(app.getHttpServer())
      .get(`/api/magazines/${owner.masthead}`)
      .set(auth(reader.token))
      .expect(200);
    expect(magazine.body.isSubscribed).toBe(true);
  });

  it('POST /api/magazines/:masthead/subscription: 로그인 없이 부르면 → 401 AUTH_REQUIRED', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/magazines/unknown/subscription')
      .expect(401);
    expect(response.body.error.code).toBe('AUTH_REQUIRED');
  });

  it('POST /api/magazines/:masthead/subscription: 없는 제호 → 404 NOT_FOUND', async () => {
    const reader = await signup('subscribe-missing');
    const response = await request(app.getHttpServer())
      .post('/api/magazines/unknown/subscription')
      .set(auth(reader.token))
      .expect(404);
    expect(response.body.error.code).toBe('NOT_FOUND');
  });

  // magazines.unsubscribe · 접근: user · 응답: SubscriptionStateDto · 계약: P12
  it('DELETE /api/magazines/:masthead/subscription: 구독 취소 → 200', async () => {
    const owner = await signup('unsubscribe-owner');
    const reader = await signup('unsubscribe-reader');
    await prisma.subscription.create({
      data: { subscriberId: reader.userId, magazineId: owner.userId },
    });
    for (let attempt = 0; attempt < 2; attempt += 1) {
      const response = await request(app.getHttpServer())
        .delete(`/api/magazines/${owner.masthead}/subscription`)
        .set(auth(reader.token))
        .expect(200);
      expect(response.body).toEqual({ subscribed: false });
    }
    expect(
      await prisma.subscription.count({
        where: { subscriberId: reader.userId, magazineId: owner.userId },
      }),
    ).toBe(0);
  });

  it('DELETE /api/magazines/:masthead/subscription: 로그인 없이 부르면 → 401 AUTH_REQUIRED', async () => {
    const response = await request(app.getHttpServer())
      .delete('/api/magazines/unknown/subscription')
      .expect(401);
    expect(response.body.error.code).toBe('AUTH_REQUIRED');
  });

  it('DELETE /api/magazines/:masthead/subscription: 없는 제호 → 404 NOT_FOUND', async () => {
    const reader = await signup('unsubscribe-missing');
    const response = await request(app.getHttpServer())
      .delete('/api/magazines/unknown/subscription')
      .set(auth(reader.token))
      .expect(404);
    expect(response.body.error.code).toBe('NOT_FOUND');
  });

  it('합격 기준(P18): 서가 응답에 구독자 수가 없음', async () => {
    const owner = await signup('p18-owner');
    const reader = await signup('p18-reader');
    const response = await request(app.getHttpServer())
      .get(`/api/magazines/${owner.masthead}`)
      .set(auth(reader.token))
      .expect(200);
    expect(response.body).not.toHaveProperty('subscriberCount');
    expect(response.body).not.toHaveProperty('subscriptionCount');
  });

  it('합격 기준(P01): 그 사람의 오늘 호가 내 오늘 후보 색이고 미리보기 3장 밖이면 id·사진 없이 숨김(내가 발행하면 보임)', async () => {
    const reader = await signup('p01-reader');
    const today = await request(app.getHttpServer())
      .get('/api/today')
      .set(auth(reader.token))
      .expect(200);
    const colorId = today.body.candidates[0].id as string;
    const owner = await signup('p01-owner');
    const locked = await createIssue(owner, {
      serviceDate: dateAt(0),
      colorId,
      publishedAt: new Date('2000-01-01T00:00:00.000Z'),
    });
    for (let index = 0; index < 3; index += 1) {
      const previewOwner = await signup(`p01-preview-${index}`);
      await createIssue(previewOwner, {
        serviceDate: dateAt(0),
        colorId,
        publishedAt: new Date(`2099-03-0${index + 1}T00:00:00.000Z`),
      });
    }

    const hidden = await request(app.getHttpServer())
      .get(`/api/magazines/${owner.masthead}`)
      .set(auth(reader.token))
      .expect(200);
    expect(hidden.body.issues).toEqual([]);
    expect(JSON.stringify(hidden.body)).not.toContain(locked.id);

    await createIssue(reader, { serviceDate: dateAt(0), colorId });
    const opened = await request(app.getHttpServer())
      .get(`/api/magazines/${owner.masthead}`)
      .set(auth(reader.token))
      .expect(200);
    expect(opened.body.issues).toEqual([
      expect.objectContaining({ id: locked.id }),
    ]);
  });

  it.todo('합격 기준: 구독하면 GET /api/feed?tab=subs에 그 잡지의 호가 나옴');
});

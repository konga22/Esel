import { INestApplication } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import { App } from 'supertest/types.js';
import { vi } from 'vitest';
import { serviceDate } from '../../src/common/service-date.js';
import { PrismaService } from '../../src/prisma/prisma.service.js';
import { dailyCandidateIds } from '../../src/today/today.rules.js';
import { createTestApp } from '../create-app.js';

describe('DEV-12 가판대와 같은 색', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  let timeZone: string;
  let mastheadSequence = 0;

  beforeAll(async () => {
    app = await createTestApp();
    prisma = app.get(PrismaService);
    timeZone = app.get(ConfigService).getOrThrow<string>('SERVICE_TIME_ZONE');
    await cleanup();
  });
  afterEach(cleanup);
  afterAll(async () => app.close());

  async function cleanup() {
    await prisma.twin.deleteMany({
      where: {
        participations: {
          some: { user: { email: { endsWith: '@stand.e2e.test' } } },
        },
      },
    });
    await prisma.issue.deleteMany({
      where: { author: { email: { endsWith: '@stand.e2e.test' } } },
    });
    await prisma.user.deleteMany({
      where: { email: { endsWith: '@stand.e2e.test' } },
    });
  }

  async function signup(label: string) {
    const response = await request(app.getHttpServer())
      .post('/api/auth/email/signup')
      .send({
        email: `${label}-${randomUUID()}@stand.e2e.test`,
        password: 'correct horse battery staple',
      })
      .expect(201);
    const user = {
      id: response.body.userId as string,
      token: response.body.accessToken as string,
      masthead: nextMasthead(),
    };
    await prisma.profile.create({
      data: { userId: user.id, masthead: user.masthead },
    });
    return user;
  }

  function nextMasthead(): string {
    let value = mastheadSequence++;
    let suffix = '';
    do {
      suffix = String.fromCharCode(97 + (value % 26)) + suffix;
      value = Math.floor(value / 26) - 1;
    } while (value >= 0);
    return `stand${suffix}`;
  }

  function day(offset: number) {
    const date = new Date(`${serviceDate(new Date(), timeZone)}T00:00:00.000Z`);
    date.setUTCDate(date.getUTCDate() + offset);
    return date;
  }

  async function issue(
    authorId: string,
    options: {
      date?: Date;
      colorId: string;
      publishedAt?: Date;
      issueNumber?: number;
    },
  ) {
    const media = await prisma.mediaAsset.create({
      data: {
        ownerId: authorId,
        storageKey: `stand/${randomUUID()}`,
        status: 'READY',
        mimeType: 'image/png',
        sizeBytes: 24,
      },
    });
    return prisma.issue.create({
      data: {
        authorId,
        serviceDate: options.date ?? day(0),
        issueNumber: options.issueNumber ?? 1,
        colorId: options.colorId,
        mediaId: media.id,
        caption: '팔레트',
        faceCrop: 'ORIGINAL',
        paintStroke: false,
        publishedAt: options.publishedAt,
      },
    });
  }

  const auth = (token: string) => ({ Authorization: `Bearer ${token}` });

  async function candidates(token: string) {
    const response = await request(app.getHttpServer())
      .get('/api/today')
      .set(auth(token))
      .expect(200);
    return (response.body.candidates as { id: string }[]).map(({ id }) => id);
  }

  // stand.get · 접근: user · 응답: StandDto · 계약: P01, P02, P18
  it('GET /api/stand: 가판대·같은 색 방(오늘 발행 전 후보 3색 방은 3장 + 숨긴 개수) → 200', async () => {
    const reader = await signup('stand-reader');
    const colorId = (await candidates(reader.token))[0];
    for (let index = 0; index < 5; index += 1) {
      const author = await signup(`stand-author-${index}`);
      await issue(author.id, {
        colorId,
        publishedAt: new Date(`2199-01-0${index + 1}T00:00:00.000Z`),
      });
    }
    const response = await request(app.getHttpServer())
      .get('/api/stand')
      .query({ colorId })
      .set(auth(reader.token))
      .expect(200);
    expect(response.body).toMatchObject({
      locked: true,
      closed: false,
      hiddenCount: 2,
    });
    expect(response.body.items).toHaveLength(3);
    expect(response.body.nextCursor).toBeNull();
  });

  it('GET /api/stand: 로그인 없이 부르면 → 401 AUTH_REQUIRED', async () => {
    const response = await request(app.getHttpServer())
      .get('/api/stand?colorId=sage')
      .expect(401);
    expect(response.body.error.code).toBe('AUTH_REQUIRED');
  });

  it('GET /api/stand: 보낸 값의 형식이 맞지 않아요 → 400 VALIDATION', async () => {
    const reader = await signup('stand-invalid');
    for (const query of [
      {},
      { colorId: 'missing' },
      { colorId: 'sage', date: '2026-99-99' },
    ]) {
      const response = await request(app.getHttpServer())
        .get('/api/stand')
        .query(query)
        .set(auth(reader.token))
        .expect(400);
      expect(response.body.error.code).toBe('VALIDATION');
    }
  });

  it('합격 기준(P01): 고른 색을 바꿔도 후보 3색 방은 최신 3장 미리보기 그대로', async () => {
    const reader = await signup('choice-reader');
    const colors = await candidates(reader.token);
    for (const colorId of colors.slice(0, 2)) {
      await request(app.getHttpServer())
        .put('/api/today/choice')
        .set(auth(reader.token))
        .send({ colorId })
        .expect(200);
    }
    const response = await request(app.getHttpServer())
      .get('/api/stand')
      .query({ colorId: colors[0] })
      .set(auth(reader.token))
      .expect(200);
    expect(response.body.locked).toBe(true);
  });

  it('합격 기준(P02): 후보가 아닌 색과 지난 날짜는 열리고 미래 날짜는 closed', async () => {
    const reader = await signup('date-reader');
    const colors = await candidates(reader.token);
    const other = await prisma.color.findFirstOrThrow({
      where: { id: { notIn: colors } },
    });
    const author = await signup('date-author');
    await issue(author.id, { colorId: other.id });
    const open = await request(app.getHttpServer())
      .get('/api/stand')
      .query({ colorId: other.id })
      .set(auth(reader.token))
      .expect(200);
    expect(open.body.locked).toBe(false);
    const futureKey = day(1).toISOString().slice(0, 10);
    const future = await request(app.getHttpServer())
      .get('/api/stand')
      .query({ colorId: other.id, date: futureKey })
      .set(auth(reader.token))
      .expect(200);
    expect(future.body).toMatchObject({ closed: true, items: [] });
  });

  it('합격 기준(P01): 오늘 발행하면 후보 3색 방이 모두 열림', async () => {
    const reader = await signup('published-reader');
    const colors = await candidates(reader.token);
    await issue(reader.id, { colorId: colors[0] });
    for (const colorId of colors) {
      const response = await request(app.getHttpServer())
        .get('/api/stand')
        .query({ colorId })
        .set(auth(reader.token))
        .expect(200);
      expect(response.body.locked).toBe(false);
    }
  });

  it.todo(
    '합격 기준(P01): 미성년자는 잠금 없이 전부 열림(판별 방법은 미정, DEV-02)',
  );
  it('합격 기준(P01·P03·P09): 색 확정·색 복원·트윈 게시로는 어느 방도 열리지 않음', async () => {
    // 색 복원은 '이번 달의 지난 날'만 되므로, 달 초하루에도 흔들리지 않게 날짜를 고정한다.
    vi.setSystemTime(new Date('2026-10-18T12:00:00.000Z'));
    try {
      const reader = await signup('no-unlock-reader');
      const partner = await signup('no-unlock-partner');
      const colors = await candidates(reader.token);
      const expectAllLocked = async (step: string) => {
        for (const colorId of colors) {
          const response = await request(app.getHttpServer())
            .get('/api/stand')
            .query({ colorId })
            .set(auth(reader.token))
            .expect(200);
          expect({ step, colorId, locked: response.body.locked }).toEqual({
            step,
            colorId,
            locked: true,
          });
        }
      };
      await expectAllLocked('처음');

      // 1) 색 확정(P01): 오늘의 색을 골라도 아직 발행 전이다.
      await request(app.getHttpServer())
        .put('/api/today/choice')
        .set(auth(reader.token))
        .send({ colorId: colors[0] })
        .expect(200);
      await expectAllLocked('색 확정 뒤');

      // 2) 색 복원(P03): 지난 빈 날을 색으로만 채운다. 오늘 발행이 아니다.
      const pastKey = '2026-10-16';
      const allColors = await prisma.color.findMany({
        orderBy: { sortOrder: 'asc' },
        select: { id: true },
      });
      await request(app.getHttpServer())
        .post(`/api/me/records/${pastKey}/restore`)
        .set(auth(reader.token))
        .send({
          colorId: dailyCandidateIds(
            pastKey,
            allColors.map(({ id }) => id),
          )[0],
        })
        .expect(201);
      await expectAllLocked('색 복원 뒤');

      // 3) 트윈 게시(P09): 친구와 트윈 표지를 올리고 공동 발행까지 해도 개인 호 발행이 아니다.
      const [userAId, userBId] =
        reader.id < partner.id
          ? [reader.id, partner.id]
          : [partner.id, reader.id];
      await prisma.friendship.create({ data: { userAId, userBId } });
      const created = await request(app.getHttpServer())
        .post('/api/twins')
        .set(auth(reader.token))
        .send({ friendId: partner.id })
        .expect(201);
      const accepted = await request(app.getHttpServer())
        .post(`/api/twins/${created.body.id}/accept`)
        .set(auth(partner.token))
        .expect(201);
      const twinId = accepted.body.id as string;
      await request(app.getHttpServer())
        .put(`/api/twins/${twinId}/choice`)
        .set(auth(reader.token))
        .send({ colorId: accepted.body.partnerCandidates[0].id })
        .expect(200);
      await request(app.getHttpServer())
        .put(`/api/twins/${twinId}/choice`)
        .set(auth(partner.token))
        .send({ colorId: accepted.body.myCandidates[0].id })
        .expect(200);
      for (const user of [reader, partner]) {
        const media = await prisma.mediaAsset.create({
          data: {
            ownerId: user.id,
            storageKey: `stand/${randomUUID()}.jpg`,
            status: 'READY',
            mimeType: 'image/jpeg',
            sizeBytes: 1024,
            width: 800,
            height: 1200,
          },
        });
        await request(app.getHttpServer())
          .post(`/api/twins/${twinId}/posts`)
          .set(auth(user.token))
          .send({ mediaId: media.id })
          .expect(201);
      }
      await expectAllLocked('트윈 표지 올린 뒤');

      for (const user of [reader, partner]) {
        await request(app.getHttpServer())
          .put(`/api/twins/${twinId}/visibility`)
          .set(auth(user.token))
          .send({ visibility: 'joint' })
          .expect(200);
      }
      // 동의는 두 사람 모두 공개 범위를 joint로 정한 뒤에만 할 수 있다.
      for (const user of [reader, partner]) {
        await request(app.getHttpServer())
          .post(`/api/twins/${twinId}/consent`)
          .set(auth(user.token))
          .expect(201);
      }
      await request(app.getHttpServer())
        .post(`/api/twins/${twinId}/publish`)
        .set(auth(reader.token))
        .expect(201);
      await expectAllLocked('트윈 공동 발행 뒤');

      // 세 가지 모두 개인 호를 만들지 않았다.
      expect(await prisma.issue.count({ where: { authorId: reader.id } })).toBe(
        0,
      );
    } finally {
      vi.useRealTimers();
    }
  });
  it('합격 기준(P18): 응답에 반응 숫자가 없음', async () => {
    const reader = await signup('stand-numbers');
    const colorId = (await candidates(reader.token))[0];
    const response = await request(app.getHttpServer())
      .get('/api/stand')
      .query({ colorId })
      .set(auth(reader.token))
      .expect(200);
    expect(JSON.stringify(response.body)).not.toMatch(
      /likeCount|scrapCount|lineCount|rank/,
    );
  });

  // 10-18 사용자 결정: 화면 이름은 팔레트(인스타 돋보기 탭 구조). 탭은 추천·색상·구독.
  it('GET /api/palette/recommended: 팔레트 추천 탭: 추천하는 사람마다 최신 사진 한 장 → 200', async () => {
    const reader = await signup('recommended-reader');
    const author = await signup('recommended-author');
    await issue(author.id, { date: day(-2), colorId: 'sage', issueNumber: 1 });
    const latest = await issue(author.id, {
      date: day(-1),
      colorId: 'sage',
      issueNumber: 2,
    });
    const response = await request(app.getHttpServer())
      .get('/api/palette/recommended')
      .set(auth(reader.token))
      .expect(200);
    expect(response.body.items).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          issueId: latest.id,
          masthead: author.masthead,
        }),
      ]),
    );
    const authorTiles = response.body.items.filter(
      ({ masthead }: { masthead: string }) => masthead === author.masthead,
    );
    expect(authorTiles).toHaveLength(1);
    expect(authorTiles[0]).toMatchObject({
      issueId: latest.id,
      masthead: author.masthead,
    });
  });

  it('GET /api/palette/recommended: 로그인 없이 부르면 → 401 AUTH_REQUIRED', async () => {
    const response = await request(app.getHttpServer())
      .get('/api/palette/recommended')
      .expect(401);
    expect(response.body.error.code).toBe('AUTH_REQUIRED');
  });

  it('GET /api/palette/recommended: 보낸 값의 형식이 맞지 않아요 → 400 VALIDATION', async () => {
    const reader = await signup('recommended-invalid');
    const response = await request(app.getHttpServer())
      .get('/api/palette/recommended?cursor=bad')
      .set(auth(reader.token))
      .expect(400);
    expect(response.body.error.code).toBe('VALIDATION');
  });

  it('합격 기준(P01·P18): 발행 전 후보색 사진과 공개 숫자는 추천에서 숨김', async () => {
    const reader = await signup('recommended-locked');
    const author = await signup('recommended-locked-author');
    const colorId = (await candidates(reader.token))[0];
    const locked = await issue(author.id, { colorId });
    const response = await request(app.getHttpServer())
      .get('/api/palette/recommended')
      .set(auth(reader.token))
      .expect(200);
    expect(
      response.body.items.map(({ issueId }: { issueId: string }) => issueId),
    ).not.toContain(locked.id);
    expect(JSON.stringify(response.body)).not.toMatch(
      /Count|rank|price|shopUrl/,
    );
  });

  it('GET /api/palette/colors: 팔레트 색상 목록 순서 → 200', async () => {
    const reader = await signup('colors-reader');
    const candidateIds = await candidates(reader.token);
    const response = await request(app.getHttpServer())
      .get('/api/palette/colors')
      .set(auth(reader.token))
      .expect(200);
    expect(response.body.items).toHaveLength(12);
    expect(
      response.body.items.slice(0, 3).map(({ id }: { id: string }) => id),
    ).toEqual(candidateIds);
    expect(
      response.body.items
        .slice(0, 3)
        .every(({ locked }: { locked: boolean }) => locked),
    ).toBe(true);
  });

  it('GET /api/palette/colors: 로그인 없이 부르면 → 401 AUTH_REQUIRED', async () => {
    const response = await request(app.getHttpServer())
      .get('/api/palette/colors')
      .expect(401);
    expect(response.body.error.code).toBe('AUTH_REQUIRED');
  });

  it('합격 기준(P01·P18): 발행 뒤 잠김이 사라지고 색별 선택 수는 응답하지 않음', async () => {
    const reader = await signup('colors-published');
    const colorId = (await candidates(reader.token))[0];
    await issue(reader.id, { colorId });
    const response = await request(app.getHttpServer())
      .get('/api/palette/colors')
      .set(auth(reader.token))
      .expect(200);
    expect(
      response.body.items.every(({ locked }: { locked: boolean }) => !locked),
    ).toBe(true);
    expect(JSON.stringify(response.body)).not.toMatch(/count|rank/i);
  });

  it('GET /api/palette/subscriptions: 팔레트 구독 탭: 구독한 사람마다 최신 사진 한 장 → 200', async () => {
    const reader = await signup('subscriptions-reader');
    const author = await signup('subscriptions-author');
    await prisma.subscription.create({
      data: { subscriberId: reader.id, magazineId: author.id },
    });
    await issue(author.id, { date: day(-2), colorId: 'sage', issueNumber: 1 });
    const latest = await issue(author.id, {
      date: day(-1),
      colorId: 'sage',
      issueNumber: 2,
    });
    const response = await request(app.getHttpServer())
      .get('/api/palette/subscriptions')
      .set(auth(reader.token))
      .expect(200);
    expect(response.body.items).toEqual([
      expect.objectContaining({
        issueId: latest.id,
        masthead: author.masthead,
      }),
    ]);
  });
  it('GET /api/palette/subscriptions: 로그인 없이 부르면 → 401 AUTH_REQUIRED', async () => {
    const response = await request(app.getHttpServer())
      .get('/api/palette/subscriptions')
      .expect(401);
    expect(response.body.error.code).toBe('AUTH_REQUIRED');
  });
  it('GET /api/palette/subscriptions: 보낸 값의 형식이 맞지 않아요 → 400 VALIDATION', async () => {
    const reader = await signup('subscriptions-invalid');
    const response = await request(app.getHttpServer())
      .get('/api/palette/subscriptions?cursor=bad')
      .set(auth(reader.token))
      .expect(400);
    expect(response.body.error.code).toBe('VALIDATION');
  });
});

import { INestApplication } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import { App } from 'supertest/types.js';
import { PrismaService } from '../../src/prisma/prisma.service.js';
import { createTestApp } from '../create-app.js';

// 계약 테스트: twins 모듈. api-contract.json의 API와 루트 docs/dev/features.json의 서버 합격 기준을 할 일(it.todo)로 적어 두었다.
// 이 파일은 손으로 관리한다. API마다 'METHOD /api/경로: … → 상태' 형식의 todo나 테스트가 있어야 하고, 상태 코드는 api-contract.json과 같아야 한다(npm run check:server가 확인).
// 하나를 구현하면 그 todo를 it(…) 안에서 request(app.getHttpServer()).<method>('/api/…')로 부르는 실제 테스트로 바꾸고, api-contract.json의 status를 done으로 바꾼다.
// 실행: npm run test:e2e (todo는 실패가 아니라 '남은 일'로 표시된다)

describe('DEV-17 트윈', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  let sequence = 0;

  beforeAll(async () => {
    app = await createTestApp();
    prisma = app.get(PrismaService);
    await cleanup();
  });
  afterEach(cleanup);
  afterAll(async () => app.close());

  async function cleanup() {
    const users = await prisma.user.findMany({
      where: { email: { endsWith: '@twins.e2e.test' } },
      select: { id: true },
    });
    const userIds = users.map(({ id }) => id);
    const twins = await prisma.twin.findMany({
      where: { participations: { some: { userId: { in: userIds } } } },
      select: { id: true },
    });
    await prisma.twin.deleteMany({
      where: { id: { in: twins.map(({ id }) => id) } },
    });
    await prisma.user.deleteMany({ where: { id: { in: userIds } } });
  }

  async function signup(label: string) {
    const response = await request(app.getHttpServer())
      .post('/api/auth/email/signup')
      .send({
        email: `${label}-${randomUUID()}@twins.e2e.test`,
        password: 'correct horse battery staple',
      })
      .expect(201);
    let suffix = '';
    for (
      let value = sequence++;
      value >= 0;
      value = Math.floor(value / 26) - 1
    ) {
      suffix = String.fromCharCode(97 + (value % 26)) + suffix;
    }
    const user = {
      token: response.body.accessToken as string,
      userId: response.body.userId as string,
      masthead: `t${suffix}`,
    };
    await prisma.profile.create({
      data: { userId: user.userId, masthead: user.masthead },
    });
    return user;
  }

  const auth = (token: string) => ({ Authorization: `Bearer ${token}` });

  async function makeFriends(
    left: { userId: string },
    right: { userId: string },
  ) {
    const [userAId, userBId] =
      left.userId < right.userId
        ? [left.userId, right.userId]
        : [right.userId, left.userId];
    await prisma.friendship.create({ data: { userAId, userBId } });
  }

  async function invite(
    inviter: { token: string },
    invitee: { userId: string },
  ) {
    return request(app.getHttpServer())
      .post('/api/twins')
      .set(auth(inviter.token))
      .send({ friendId: invitee.userId })
      .expect(201);
  }

  async function acceptedTwin(
    inviter: { token: string; userId: string },
    invitee: { token: string; userId: string },
  ) {
    await makeFriends(inviter, invitee);
    const created = await invite(inviter, invitee);
    return request(app.getHttpServer())
      .post(`/api/twins/${created.body.id}/accept`)
      .set(auth(invitee.token))
      .expect(201);
  }

  async function readyMedia(userId: string, status = 'READY') {
    return prisma.mediaAsset.create({
      data: {
        ownerId: userId,
        storageKey: `twins/${randomUUID()}.jpg`,
        status: status as 'READY' | 'PENDING',
        mimeType: 'image/jpeg',
        sizeBytes: 1024,
        width: 800,
        height: 1200,
      },
    });
  }

  async function postedTwin(
    inviter: { token: string; userId: string },
    invitee: { token: string; userId: string },
  ) {
    const accepted = await acceptedTwin(inviter, invitee);
    await request(app.getHttpServer())
      .put(`/api/twins/${accepted.body.id}/choice`)
      .set(auth(inviter.token))
      .send({ colorId: accepted.body.partnerCandidates[0].id })
      .expect(200);
    await request(app.getHttpServer())
      .put(`/api/twins/${accepted.body.id}/choice`)
      .set(auth(invitee.token))
      .send({ colorId: accepted.body.myCandidates[0].id })
      .expect(200);
    const inviterMedia = await readyMedia(inviter.userId);
    const inviteeMedia = await readyMedia(invitee.userId);
    await request(app.getHttpServer())
      .post(`/api/twins/${accepted.body.id}/posts`)
      .set(auth(inviter.token))
      .send({ mediaId: inviterMedia.id })
      .expect(201);
    await request(app.getHttpServer())
      .post(`/api/twins/${accepted.body.id}/posts`)
      .set(auth(invitee.token))
      .send({ mediaId: inviteeMedia.id })
      .expect(201);
    return { id: accepted.body.id as string, inviterMedia, inviteeMedia };
  }

  // twins.invite · 접근: user · 응답: TwinDto · 계약: P08
  it('POST /api/twins: 친구를 오늘 트윈에 초대 → 201', async () => {
    const inviter = await signup('invite-a');
    const invitee = await signup('invite-b');
    await makeFriends(inviter, invitee);
    const response = await invite(inviter, invitee);
    expect(response.body).toMatchObject({
      id: expect.any(String),
      status: 'INVITED',
      invitedByMe: true,
      partner: { friendId: invitee.userId, masthead: invitee.masthead },
      myCandidates: [],
      partnerCandidates: [],
      myColorId: null,
      partnerColorId: null,
      myPost: null,
      partnerPost: null,
    });
  });
  it('POST /api/twins: 로그인 없이 부르면 → 401 AUTH_REQUIRED', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/twins')
      .send({ friendId: randomUUID() })
      .expect(401);
    expect(response.body.error.code).toBe('AUTH_REQUIRED');
  });
  it('POST /api/twins: 보낸 값의 형식이 맞지 않아요 → 400 VALIDATION', async () => {
    const inviter = await signup('invite-invalid');
    const response = await request(app.getHttpServer())
      .post('/api/twins')
      .set(auth(inviter.token))
      .send({ friendId: 'invalid' })
      .expect(400);
    expect(response.body.error.code).toBe('VALIDATION');
  });
  it('POST /api/twins: 친구가 아니거나 없는 사람 → 404 NOT_FOUND', async () => {
    const inviter = await signup('invite-missing-a');
    const stranger = await signup('invite-missing-b');
    const response = await request(app.getHttpServer())
      .post('/api/twins')
      .set(auth(inviter.token))
      .send({ friendId: stranger.userId })
      .expect(404);
    expect(response.body.error.code).toBe('NOT_FOUND');
  });
  it('POST /api/twins: 지금 단계에서는 할 수 없는 작업이에요 → 409 TWIN_STATE', async () => {
    const inviter = await signup('invite-duplicate-a');
    const invitee = await signup('invite-duplicate-b');
    await makeFriends(inviter, invitee);
    await invite(inviter, invitee);
    const response = await request(app.getHttpServer())
      .post('/api/twins')
      .set(auth(inviter.token))
      .send({ friendId: invitee.userId })
      .expect(409);
    expect(response.body.error.code).toBe('TWIN_STATE');
  });
  // twins.get · 접근: member · 응답: TwinDto · 계약: P08, P10
  it('GET /api/twins/:id: 트윈 현재 단계(상대 사진은 둘 다 게시 후에만) → 200', async () => {
    const inviter = await signup('get-a');
    const invitee = await signup('get-b');
    await makeFriends(inviter, invitee);
    const created = await invite(inviter, invitee);
    const response = await request(app.getHttpServer())
      .get(`/api/twins/${created.body.id}`)
      .set(auth(invitee.token))
      .expect(200);
    expect(response.body).toMatchObject({
      id: created.body.id,
      status: 'INVITED',
      invitedByMe: false,
      partner: { friendId: inviter.userId, masthead: inviter.masthead },
    });
  });
  it('GET /api/twins/:id: 로그인 없이 부르면 → 401 AUTH_REQUIRED', async () => {
    const response = await request(app.getHttpServer())
      .get(`/api/twins/${randomUUID()}`)
      .expect(401);
    expect(response.body.error.code).toBe('AUTH_REQUIRED');
  });
  it('GET /api/twins/:id: 참여자가 아니거나 없는 트윈 → 404 NOT_FOUND', async () => {
    const inviter = await signup('get-other-a');
    const invitee = await signup('get-other-b');
    const stranger = await signup('get-other-c');
    await makeFriends(inviter, invitee);
    const created = await invite(inviter, invitee);
    const response = await request(app.getHttpServer())
      .get(`/api/twins/${created.body.id}`)
      .set(auth(stranger.token))
      .expect(404);
    expect(response.body.error.code).toBe('NOT_FOUND');
  });
  // twins.accept · 접근: member · 응답: TwinDto · 계약: P08
  it('POST /api/twins/:id/accept: 초대 수락 → 201', async () => {
    const inviter = await signup('accept-a');
    const invitee = await signup('accept-b');
    const response = await acceptedTwin(inviter, invitee);
    const mine = response.body.myCandidates.map(({ id }: { id: string }) => id);
    const theirs = response.body.partnerCandidates.map(
      ({ id }: { id: string }) => id,
    );
    expect(response.body.status).toBe('CHOOSING');
    expect(mine).toHaveLength(3);
    expect(theirs).toHaveLength(3);
    expect(mine.filter((id: string) => theirs.includes(id))).toHaveLength(1);
  });
  it('POST /api/twins/:id/accept: 로그인 없이 부르면 → 401 AUTH_REQUIRED', async () => {
    const response = await request(app.getHttpServer())
      .post(`/api/twins/${randomUUID()}/accept`)
      .expect(401);
    expect(response.body.error.code).toBe('AUTH_REQUIRED');
  });
  it('POST /api/twins/:id/accept: 참여자가 아니거나 없는 트윈 → 404 NOT_FOUND', async () => {
    const inviter = await signup('accept-other-a');
    const invitee = await signup('accept-other-b');
    const stranger = await signup('accept-other-c');
    await makeFriends(inviter, invitee);
    const created = await invite(inviter, invitee);
    const response = await request(app.getHttpServer())
      .post(`/api/twins/${created.body.id}/accept`)
      .set(auth(stranger.token))
      .expect(404);
    expect(response.body.error.code).toBe('NOT_FOUND');
  });
  it('POST /api/twins/:id/accept: 지금 단계에서는 할 수 없는 작업이에요 → 409 TWIN_STATE', async () => {
    const inviter = await signup('accept-state-a');
    const invitee = await signup('accept-state-b');
    await makeFriends(inviter, invitee);
    const created = await invite(inviter, invitee);
    const response = await request(app.getHttpServer())
      .post(`/api/twins/${created.body.id}/accept`)
      .set(auth(inviter.token))
      .expect(409);
    expect(response.body.error.code).toBe('TWIN_STATE');
  });
  // twins.choose · 접근: member · 응답: TwinDto · 계약: P08, P09
  it('PUT /api/twins/:id/choice: 내 트윈 색 고르기(내 후보 3개 중) → 200', async () => {
    const inviter = await signup('choose-a');
    const invitee = await signup('choose-b');
    const accepted = await acceptedTwin(inviter, invitee);
    const myColor = accepted.body.partnerCandidates[1].id as string;
    const theirColor = accepted.body.myCandidates[1].id as string;
    const first = await request(app.getHttpServer())
      .put(`/api/twins/${accepted.body.id}/choice`)
      .set(auth(inviter.token))
      .send({ colorId: myColor })
      .expect(200);
    const second = await request(app.getHttpServer())
      .put(`/api/twins/${accepted.body.id}/choice`)
      .set(auth(invitee.token))
      .send({ colorId: theirColor })
      .expect(200);
    expect(first.body.myColorId).toBe(myColor);
    expect(second.body.myColorId).toBe(theirColor);
    expect(second.body.partnerColorId).toBe(myColor);
    expect(second.body.status).toBe('POSTING');
  });
  it('PUT /api/twins/:id/choice: 로그인 없이 부르면 → 401 AUTH_REQUIRED', async () => {
    const response = await request(app.getHttpServer())
      .put(`/api/twins/${randomUUID()}/choice`)
      .send({ colorId: 'camel' })
      .expect(401);
    expect(response.body.error.code).toBe('AUTH_REQUIRED');
  });
  it('PUT /api/twins/:id/choice: 보낸 값의 형식이 맞지 않아요 → 400 VALIDATION', async () => {
    const user = await signup('choose-invalid');
    const response = await request(app.getHttpServer())
      .put(`/api/twins/${randomUUID()}/choice`)
      .set(auth(user.token))
      .send({ colorId: 'NOT VALID' })
      .expect(400);
    expect(response.body.error.code).toBe('VALIDATION');
  });
  it('PUT /api/twins/:id/choice: 참여자가 아니거나 없는 트윈 → 404 NOT_FOUND', async () => {
    const user = await signup('choose-missing');
    const response = await request(app.getHttpServer())
      .put(`/api/twins/${randomUUID()}/choice`)
      .set(auth(user.token))
      .send({ colorId: 'camel' })
      .expect(404);
    expect(response.body.error.code).toBe('NOT_FOUND');
  });
  it('PUT /api/twins/:id/choice: 지금 단계에서는 할 수 없는 작업이에요 → 409 TWIN_STATE', async () => {
    const inviter = await signup('choose-state-a');
    const invitee = await signup('choose-state-b');
    await makeFriends(inviter, invitee);
    const created = await invite(inviter, invitee);
    const response = await request(app.getHttpServer())
      .put(`/api/twins/${created.body.id}/choice`)
      .set(auth(inviter.token))
      .send({ colorId: 'camel' })
      .expect(409);
    expect(response.body.error.code).toBe('TWIN_STATE');
  });
  it('PUT /api/twins/:id/choice: 오늘 후보에 없는 색이에요 → 422 COLOR_NOT_CANDIDATE', async () => {
    const inviter = await signup('choose-color-a');
    const invitee = await signup('choose-color-b');
    const accepted = await acceptedTwin(inviter, invitee);
    const candidates = new Set(
      accepted.body.partnerCandidates.map(({ id }: { id: string }) => id),
    );
    const color = await prisma.color.findFirstOrThrow({
      where: { id: { notIn: [...candidates] } },
    });
    const response = await request(app.getHttpServer())
      .put(`/api/twins/${accepted.body.id}/choice`)
      .set(auth(inviter.token))
      .send({ colorId: color.id })
      .expect(422);
    expect(response.body.error.code).toBe('COLOR_NOT_CANDIDATE');
  });
  // twins.post · 접근: member · 응답: TwinDto · 계약: P01, P09, P10
  it('POST /api/twins/:id/posts: 내 트윈 표지 올리기(명시적 업로드) → 201', async () => {
    const inviter = await signup('post-a');
    const invitee = await signup('post-b');
    const accepted = await acceptedTwin(inviter, invitee);
    const inviterColor = accepted.body.partnerCandidates[0].id as string;
    const inviteeColor = accepted.body.myCandidates[1].id as string;
    await request(app.getHttpServer())
      .put(`/api/twins/${accepted.body.id}/choice`)
      .set(auth(inviter.token))
      .send({ colorId: inviterColor })
      .expect(200);
    await request(app.getHttpServer())
      .put(`/api/twins/${accepted.body.id}/choice`)
      .set(auth(invitee.token))
      .send({ colorId: inviteeColor })
      .expect(200);
    const inviterMedia = await readyMedia(inviter.userId);
    const inviteeMedia = await readyMedia(invitee.userId);
    const first = await request(app.getHttpServer())
      .post(`/api/twins/${accepted.body.id}/posts`)
      .set(auth(inviter.token))
      .send({ mediaId: inviterMedia.id })
      .expect(201);
    expect(first.body.myPost.media.id).toBe(inviterMedia.id);
    expect(first.body.partnerPost).toBeNull();

    const second = await request(app.getHttpServer())
      .post(`/api/twins/${accepted.body.id}/posts`)
      .set(auth(invitee.token))
      .send({ mediaId: inviteeMedia.id })
      .expect(201);
    expect(second.body.status).toBe('REVEALED');
    expect(second.body.myPost.media.id).toBe(inviteeMedia.id);
    expect(second.body.partnerPost.media.id).toBe(inviterMedia.id);
    const participantIds = [inviter.userId, invitee.userId];
    expect(
      await prisma.issue.count({ where: { authorId: { in: participantIds } } }),
    ).toBe(0);
    expect(
      await prisma.userDailyChoice.count({
        where: { userId: { in: participantIds } },
      }),
    ).toBe(0);
  });
  it('POST /api/twins/:id/posts: 로그인 없이 부르면 → 401 AUTH_REQUIRED', async () => {
    const response = await request(app.getHttpServer())
      .post(`/api/twins/${randomUUID()}/posts`)
      .send({ mediaId: randomUUID() })
      .expect(401);
    expect(response.body.error.code).toBe('AUTH_REQUIRED');
  });
  it('POST /api/twins/:id/posts: 보낸 값의 형식이 맞지 않아요 → 400 VALIDATION', async () => {
    const user = await signup('post-invalid');
    const response = await request(app.getHttpServer())
      .post(`/api/twins/${randomUUID()}/posts`)
      .set(auth(user.token))
      .send({ mediaId: 'invalid' })
      .expect(400);
    expect(response.body.error.code).toBe('VALIDATION');
  });
  it('POST /api/twins/:id/posts: 참여자가 아니거나 없는 트윈 → 404 NOT_FOUND', async () => {
    const user = await signup('post-missing');
    const response = await request(app.getHttpServer())
      .post(`/api/twins/${randomUUID()}/posts`)
      .set(auth(user.token))
      .send({ mediaId: randomUUID() })
      .expect(404);
    expect(response.body.error.code).toBe('NOT_FOUND');
  });
  it('POST /api/twins/:id/posts: 사진 올리기가 아직 끝나지 않았어요 → 409 MEDIA_NOT_READY', async () => {
    const inviter = await signup('post-pending-a');
    const invitee = await signup('post-pending-b');
    const accepted = await acceptedTwin(inviter, invitee);
    await request(app.getHttpServer())
      .put(`/api/twins/${accepted.body.id}/choice`)
      .set(auth(inviter.token))
      .send({ colorId: accepted.body.partnerCandidates[0].id })
      .expect(200);
    const media = await readyMedia(inviter.userId, 'PENDING');
    const response = await request(app.getHttpServer())
      .post(`/api/twins/${accepted.body.id}/posts`)
      .set(auth(inviter.token))
      .send({ mediaId: media.id })
      .expect(409);
    expect(response.body.error.code).toBe('MEDIA_NOT_READY');
  });
  it('POST /api/twins/:id/posts: 지금 단계에서는 할 수 없는 작업이에요 → 409 TWIN_STATE', async () => {
    const inviter = await signup('post-state-a');
    const invitee = await signup('post-state-b');
    const accepted = await acceptedTwin(inviter, invitee);
    const media = await readyMedia(inviter.userId);
    const response = await request(app.getHttpServer())
      .post(`/api/twins/${accepted.body.id}/posts`)
      .set(auth(inviter.token))
      .send({ mediaId: media.id })
      .expect(409);
    expect(response.body.error.code).toBe('TWIN_STATE');
  });
  // twins.visibility · 접근: member · 응답: TwinDto · 계약: P10
  it('PUT /api/twins/:id/visibility: 공개 범위 정하기(private·solo·joint) → 200', async () => {
    const inviter = await signup('visibility-a');
    const invitee = await signup('visibility-b');
    const twin = await postedTwin(inviter, invitee);
    const response = await request(app.getHttpServer())
      .put(`/api/twins/${twin.id}/visibility`)
      .set(auth(inviter.token))
      .send({ visibility: 'solo' })
      .expect(200);
    expect(response.body).toMatchObject({
      status: 'SHARING',
      myVisibility: 'solo',
      partnerVisibility: null,
      myConsented: false,
      publishedAt: null,
    });
  });
  it('PUT /api/twins/:id/visibility: 로그인 없이 부르면 → 401 AUTH_REQUIRED', async () => {
    const response = await request(app.getHttpServer())
      .put(`/api/twins/${randomUUID()}/visibility`)
      .send({ visibility: 'private' })
      .expect(401);
    expect(response.body.error.code).toBe('AUTH_REQUIRED');
  });
  it('PUT /api/twins/:id/visibility: 보낸 값의 형식이 맞지 않아요 → 400 VALIDATION', async () => {
    const user = await signup('visibility-invalid');
    const response = await request(app.getHttpServer())
      .put(`/api/twins/${randomUUID()}/visibility`)
      .set(auth(user.token))
      .send({ visibility: 'public' })
      .expect(400);
    expect(response.body.error.code).toBe('VALIDATION');
  });
  it('PUT /api/twins/:id/visibility: 참여자가 아니거나 없는 트윈 → 404 NOT_FOUND', async () => {
    const user = await signup('visibility-missing');
    const response = await request(app.getHttpServer())
      .put(`/api/twins/${randomUUID()}/visibility`)
      .set(auth(user.token))
      .send({ visibility: 'private' })
      .expect(404);
    expect(response.body.error.code).toBe('NOT_FOUND');
  });
  it('PUT /api/twins/:id/visibility: 지금 단계에서는 할 수 없는 작업이에요 → 409 TWIN_STATE', async () => {
    const inviter = await signup('visibility-state-a');
    const invitee = await signup('visibility-state-b');
    const accepted = await acceptedTwin(inviter, invitee);
    const response = await request(app.getHttpServer())
      .put(`/api/twins/${accepted.body.id}/visibility`)
      .set(auth(inviter.token))
      .send({ visibility: 'joint' })
      .expect(409);
    expect(response.body.error.code).toBe('TWIN_STATE');
  });
  // twins.consent · 접근: member · 응답: TwinDto · 계약: P10
  it('POST /api/twins/:id/consent: 공동 공개에 동의 → 201', async () => {
    const inviter = await signup('consent-a');
    const invitee = await signup('consent-b');
    const twin = await postedTwin(inviter, invitee);
    for (const user of [inviter, invitee]) {
      await request(app.getHttpServer())
        .put(`/api/twins/${twin.id}/visibility`)
        .set(auth(user.token))
        .send({ visibility: 'joint' })
        .expect(200);
    }
    const response = await request(app.getHttpServer())
      .post(`/api/twins/${twin.id}/consent`)
      .set(auth(inviter.token))
      .expect(201);
    expect(response.body).toMatchObject({
      status: 'CONSENT_WAITING',
      myConsented: true,
      partnerConsented: false,
    });
    const changed = await request(app.getHttpServer())
      .put(`/api/twins/${twin.id}/visibility`)
      .set(auth(invitee.token))
      .send({ visibility: 'private' })
      .expect(200);
    expect(changed.body).toMatchObject({
      myVisibility: 'private',
      myConsented: false,
      partnerConsented: false,
    });
  });
  it('POST /api/twins/:id/consent: 로그인 없이 부르면 → 401 AUTH_REQUIRED', async () => {
    const response = await request(app.getHttpServer())
      .post(`/api/twins/${randomUUID()}/consent`)
      .expect(401);
    expect(response.body.error.code).toBe('AUTH_REQUIRED');
  });
  it('POST /api/twins/:id/consent: 참여자가 아니거나 없는 트윈 → 404 NOT_FOUND', async () => {
    const user = await signup('consent-missing');
    const response = await request(app.getHttpServer())
      .post(`/api/twins/${randomUUID()}/consent`)
      .set(auth(user.token))
      .expect(404);
    expect(response.body.error.code).toBe('NOT_FOUND');
  });
  it('POST /api/twins/:id/consent: 지금 단계에서는 할 수 없는 작업이에요 → 409 TWIN_STATE', async () => {
    const inviter = await signup('consent-state-a');
    const invitee = await signup('consent-state-b');
    const twin = await postedTwin(inviter, invitee);
    const response = await request(app.getHttpServer())
      .post(`/api/twins/${twin.id}/consent`)
      .set(auth(inviter.token))
      .expect(409);
    expect(response.body.error.code).toBe('TWIN_STATE');
  });
  // twins.publish · 접근: member · 응답: TwinDto · 계약: P01, P09, P10
  it('POST /api/twins/:id/publish: 공동 표지 발행(두 사람 동의 후) → 201', async () => {
    const inviter = await signup('publish-a');
    const invitee = await signup('publish-b');
    const twin = await postedTwin(inviter, invitee);
    for (const user of [inviter, invitee]) {
      await request(app.getHttpServer())
        .put(`/api/twins/${twin.id}/visibility`)
        .set(auth(user.token))
        .send({ visibility: 'joint' })
        .expect(200);
    }
    for (const user of [inviter, invitee]) {
      await request(app.getHttpServer())
        .post(`/api/twins/${twin.id}/consent`)
        .set(auth(user.token))
        .expect(201);
    }
    const response = await request(app.getHttpServer())
      .post(`/api/twins/${twin.id}/publish`)
      .set(auth(inviter.token))
      .expect(201);
    expect(response.body).toMatchObject({
      status: 'PUBLISHED',
      myConsented: true,
      partnerConsented: true,
      publishedAt: expect.any(String),
    });
    expect(await prisma.issue.count()).toBe(0);
    expect(await prisma.userDailyChoice.count()).toBe(0);
    expect(
      await prisma.profile.findMany({
        where: { userId: { in: [inviter.userId, invitee.userId] } },
        select: { issueCount: true },
      }),
    ).toEqual([{ issueCount: 0 }, { issueCount: 0 }]);
  });
  it('POST /api/twins/:id/publish: 로그인 없이 부르면 → 401 AUTH_REQUIRED', async () => {
    const response = await request(app.getHttpServer())
      .post(`/api/twins/${randomUUID()}/publish`)
      .expect(401);
    expect(response.body.error.code).toBe('AUTH_REQUIRED');
  });
  it('POST /api/twins/:id/publish: 참여자가 아니거나 없는 트윈 → 404 NOT_FOUND', async () => {
    const user = await signup('publish-missing');
    const response = await request(app.getHttpServer())
      .post(`/api/twins/${randomUUID()}/publish`)
      .set(auth(user.token))
      .expect(404);
    expect(response.body.error.code).toBe('NOT_FOUND');
  });
  it('POST /api/twins/:id/publish: 지금 단계에서는 할 수 없는 작업이에요 → 409 TWIN_STATE', async () => {
    const inviter = await signup('publish-state-a');
    const invitee = await signup('publish-state-b');
    const twin = await postedTwin(inviter, invitee);
    const response = await request(app.getHttpServer())
      .post(`/api/twins/${twin.id}/publish`)
      .set(auth(inviter.token))
      .expect(409);
    expect(response.body.error.code).toBe('TWIN_STATE');
  });
  it('POST /api/twins/:id/publish: 두 사람 모두 동의해야 공개할 수 있어요 → 409 TWIN_CONSENT_REQUIRED', async () => {
    const inviter = await signup('publish-consent-a');
    const invitee = await signup('publish-consent-b');
    const twin = await postedTwin(inviter, invitee);
    for (const user of [inviter, invitee]) {
      await request(app.getHttpServer())
        .put(`/api/twins/${twin.id}/visibility`)
        .set(auth(user.token))
        .send({ visibility: 'joint' })
        .expect(200);
    }
    await request(app.getHttpServer())
      .post(`/api/twins/${twin.id}/consent`)
      .set(auth(inviter.token))
      .expect(201);
    const response = await request(app.getHttpServer())
      .post(`/api/twins/${twin.id}/publish`)
      .set(auth(inviter.token))
      .expect(409);
    expect(response.body.error.code).toBe('TWIN_CONSENT_REQUIRED');
    expect(
      (await prisma.twin.findUniqueOrThrow({ where: { id: twin.id } }))
        .publishedAt,
    ).toBeNull();
  });
  it('합격 기준(P10): solo 선택 한 명만으로 상대 사진을 공동 공개할 수 없음', async () => {
    const inviter = await signup('solo-a');
    const invitee = await signup('solo-b');
    const twin = await postedTwin(inviter, invitee);
    await request(app.getHttpServer())
      .put(`/api/twins/${twin.id}/visibility`)
      .set(auth(inviter.token))
      .send({ visibility: 'solo' })
      .expect(200);
    expect(
      (await prisma.twin.findUniqueOrThrow({ where: { id: twin.id } }))
        .publishedAt,
    ).toBeNull();
  });
});

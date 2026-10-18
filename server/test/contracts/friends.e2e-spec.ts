import { INestApplication } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import { App } from 'supertest/types.js';
import { PrismaService } from '../../src/prisma/prisma.service.js';
import { createTestApp } from '../create-app.js';

// 계약 테스트: friends 모듈. api-contract.json의 API와 루트 docs/dev/features.json의 서버 합격 기준을 할 일(it.todo)로 적어 두었다.
// 이 파일은 손으로 관리한다. API마다 'METHOD /api/경로: … → 상태' 형식의 todo나 테스트가 있어야 하고, 상태 코드는 api-contract.json과 같아야 한다(npm run check:server가 확인).
// 하나를 구현하면 그 todo를 it(…) 안에서 request(app.getHttpServer()).<method>('/api/…')로 부르는 실제 테스트로 바꾸고, api-contract.json의 status를 done으로 바꾼다.
// 실행: npm run test:e2e (todo는 실패가 아니라 '남은 일'로 표시된다)

describe('DEV-16 친구', () => {
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
    await prisma.user.deleteMany({
      where: { email: { endsWith: '@friends.e2e.test' } },
    });
  }

  async function signup(label: string) {
    const response = await request(app.getHttpServer())
      .post('/api/auth/email/signup')
      .send({
        email: `${label}-${randomUUID()}@friends.e2e.test`,
        password: 'correct horse battery staple',
      })
      .expect(201);
    let mastheadSuffix = '';
    for (
      let value = sequence++;
      value >= 0;
      value = Math.floor(value / 26) - 1
    ) {
      mastheadSuffix = String.fromCharCode(97 + (value % 26)) + mastheadSuffix;
    }
    const user = {
      token: response.body.accessToken as string,
      masthead: `f${mastheadSuffix}`,
      userId: response.body.userId as string,
    };
    await prisma.profile.create({
      data: { userId: user.userId, masthead: user.masthead },
    });
    return user;
  }

  const auth = (token: string) => ({ Authorization: `Bearer ${token}` });

  async function sendFriendRequest(
    sender: { token: string },
    receiver: { masthead: string },
  ) {
    const response = await request(app.getHttpServer())
      .post('/api/friends/requests')
      .set(auth(sender.token))
      .send({ masthead: receiver.masthead })
      .expect(201);
    return response.body as {
      id: string;
      masthead: string;
      createdAt: string;
    };
  }

  async function becomeFriends(
    sender: { token: string },
    receiver: { token: string; masthead: string },
  ) {
    const friendRequest = await sendFriendRequest(sender, receiver);
    return request(app.getHttpServer())
      .post(`/api/friends/requests/${friendRequest.id}/accept`)
      .set(auth(receiver.token))
      .expect(201);
  }

  // users.lookup · 접근: user · 응답: UserPublicDto · 계약: P18
  it('GET /api/users/:masthead: 제호로 사람 찾기(친구 요청 전 확인) → 200', async () => {
    const target = await signup('target');
    const viewer = await signup('viewer');
    const response = await request(app.getHttpServer())
      .get(`/api/users/${target.masthead}`)
      .set(auth(viewer.token))
      .expect(200);
    expect(response.body).toEqual({ masthead: target.masthead, issueCount: 0 });
    expect(response.body).not.toHaveProperty('userId');
    expect(response.body).not.toHaveProperty('subscriberCount');
  });
  it('GET /api/users/:masthead: 로그인 없이 부르면 → 401 AUTH_REQUIRED', async () => {
    const response = await request(app.getHttpServer())
      .get('/api/users/unknown')
      .expect(401);
    expect(response.body.error.code).toBe('AUTH_REQUIRED');
  });
  it('GET /api/users/:masthead: 없는 제호 → 404 NOT_FOUND', async () => {
    const viewer = await signup('missing');
    const response = await request(app.getHttpServer())
      .get('/api/users/unknown')
      .set(auth(viewer.token))
      .expect(404);
    expect(response.body.error.code).toBe('NOT_FOUND');
  });
  // friends.list · 접근: user · 응답: Page<FriendDto>
  it('GET /api/friends: 내 친구 목록 → 200', async () => {
    const sender = await signup('list-sender');
    const receiver = await signup('list-receiver');
    await becomeFriends(sender, receiver);

    const response = await request(app.getHttpServer())
      .get('/api/friends')
      .set(auth(sender.token))
      .expect(200);
    expect(response.body).toEqual({
      items: [
        {
          friendId: receiver.userId,
          masthead: receiver.masthead,
          friendsSince: expect.any(String),
        },
      ],
      nextCursor: null,
    });
  });
  it('GET /api/friends: 로그인 없이 부르면 → 401 AUTH_REQUIRED', async () => {
    const response = await request(app.getHttpServer())
      .get('/api/friends')
      .expect(401);
    expect(response.body.error.code).toBe('AUTH_REQUIRED');
  });
  // friends.requests · 접근: user · 응답: Page<FriendRequestDto>
  it('GET /api/friends/requests: 받은 친구 요청 → 200', async () => {
    const sender = await signup('requests-sender');
    const receiver = await signup('requests-receiver');
    const friendRequest = await sendFriendRequest(sender, receiver);

    const response = await request(app.getHttpServer())
      .get('/api/friends/requests')
      .set(auth(receiver.token))
      .expect(200);
    expect(response.body).toEqual({
      items: [
        {
          id: friendRequest.id,
          masthead: sender.masthead,
          createdAt: expect.any(String),
        },
      ],
      nextCursor: null,
    });
  });
  it('GET /api/friends/requests: 로그인 없이 부르면 → 401 AUTH_REQUIRED', async () => {
    const response = await request(app.getHttpServer())
      .get('/api/friends/requests')
      .expect(401);
    expect(response.body.error.code).toBe('AUTH_REQUIRED');
  });
  // friends.request · 접근: user · 응답: FriendRequestDto · 계약: P12
  it('POST /api/friends/requests: 친구 요청 보내기 → 201', async () => {
    const sender = await signup('request-sender');
    const receiver = await signup('request-receiver');
    const response = await request(app.getHttpServer())
      .post('/api/friends/requests')
      .set(auth(sender.token))
      .send({ masthead: receiver.masthead })
      .expect(201);
    expect(response.body).toEqual({
      id: expect.any(String),
      masthead: receiver.masthead,
      createdAt: expect.any(String),
    });
  });
  it('POST /api/friends/requests: 로그인 없이 부르면 → 401 AUTH_REQUIRED', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/friends/requests')
      .send({ masthead: 'unknown' })
      .expect(401);
    expect(response.body.error.code).toBe('AUTH_REQUIRED');
  });
  it('POST /api/friends/requests: 보낸 값의 형식이 맞지 않아요 → 400 VALIDATION', async () => {
    const sender = await signup('request-invalid');
    const response = await request(app.getHttpServer())
      .post('/api/friends/requests')
      .set(auth(sender.token))
      .send({ masthead: 'NOT VALID' })
      .expect(400);
    expect(response.body.error.code).toBe('VALIDATION');
  });
  it('POST /api/friends/requests: 없는 제호 → 404 NOT_FOUND', async () => {
    const sender = await signup('request-missing');
    const response = await request(app.getHttpServer())
      .post('/api/friends/requests')
      .set(auth(sender.token))
      .send({ masthead: 'unknown' })
      .expect(404);
    expect(response.body.error.code).toBe('NOT_FOUND');
  });
  it('POST /api/friends/requests: 이미 친구예요 → 409 ALREADY_FRIENDS', async () => {
    const sender = await signup('request-friend-a');
    const receiver = await signup('request-friend-b');
    await becomeFriends(sender, receiver);

    const response = await request(app.getHttpServer())
      .post('/api/friends/requests')
      .set(auth(sender.token))
      .send({ masthead: receiver.masthead })
      .expect(409);
    expect(response.body.error.code).toBe('ALREADY_FRIENDS');
  });
  it('POST /api/friends/requests: 이미 보낸 요청이 있어요 → 409 REQUEST_EXISTS', async () => {
    const sender = await signup('request-duplicate-a');
    const receiver = await signup('request-duplicate-b');
    await sendFriendRequest(sender, receiver);

    const response = await request(app.getHttpServer())
      .post('/api/friends/requests')
      .set(auth(receiver.token))
      .send({ masthead: sender.masthead })
      .expect(409);
    expect(response.body.error.code).toBe('REQUEST_EXISTS');
  });
  // friends.accept · 접근: user · 응답: FriendDto
  it('POST /api/friends/requests/:id/accept: 받은 요청 수락 → 201', async () => {
    const sender = await signup('accept-sender');
    const receiver = await signup('accept-receiver');
    const friendRequest = await sendFriendRequest(sender, receiver);
    const response = await request(app.getHttpServer())
      .post(`/api/friends/requests/${friendRequest.id}/accept`)
      .set(auth(receiver.token))
      .expect(201);
    expect(response.body).toEqual({
      friendId: sender.userId,
      masthead: sender.masthead,
      friendsSince: expect.any(String),
    });
    const participantIds = [sender.userId, receiver.userId];
    expect(
      await prisma.friendRequest.count({
        where: {
          OR: [
            { senderId: { in: participantIds } },
            { receiverId: { in: participantIds } },
          ],
        },
      }),
    ).toBe(0);
    expect(
      await prisma.friendship.count({
        where: {
          OR: [
            { userAId: { in: participantIds } },
            { userBId: { in: participantIds } },
          ],
        },
      }),
    ).toBe(1);
  });
  it('POST /api/friends/requests/:id/accept: 로그인 없이 부르면 → 401 AUTH_REQUIRED', async () => {
    const response = await request(app.getHttpServer())
      .post(`/api/friends/requests/${randomUUID()}/accept`)
      .expect(401);
    expect(response.body.error.code).toBe('AUTH_REQUIRED');
  });
  it('POST /api/friends/requests/:id/accept: 내가 보낸 요청을 내가 수락함 → 403 FORBIDDEN', async () => {
    const sender = await signup('accept-self-a');
    const receiver = await signup('accept-self-b');
    const friendRequest = await sendFriendRequest(sender, receiver);
    const response = await request(app.getHttpServer())
      .post(`/api/friends/requests/${friendRequest.id}/accept`)
      .set(auth(sender.token))
      .expect(403);
    expect(response.body.error.code).toBe('FORBIDDEN');
  });
  it('POST /api/friends/requests/:id/accept: 없거나 나와 상관없는 요청 → 404 NOT_FOUND', async () => {
    const sender = await signup('accept-other-a');
    const receiver = await signup('accept-other-b');
    const stranger = await signup('accept-other-c');
    const friendRequest = await sendFriendRequest(sender, receiver);
    const response = await request(app.getHttpServer())
      .post(`/api/friends/requests/${friendRequest.id}/accept`)
      .set(auth(stranger.token))
      .expect(404);
    expect(response.body.error.code).toBe('NOT_FOUND');
  });
  // friends.decline · 접근: user · 응답: void
  it('POST /api/friends/requests/:id/decline: 받은 요청 나중에(거절) → 204', async () => {
    const sender = await signup('decline-sender');
    const receiver = await signup('decline-receiver');
    const friendRequest = await sendFriendRequest(sender, receiver);
    await request(app.getHttpServer())
      .post(`/api/friends/requests/${friendRequest.id}/decline`)
      .set(auth(receiver.token))
      .expect(204);
    expect(await prisma.friendRequest.count()).toBe(0);
  });
  it('POST /api/friends/requests/:id/decline: 로그인 없이 부르면 → 401 AUTH_REQUIRED', async () => {
    const response = await request(app.getHttpServer())
      .post(`/api/friends/requests/${randomUUID()}/decline`)
      .expect(401);
    expect(response.body.error.code).toBe('AUTH_REQUIRED');
  });
  it('POST /api/friends/requests/:id/decline: 내가 보낸 요청을 내가 거절함 → 403 FORBIDDEN', async () => {
    const sender = await signup('decline-self-a');
    const receiver = await signup('decline-self-b');
    const friendRequest = await sendFriendRequest(sender, receiver);
    const response = await request(app.getHttpServer())
      .post(`/api/friends/requests/${friendRequest.id}/decline`)
      .set(auth(sender.token))
      .expect(403);
    expect(response.body.error.code).toBe('FORBIDDEN');
  });
  it('POST /api/friends/requests/:id/decline: 없거나 나와 상관없는 요청 → 404 NOT_FOUND', async () => {
    const sender = await signup('decline-other-a');
    const receiver = await signup('decline-other-b');
    const stranger = await signup('decline-other-c');
    const friendRequest = await sendFriendRequest(sender, receiver);
    const response = await request(app.getHttpServer())
      .post(`/api/friends/requests/${friendRequest.id}/decline`)
      .set(auth(stranger.token))
      .expect(404);
    expect(response.body.error.code).toBe('NOT_FOUND');
  });
  it('합격 기준: 같은 사람에게 친구 요청을 두 번 만들 수 없음(동시에 보내도 하나)', async () => {
    const sender = await signup('concurrent-a');
    const receiver = await signup('concurrent-b');
    const responses = await Promise.all(
      Array.from({ length: 2 }, () =>
        request(app.getHttpServer())
          .post('/api/friends/requests')
          .set(auth(sender.token))
          .send({ masthead: receiver.masthead }),
      ),
    );
    expect(responses.map(({ status }) => status).sort((a, b) => a - b)).toEqual(
      [201, 409],
    );
    expect(await prisma.friendRequest.count()).toBe(1);
  });
});

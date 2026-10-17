import { INestApplication } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import request from 'supertest';
import { App } from 'supertest/types.js';
import { serviceDate } from '../../src/common/service-date.js';
import { PrismaService } from '../../src/prisma/prisma.service.js';
import { createTestApp } from '../create-app.js';
import { createLockedIssuePerCandidate } from '../p01-fixtures.js';

// 계약 테스트: today 모듈. api-contract.json의 API와 루트 docs/dev/features.json의 서버 합격 기준을 할 일(it.todo)로 적어 두었다.
// 이 파일은 손으로 관리한다. API마다 'METHOD /api/경로: … → 상태' 형식의 todo나 테스트가 있어야 하고, 상태 코드는 api-contract.json과 같아야 한다(npm run check:server가 확인).
// 하나를 구현하면 그 todo를 it(…) 안에서 request(app.getHttpServer()).<method>('/api/…')로 부르는 실제 테스트로 바꾸고, api-contract.json의 status를 done으로 바꾼다.
// 실행: npm run test:e2e (todo는 실패가 아니라 '남은 일'로 표시된다)

describe('DEV-04 비로그인 첫 표지와 로그인 바', () => {
  // today.cover · 접근: public · 응답: TodayCoverPublicDto · 계약: P01, P12, P18
  it.todo('GET /api/today/cover: 비로그인용 오늘의 표지와 안쪽 2쪽 → 200');
  it.todo(
    '합격 기준(P12): 비로그인에게는 표지 1장과 안쪽 2쪽까지만 줌(3번째 지면 이후는 응답에 없음)',
  );
  it.todo(
    '합격 기준(P01): 오늘 후보 색 표지는 각 방의 미리보기(최신 3장) 안에서만 고름. 로그인 없이 불러 잠긴 표지를 보는 우회를 막음',
  );
  it.todo('합격 기준(P18): 응답에 반응 숫자가 없음');
});

describe('DEV-07 오늘의 색', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  let timeZone: string;

  beforeAll(async () => {
    app = await createTestApp();
    prisma = app.get(PrismaService);
    timeZone = app.get(ConfigService).getOrThrow<string>('SERVICE_TIME_ZONE');
    await cleanupFixtures();
  });

  afterEach(cleanupFixtures);

  afterAll(async () => {
    await app.close();
  });

  async function cleanupFixtures() {
    await prisma.issue.deleteMany({
      where: { author: { email: { endsWith: '@today.e2e.test' } } },
    });
    await prisma.user.deleteMany({
      where: { email: { endsWith: '@today.e2e.test' } },
    });
  }

  async function signup(name: string) {
    const response = await request(app.getHttpServer())
      .post('/api/auth/email/signup')
      .send({
        email: `${name}@today.e2e.test`,
        password: 'correct horse battery staple',
      })
      .expect(201);
    return {
      userId: response.body.userId as string,
      token: response.body.accessToken as string,
    };
  }

  const auth = (token: string) => ({ Authorization: `Bearer ${token}` });

  // today.get · 접근: user · 응답: TodayDto · 계약: P05, P17
  it('GET /api/today: 오늘의 날짜, 후보 3색, 내 선택, 발행 여부 → 200', async () => {
    const user = await signup('get-today');
    const response = await request(app.getHttpServer())
      .get('/api/today')
      .set(auth(user.token))
      .expect(200);

    expect(response.body).toMatchObject({
      serviceDate: serviceDate(new Date(), timeZone),
      selectedColorId: null,
      hasPublishedToday: false,
    });
    expect(response.body.candidates).toHaveLength(3);
    for (const candidate of response.body.candidates as Record<
      string,
      unknown
    >[]) {
      expect(candidate).toEqual({
        id: expect.any(String),
        nameKo: expect.any(String),
        nameEn: expect.any(String),
        hex: expect.stringMatching(/^#[0-9A-Fa-f]{6}$/),
      });
    }
  });

  it('GET /api/today: 로그인 없이 부르면 → 401 AUTH_REQUIRED', async () => {
    const response = await request(app.getHttpServer())
      .get('/api/today')
      .expect(401);
    expect(response.body.error.code).toBe('AUTH_REQUIRED');
  });

  // today.choose · 접근: user · 응답: TodayDto · 계약: P01, P03, P05
  it('PUT /api/today/choice: 오늘의 색 고르기(발행 전까지 바꿀 수 있음) → 200', async () => {
    const user = await signup('choose');
    const today = await request(app.getHttpServer())
      .get('/api/today')
      .set(auth(user.token))
      .expect(200);
    const colorId = today.body.candidates[0].id as string;

    const response = await request(app.getHttpServer())
      .put('/api/today/choice')
      .set(auth(user.token))
      .send({ colorId })
      .expect(200);

    expect(response.body.selectedColorId).toBe(colorId);
    const choice = await prisma.userDailyChoice.findFirstOrThrow({
      where: { userId: user.userId },
    });
    expect(choice.colorId).toBe(colorId);
    expect(choice.lockedAt).toBeNull();
  });

  it('PUT /api/today/choice: 로그인 없이 부르면 → 401 AUTH_REQUIRED', async () => {
    const response = await request(app.getHttpServer())
      .put('/api/today/choice')
      .send({ colorId: 'camel' })
      .expect(401);
    expect(response.body.error.code).toBe('AUTH_REQUIRED');
  });

  it('PUT /api/today/choice: 보낸 값의 형식이 맞지 않아요 → 400 VALIDATION', async () => {
    const user = await signup('invalid-choice');
    const response = await request(app.getHttpServer())
      .put('/api/today/choice')
      .set(auth(user.token))
      .send({ colorId: 123 })
      .expect(400);
    expect(response.body.error.code).toBe('VALIDATION');
  });

  it('PUT /api/today/choice: 오늘 호를 발행해서 색을 바꿀 수 없어요 → 409 CHOICE_LOCKED', async () => {
    const user = await signup('locked-choice');
    const today = await request(app.getHttpServer())
      .get('/api/today')
      .set(auth(user.token))
      .expect(200);
    const [first, second] = today.body.candidates as { id: string }[];
    await request(app.getHttpServer())
      .put('/api/today/choice')
      .set(auth(user.token))
      .send({ colorId: first?.id })
      .expect(200);
    await prisma.userDailyChoice.updateMany({
      where: { userId: user.userId },
      data: { lockedAt: new Date() },
    });

    const response = await request(app.getHttpServer())
      .put('/api/today/choice')
      .set(auth(user.token))
      .send({ colorId: second?.id })
      .expect(409);
    expect(response.body.error.code).toBe('CHOICE_LOCKED');
  });

  it('PUT /api/today/choice: 오늘 후보에 없는 색이에요 → 422 COLOR_NOT_CANDIDATE', async () => {
    const user = await signup('outside-choice');
    const today = await request(app.getHttpServer())
      .get('/api/today')
      .set(auth(user.token))
      .expect(200);
    const candidateIds = new Set<string>(
      (today.body.candidates as { id: string }[]).map(({ id }) => id),
    );
    const outside = await prisma.color.findFirstOrThrow({
      where: { id: { notIn: [...candidateIds] } },
    });

    const response = await request(app.getHttpServer())
      .put('/api/today/choice')
      .set(auth(user.token))
      .send({ colorId: outside.id })
      .expect(422);
    expect(response.body.error.code).toBe('COLOR_NOT_CANDIDATE');
  });

  it('합격 기준(P17): 후보는 12색 중 서로 다른 3색이고 서비스 날짜(SERVICE_TIME_ZONE 자정 기준)로 정해짐', async () => {
    const firstUser = await signup('candidate-a');
    const secondUser = await signup('candidate-b');
    const [first, second] = await Promise.all([
      request(app.getHttpServer()).get('/api/today').set(auth(firstUser.token)),
      request(app.getHttpServer())
        .get('/api/today')
        .set(auth(secondUser.token)),
    ]);
    const ids = (first.body.candidates as { id: string }[]).map(({ id }) => id);

    expect(first.status).toBe(200);
    expect(second.status).toBe(200);
    expect(first.body.serviceDate).toBe(serviceDate(new Date(), timeZone));
    expect(second.body.candidates).toEqual(first.body.candidates);
    expect(ids).toHaveLength(3);
    expect(new Set(ids)).toHaveLength(3);
    expect(await prisma.color.count({ where: { id: { in: ids } } })).toBe(3);
  });

  it('합격 기준: 후보 밖의 색은 고를 수 없음', async () => {
    const user = await signup('outside-acceptance');
    const today = await request(app.getHttpServer())
      .get('/api/today')
      .set(auth(user.token));
    const ids = (today.body.candidates as { id: string }[]).map(({ id }) => id);
    const outside = await prisma.color.findFirstOrThrow({
      where: { id: { notIn: ids } },
    });

    await request(app.getHttpServer())
      .put('/api/today/choice')
      .set(auth(user.token))
      .send({ colorId: outside.id })
      .expect(422);
    expect(
      await prisma.userDailyChoice.count({ where: { userId: user.userId } }),
    ).toBe(0);
  });

  it('합격 기준(P01·P03): 색을 고르거나 바꾸기만 해서는 어느 같은 색 방도 열리지 않음', async () => {
    const user = await signup('change-choice');
    const today = await request(app.getHttpServer())
      .get('/api/today')
      .set(auth(user.token));
    const candidateIds = (today.body.candidates as { id: string }[]).map(
      ({ id }) => id,
    );
    const lockedIssueIds = await createLockedIssuePerCandidate(
      prisma,
      candidateIds,
      today.body.serviceDate as string,
      'today.e2e.test',
      'today-p01',
    );

    const expectAllCandidateRoomsLocked = async () => {
      for (const issueId of lockedIssueIds) {
        const response = await request(app.getHttpServer())
          .get(`/api/issues/${issueId}`)
          .set(auth(user.token))
          .expect(404);
        expect(response.body.error.code).toBe('NOT_FOUND');
      }
    };

    for (const colorId of candidateIds) {
      await request(app.getHttpServer())
        .put('/api/today/choice')
        .set(auth(user.token))
        .send({ colorId })
        .expect(200);
      await expectAllCandidateRoomsLocked();
    }

    const choice = await prisma.userDailyChoice.findFirstOrThrow({
      where: { userId: user.userId },
    });
    expect(choice.colorId).toBe(candidateIds.at(-1));
    expect(choice.lockedAt).toBeNull();
    await prisma.userDailyChoice.update({
      where: { id: choice.id },
      data: { lockedAt: new Date() },
    });
    await expectAllCandidateRoomsLocked();
  });

  it('합격 기준: 발행 후 색 변경은 거절', async () => {
    const user = await signup('published-lock');
    const today = await request(app.getHttpServer())
      .get('/api/today')
      .set(auth(user.token));
    const [first, second] = today.body.candidates as { id: string }[];
    await request(app.getHttpServer())
      .put('/api/today/choice')
      .set(auth(user.token))
      .send({ colorId: first?.id });
    await prisma.userDailyChoice.updateMany({
      where: { userId: user.userId },
      data: { lockedAt: new Date() },
    });

    const response = await request(app.getHttpServer())
      .put('/api/today/choice')
      .set(auth(user.token))
      .send({ colorId: second?.id })
      .expect(409);
    expect(response.body.error.code).toBe('CHOICE_LOCKED');
  });
});

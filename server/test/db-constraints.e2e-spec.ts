import { INestApplication } from '@nestjs/common';
import { App } from 'supertest/types.js';
import { PrismaService } from '../src/prisma/prisma.service.js';
import { createTestApp } from './create-app.js';

// migration 20261015130000_add_checks_and_colors가 하네스 규칙을 DB에서 직접 막는지 확인한다.
// API를 거치지 않고 잘못된 값을 넣어도 DB가 거절해야 한다(동시 요청·버그·직접 수정 방어).
describe('DB 제약과 12색 (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;

  beforeAll(async () => {
    app = await createTestApp();
    prisma = app.get(PrismaService);
  });

  afterAll(async () => {
    await app.close();
  });

  it('12색이 순서대로 들어 있다', async () => {
    const colors = await prisma.color.findMany({
      orderBy: { sortOrder: 'asc' },
    });
    expect(colors).toHaveLength(12);
    expect(colors[0]).toMatchObject({
      id: 'sage',
      hex: '#A8B5A0',
      sortOrder: 1,
    });
    expect(colors[11]).toMatchObject({
      id: 'cobalt',
      hex: '#2648B0',
      sortOrder: 12,
    });
  });

  it('제호는 영문 소문자 2~10자만 저장된다(P14)', async () => {
    for (const masthead of ['Selin', 'a', 'selin1', 'sé']) {
      await expect(
        prisma.profile.create({ data: { masthead, user: { create: {} } } }),
      ).rejects.toThrow(/profiles_masthead_format_check/);
    }
  });

  it('색 hex는 #과 대문자 16진수 6자리만 저장된다', async () => {
    await expect(
      prisma.color.create({
        data: {
          id: 'test-hex',
          nameKo: '시험',
          nameEn: 'Test',
          hex: '#a8b5a0',
          sortOrder: 99,
        },
      }),
    ).rejects.toThrow(/colors_hex_format_check/);
  });

  it('하루 후보 색 자리는 1~3번뿐이다(P17)', async () => {
    await expect(
      prisma.dailyPalette.create({
        data: {
          serviceDate: new Date('1999-01-01'),
          colors: { create: [{ colorId: 'sage', position: 4 }] },
        },
      }),
    ).rejects.toThrow(/daily_palette_colors_position_check/);
  });

  it('개인 호수는 1호부터다(P04)', async () => {
    const user = await prisma.user.create({ data: {} });
    try {
      const media = await prisma.mediaAsset.create({
        data: {
          ownerId: user.id,
          storageKey: `test/${user.id}`,
          mimeType: 'image/jpeg',
          sizeBytes: 1,
        },
      });
      await expect(
        prisma.issue.create({
          data: {
            authorId: user.id,
            serviceDate: new Date('1999-01-01'),
            issueNumber: 0,
            colorId: 'sage',
            mediaId: media.id,
            caption: '',
            faceCrop: 'ORIGINAL',
            paintStroke: false,
          },
        }),
      ).rejects.toThrow(/issues_issue_number_check/);
    } finally {
      await prisma.user.delete({ where: { id: user.id } });
    }
  });

  it('목 아래 자르기에는 물감 연출을 함께 저장할 수 없다', async () => {
    const user = await prisma.user.create({ data: {} });
    try {
      const media = await prisma.mediaAsset.create({
        data: {
          ownerId: user.id,
          storageKey: `face-constraint/${user.id}`,
          mimeType: 'image/jpeg',
          sizeBytes: 1,
        },
      });
      await expect(
        prisma.issue.create({
          data: {
            authorId: user.id,
            serviceDate: new Date('1999-01-02'),
            issueNumber: 1,
            colorId: 'sage',
            mediaId: media.id,
            caption: '',
            faceCrop: 'BELOW_NECK',
            paintStroke: true,
          },
        }),
      ).rejects.toThrow(/issues_below_neck_without_paint_check/);
    } finally {
      await prisma.user.delete({ where: { id: user.id } });
    }
  });
});

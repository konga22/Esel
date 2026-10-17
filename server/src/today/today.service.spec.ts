import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service.js';
import { TodayService } from './today.service.js';

describe('TodayService', () => {
  it('GET용 get은 팔레트가 없어도 계산만 하고 DB를 바꾸지 않는다', async () => {
    const createPalette = vi.fn();
    const colors = [
      'sage',
      'butter',
      'powder',
      'coral',
      'lilac',
      'terracotta',
      'burgundy',
      'olive',
      'cream',
      'charcoal',
      'camel',
      'cobalt',
    ].map((id, index) => ({
      id,
      nameKo: id,
      nameEn: id,
      hex: '#000000',
      sortOrder: index + 1,
    }));
    const prisma = {
      dailyPalette: {
        findUnique: vi.fn().mockResolvedValue(null),
        create: createPalette,
      },
      color: { findMany: vi.fn().mockResolvedValue(colors) },
      userDailyChoice: { findUnique: vi.fn().mockResolvedValue(null) },
      issue: { findUnique: vi.fn().mockResolvedValue(null) },
    } as unknown as PrismaService;
    const config = {
      getOrThrow: vi.fn().mockReturnValue('Asia/Seoul'),
    } as unknown as ConfigService;

    const result = await new TodayService(prisma, config).get('user-id');

    expect(result.candidates).toHaveLength(3);
    expect(createPalette).not.toHaveBeenCalled();
  });
});

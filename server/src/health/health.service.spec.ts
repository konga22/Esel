import { ServiceUnavailableException } from '@nestjs/common';
import { describe, expect, it, vi } from 'vitest';
import { PrismaService } from '../prisma/prisma.service.js';
import { HealthService } from './health.service.js';

describe('HealthService', () => {
  it('reports an available database', async () => {
    const prisma = {
      $queryRaw: vi.fn().mockResolvedValue([{ '?column?': 1 }]),
    };
    const service = new HealthService(prisma as unknown as PrismaService);

    await expect(service.check()).resolves.toMatchObject({
      status: 'ok',
      database: 'up',
    });
  });

  it('reports an unavailable database', async () => {
    const prisma = {
      $queryRaw: vi.fn().mockRejectedValue(new Error('offline')),
    };
    const service = new HealthService(prisma as unknown as PrismaService);

    await expect(service.check()).rejects.toBeInstanceOf(
      ServiceUnavailableException,
    );
  });
});

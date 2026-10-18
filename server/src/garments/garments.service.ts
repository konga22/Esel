import { Injectable } from '@nestjs/common';
import { AppException } from '../common/app-exception.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { GarmentPageDto } from './dto/garment-page.dto.js';

const UUID_PATTERN =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

@Injectable()
export class GarmentsService {
  constructor(private readonly prisma: PrismaService) {}

  async mine(userId: string, cursor?: string): Promise<GarmentPageDto> {
    const value = cursor ? this.decodeCursor(cursor) : null;
    const garments = await this.prisma.garment.findMany({
      where: {
        ownerId: userId,
        ...(value
          ? {
              OR: [
                { createdAt: { lt: value.createdAt } },
                { createdAt: value.createdAt, id: { lt: value.id } },
              ],
            }
          : {}),
      },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take: 21,
    });
    const page = garments.slice(0, 20);
    const last = page.at(-1);
    return {
      items: page.map((garment) => ({
        id: garment.id,
        kind: garment.kind,
        name: garment.name,
        note: garment.note,
        createdAt: garment.createdAt.toISOString(),
      })),
      nextCursor:
        garments.length > 20 && last
          ? this.encodeCursor(last.createdAt, last.id)
          : null,
    };
  }

  private encodeCursor(createdAt: Date, id: string): string {
    return Buffer.from(
      JSON.stringify({ createdAt: createdAt.toISOString(), id }),
    ).toString('base64url');
  }

  private decodeCursor(cursor: string): { createdAt: Date; id: string } {
    try {
      const value = JSON.parse(
        Buffer.from(cursor, 'base64url').toString('utf8'),
      ) as { createdAt?: unknown; id?: unknown };
      if (
        typeof value.createdAt !== 'string' ||
        typeof value.id !== 'string' ||
        !UUID_PATTERN.test(value.id)
      ) {
        throw new Error('invalid cursor');
      }
      const createdAt = new Date(value.createdAt);
      if (Number.isNaN(createdAt.getTime())) throw new Error('invalid cursor');
      return { createdAt, id: value.id };
    } catch {
      throw new AppException('VALIDATION', {
        cursor: ['cursor가 올바르지 않아요.'],
      });
    }
  }
}

import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AppException } from '../common/app-exception.js';
import { serviceDate } from '../common/service-date.js';
import { IssuesService } from '../issues/issues.service.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { dailyCandidateIds } from '../today/today.rules.js';
import { FeedPageDto } from './dto/feed-page.dto.js';
import { FeedItemDto } from './dto/feed-item.dto.js';

const UUID_PATTERN =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

@Injectable()
export class FeedService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly issuesService: IssuesService,
    private readonly config: ConfigService,
  ) {}

  async list(userId: string, cursor?: string): Promise<FeedPageDto> {
    const key = serviceDate(
      new Date(),
      this.config.getOrThrow<string>('SERVICE_TIME_ZONE'),
    );
    const today = new Date(`${key}T00:00:00.000Z`);
    const [ownIssue, candidateIds, subscriptions] = await Promise.all([
      this.prisma.issue.findUnique({
        where: {
          authorId_serviceDate: { authorId: userId, serviceDate: today },
        },
        select: { id: true },
      }),
      this.candidateIds(key, today),
      this.prisma.subscription.findMany({
        where: { subscriberId: userId },
        select: { magazineId: true },
      }),
    ]);
    const cursorValue = cursor ? this.decodeCursor(cursor) : null;
    const raw = await this.prisma.issue.findMany({
      where: {
        serviceDate: { lte: today },
        ...(!ownIssue
          ? {
              OR: [
                { serviceDate: { lt: today } },
                { serviceDate: today, colorId: { notIn: candidateIds } },
              ],
            }
          : {}),
        ...(cursorValue
          ? {
              AND: [
                {
                  OR: [
                    { publishedAt: { lt: cursorValue.publishedAt } },
                    {
                      publishedAt: cursorValue.publishedAt,
                      id: { lt: cursorValue.id },
                    },
                  ],
                },
              ],
            }
          : {}),
      },
      orderBy: [{ publishedAt: 'desc' }, { id: 'desc' }],
      take: 21,
      select: { id: true, authorId: true, publishedAt: true },
    });
    const page = raw.slice(0, 20);
    const subscribed = new Set(
      subscriptions.map(({ magazineId }) => magazineId),
    );
    const items: FeedItemDto[] = [];
    for (const issue of page) {
      try {
        items.push(
          Object.assign(
            new FeedItemDto(),
            await this.issuesService.publicIssue(userId, issue.id),
            {
              source: subscribed.has(issue.authorId)
                ? ('SUBSCRIPTION' as const)
                : ('RECOMMENDED' as const),
            },
          ),
        );
      } catch (error) {
        if (error instanceof AppException && error.code === 'NOT_FOUND') {
          continue;
        }
        throw error;
      }
    }
    const last = page.at(-1);
    return {
      items,
      nextCursor:
        raw.length > 20 && last
          ? this.encodeCursor(last.publishedAt, last.id)
          : null,
    };
  }

  private async candidateIds(key: string, date: Date): Promise<string[]> {
    const palette = await this.prisma.dailyPalette.findUnique({
      where: { serviceDate: date },
      select: {
        colors: { orderBy: { position: 'asc' }, select: { colorId: true } },
      },
    });
    if (palette) return palette.colors.map(({ colorId }) => colorId);
    const colors = await this.prisma.color.findMany({
      orderBy: { sortOrder: 'asc' },
      select: { id: true },
    });
    return dailyCandidateIds(
      key,
      colors.map(({ id }) => id),
    );
  }

  private encodeCursor(publishedAt: Date, id: string): string {
    return Buffer.from(
      JSON.stringify({ publishedAt: publishedAt.toISOString(), id }),
    ).toString('base64url');
  }

  private decodeCursor(cursor: string): { publishedAt: Date; id: string } {
    try {
      const value = JSON.parse(
        Buffer.from(cursor, 'base64url').toString('utf8'),
      ) as { publishedAt?: unknown; id?: unknown };
      if (
        typeof value.publishedAt !== 'string' ||
        typeof value.id !== 'string' ||
        !UUID_PATTERN.test(value.id)
      ) {
        throw new Error('invalid cursor');
      }
      const publishedAt = new Date(value.publishedAt);
      if (Number.isNaN(publishedAt.getTime()))
        throw new Error('invalid cursor');
      return { publishedAt, id: value.id };
    } catch {
      throw new AppException('VALIDATION', {
        cursor: ['cursor가 올바르지 않아요.'],
      });
    }
  }
}

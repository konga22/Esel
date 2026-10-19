import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Prisma } from '../generated/prisma/client.js';
import { AppException } from '../common/app-exception.js';
import { serviceDate } from '../common/service-date.js';
import { IssuesService } from '../issues/issues.service.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { dailyCandidateIds } from '../today/today.rules.js';
import { PaletteColorsDto } from './dto/palette-color.dto.js';
import { PalettePageDto } from './dto/palette-page.dto.js';
import { StandDto } from './dto/stand.dto.js';

const UUID_PATTERN =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

@Injectable()
export class StandService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly issuesService: IssuesService,
    private readonly config: ConfigService,
  ) {}

  async get(
    userId: string,
    colorId: string,
    dateKey?: string,
    cursor?: string,
  ): Promise<StandDto> {
    const current = this.currentDate();
    const key = dateKey ?? current.key;
    const date = this.parseDate(key);
    const color = await this.prisma.color.findUnique({
      where: { id: colorId },
    });
    if (!color)
      throw new AppException('VALIDATION', { colorId: ['없는 색이에요.'] });
    if (key > current.key) {
      return {
        serviceDate: key,
        color: this.toColor(color),
        locked: false,
        closed: true,
        hiddenCount: 0,
        items: [],
        nextCursor: null,
      };
    }

    const [candidateIds, ownIssue, blocks] =
      key === current.key
        ? await Promise.all([
            this.candidateIds(key, date),
            this.prisma.issue.findUnique({
              where: {
                authorId_serviceDate: { authorId: userId, serviceDate: date },
              },
              select: { id: true, deletedAt: true },
            }),
            this.prisma.block.findMany({
              where: { blockerId: userId },
              select: { blockedId: true },
            }),
          ])
        : [
            [],
            null,
            await this.prisma.block.findMany({
              where: { blockerId: userId },
              select: { blockedId: true },
            }),
          ];
    const blockedIds = blocks.map(({ blockedId }) => blockedId);
    const locked = Boolean(
      key === current.key &&
      (!ownIssue || ownIssue.deletedAt) &&
      candidateIds.includes(colorId),
    );
    const cursorValue = cursor ? this.decodeCursor(cursor) : null;
    const total = await this.prisma.issue.count({
      where: {
        serviceDate: date,
        colorId,
        deletedAt: null,
        authorId: { notIn: blockedIds },
      },
    });
    const raw = await this.prisma.issue.findMany({
      where: {
        serviceDate: date,
        colorId,
        deletedAt: null,
        authorId: { notIn: blockedIds },
        ...(!locked && cursorValue
          ? {
              OR: [
                { publishedAt: { lt: cursorValue.publishedAt } },
                {
                  publishedAt: cursorValue.publishedAt,
                  id: { lt: cursorValue.id },
                },
              ],
            }
          : {}),
      },
      orderBy: [{ publishedAt: 'desc' }, { id: 'desc' }],
      take: locked ? 3 : 21,
      select: { id: true, publishedAt: true },
    });
    const page = locked ? raw : raw.slice(0, 20);
    const items = [];
    for (const { id } of page) {
      try {
        items.push(await this.issuesService.publicIssue(userId, id));
      } catch (error) {
        if (error instanceof AppException && error.code === 'NOT_FOUND') {
          continue;
        }
        throw error;
      }
    }
    const last = page.at(-1);
    return {
      serviceDate: key,
      color: this.toColor(color),
      locked,
      closed: false,
      hiddenCount: locked ? Math.max(0, total - page.length) : 0,
      items,
      nextCursor:
        !locked && raw.length > 20 && last
          ? this.encodeCursor(last.publishedAt, last.id)
          : null,
    };
  }

  async recommended(userId: string, cursor?: string): Promise<PalettePageDto> {
    const current = this.currentDate();
    const [candidateIds, ownIssue, choice, subscriptions, blocks] =
      await Promise.all([
        this.candidateIds(current.key, current.date),
        this.prisma.issue.findUnique({
          where: {
            authorId_serviceDate: {
              authorId: userId,
              serviceDate: current.date,
            },
          },
          select: { id: true, deletedAt: true },
        }),
        this.prisma.userDailyChoice.findUnique({
          where: {
            userId_serviceDate: { userId, serviceDate: current.date },
          },
          select: { colorId: true },
        }),
        this.prisma.subscription.findMany({
          where: { subscriberId: userId },
          select: { magazineId: true },
        }),
        this.prisma.block.findMany({
          where: { blockerId: userId },
          select: { blockedId: true },
        }),
      ]);
    const excludedAuthors = [
      userId,
      ...subscriptions.map(({ magazineId }) => magazineId),
      ...blocks.map(({ blockedId }) => blockedId),
    ];
    const cursorValue = cursor ? this.decodeCursor(cursor) : null;
    const rows = await this.latestIssueRows(
      Prisma.sql`
        i."deleted_at" IS NULL
        AND i."author_id" NOT IN (${this.uuidList(excludedAuthors)})
        AND i."service_date" <= ${current.date}
        ${choice ? Prisma.sql`AND i."color_id" = ${choice.colorId}` : Prisma.empty}
        ${
          !ownIssue || ownIssue.deletedAt
            ? Prisma.sql`AND (
                i."service_date" < ${current.date}
                OR (i."service_date" = ${current.date} AND i."color_id" NOT IN (${Prisma.join(candidateIds)}))
              )`
            : Prisma.empty
        }
      `,
      cursorValue,
    );
    return this.palettePage(rows);
  }

  async subscriptions(
    userId: string,
    cursor?: string,
  ): Promise<PalettePageDto> {
    const current = this.currentDate();
    const cursorValue = cursor ? this.decodeCursor(cursor) : null;
    const [candidateIds, ownIssue, subscriptions, blocks] = await Promise.all([
      this.candidateIds(current.key, current.date),
      this.prisma.issue.findUnique({
        where: {
          authorId_serviceDate: { authorId: userId, serviceDate: current.date },
        },
        select: { id: true, deletedAt: true },
      }),
      this.prisma.subscription.findMany({
        where: { subscriberId: userId },
        select: { magazineId: true },
      }),
      this.prisma.block.findMany({
        where: { blockerId: userId },
        select: { blockedId: true },
      }),
    ]);
    if (subscriptions.length === 0) return { items: [], nextCursor: null };

    const subscriberIds = subscriptions.map(({ magazineId }) => magazineId);
    const blockedIds = blocks.map(({ blockedId }) => blockedId);
    const rows = await this.latestIssueRows(
      Prisma.sql`
        i."deleted_at" IS NULL
        AND i."author_id" IN (${this.uuidList(subscriberIds)})
        ${blockedIds.length > 0 ? Prisma.sql`AND i."author_id" NOT IN (${this.uuidList(blockedIds)})` : Prisma.empty}
        AND i."service_date" <= ${current.date}
        ${
          !ownIssue || ownIssue.deletedAt
            ? Prisma.sql`AND (
                i."service_date" < ${current.date}
                OR (i."service_date" = ${current.date} AND i."color_id" NOT IN (${Prisma.join(candidateIds)}))
              )`
            : Prisma.empty
        }
      `,
      cursorValue,
    );
    return this.palettePage(rows);
  }

  async colors(userId: string): Promise<PaletteColorsDto> {
    const current = this.currentDate();
    const [colors, candidates, choice, issue, choiceCounts] = await Promise.all(
      [
        this.prisma.color.findMany({ orderBy: { sortOrder: 'asc' } }),
        this.candidateIds(current.key, current.date),
        this.prisma.userDailyChoice.findUnique({
          where: { userId_serviceDate: { userId, serviceDate: current.date } },
          select: { colorId: true },
        }),
        this.prisma.issue.findUnique({
          where: {
            authorId_serviceDate: {
              authorId: userId,
              serviceDate: current.date,
            },
          },
          select: { id: true, deletedAt: true },
        }),
        this.prisma.userDailyChoice.groupBy({
          by: ['colorId'],
          where: { serviceDate: current.date },
          _count: { colorId: true },
        }),
      ],
    );
    const countByColor = new Map(
      choiceCounts.map(({ colorId, _count }) => [colorId, _count.colorId]),
    );
    const candidatePosition = new Map(
      candidates.map((id, index) => [id, index]),
    );
    const ordered = [...colors].sort((left, right) => {
      if (!issue || issue.deletedAt) {
        const leftPosition = candidatePosition.get(left.id);
        const rightPosition = candidatePosition.get(right.id);
        if (leftPosition !== undefined || rightPosition !== undefined) {
          if (leftPosition === undefined) return 1;
          if (rightPosition === undefined) return -1;
          return leftPosition - rightPosition;
        }
      }
      return (
        (countByColor.get(right.id) ?? 0) - (countByColor.get(left.id) ?? 0) ||
        left.sortOrder - right.sortOrder
      );
    });
    return {
      serviceDate: current.key,
      items: ordered.map((color) => ({
        ...this.toColor(color),
        locked:
          (!issue || Boolean(issue.deletedAt)) &&
          candidatePosition.has(color.id),
        selected: choice?.colorId === color.id,
      })),
    };
  }

  private currentDate(): { key: string; date: Date } {
    const key = serviceDate(
      new Date(),
      this.config.getOrThrow<string>('SERVICE_TIME_ZONE'),
    );
    return { key, date: new Date(`${key}T00:00:00.000Z`) };
  }

  private async latestIssueRows(
    where: Prisma.Sql,
    cursor: { publishedAt: Date; id: string } | null,
  ): Promise<Array<{ id: string; publishedAt: Date }>> {
    return this.prisma.$queryRaw<Array<{ id: string; publishedAt: Date }>>(
      Prisma.sql`
        WITH ranked AS (
          SELECT
            i."id",
            i."published_at",
            ROW_NUMBER() OVER (
              PARTITION BY i."author_id"
              ORDER BY i."published_at" DESC, i."id" DESC
            ) AS author_rank
          FROM "issues" i
          INNER JOIN "profiles" p ON p."user_id" = i."author_id"
          WHERE ${where}
        )
        SELECT "id", "published_at" AS "publishedAt"
        FROM ranked
        WHERE author_rank = 1
          ${
            cursor
              ? Prisma.sql`AND (
                  "published_at" < ${cursor.publishedAt}
                  OR ("published_at" = ${cursor.publishedAt} AND "id" < ${cursor.id}::uuid)
                )`
              : Prisma.empty
          }
        ORDER BY "published_at" DESC, "id" DESC
        LIMIT 21
      `,
    );
  }

  private async palettePage(
    rows: Array<{ id: string; publishedAt: Date }>,
  ): Promise<PalettePageDto> {
    const page = rows.slice(0, 20);
    const issues = await this.prisma.issue.findMany({
      where: { id: { in: page.map(({ id }) => id) } },
      include: {
        author: { select: { profile: { select: { masthead: true } } } },
        color: true,
        media: {
          select: { id: true, mimeType: true, width: true, height: true },
        },
      },
    });
    const issueById = new Map(issues.map((issue) => [issue.id, issue]));
    const items = page.flatMap(({ id }) => {
      const issue = issueById.get(id);
      if (!issue?.author.profile) return [];
      return [
        {
          issueId: issue.id,
          masthead: issue.author.profile.masthead,
          serviceDate: this.dateKey(issue.serviceDate),
          color: this.toColor(issue.color),
          media: issue.media,
        },
      ];
    });
    const last = page.at(-1);
    return {
      items,
      nextCursor:
        rows.length > 20 && last
          ? this.encodeCursor(last.publishedAt, last.id)
          : null,
    };
  }

  private uuidList(ids: string[]): Prisma.Sql {
    return Prisma.join(ids.map((id) => Prisma.sql`${id}::uuid`));
  }

  private parseDate(key: string): Date {
    const date = new Date(`${key}T00:00:00.000Z`);
    if (Number.isNaN(date.getTime()) || this.dateKey(date) !== key) {
      throw new AppException('VALIDATION', {
        date: ['날짜가 올바르지 않아요.'],
      });
    }
    return date;
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

  private toColor(color: {
    id: string;
    nameKo: string;
    nameEn: string;
    hex: string;
  }) {
    return {
      id: color.id,
      nameKo: color.nameKo,
      nameEn: color.nameEn,
      hex: color.hex,
    };
  }

  private dateKey(date: Date): string {
    return date.toISOString().slice(0, 10);
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

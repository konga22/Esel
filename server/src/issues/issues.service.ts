import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Prisma } from '../generated/prisma/client.js';
import { AppException } from '../common/app-exception.js';
import { serviceDate } from '../common/service-date.js';
import { isWriteConflict } from '../prisma/is-write-conflict.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { dailyCandidateIds } from '../today/today.rules.js';
import { IssueOwnerDto } from './dto/issue-owner.dto.js';
import { IssuePublicDto } from './dto/issue-public.dto.js';
import { ReactionStateDto } from './dto/reaction-state.dto.js';
import { AddLineDto } from './dto/add-line.dto.js';
import { ReaderLinePageDto } from './dto/reader-line-page.dto.js';
import { ReaderLinePublicDto } from './dto/reader-line-public.dto.js';
import { ReaderLineRateLimiter } from './reader-line-rate-limiter.js';
import { PublishIssueDto } from './dto/publish-issue.dto.js';

const UUID_PATTERN =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

@Injectable()
export class IssuesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
    private readonly readerLineRateLimiter: ReaderLineRateLimiter,
  ) {}

  async publish(
    userId: string,
    input: PublishIssueDto,
  ): Promise<IssueOwnerDto> {
    this.validateGarmentPositions(input);
    const key = serviceDate(
      new Date(),
      this.config.getOrThrow<string>('SERVICE_TIME_ZONE'),
    );
    const date = new Date(`${key}T00:00:00.000Z`);

    for (let attempt = 0; attempt < 5; attempt += 1) {
      try {
        const issueId = await this.prisma.$transaction(
          async (tx) => {
            const [existing, profile, choice, media] = await Promise.all([
              tx.issue.findUnique({
                where: {
                  authorId_serviceDate: { authorId: userId, serviceDate: date },
                },
                select: { id: true },
              }),
              tx.profile.findUnique({
                where: { userId },
                select: { issueCount: true },
              }),
              tx.userDailyChoice.findUnique({
                where: {
                  userId_serviceDate: { userId, serviceDate: date },
                },
                select: { id: true, colorId: true },
              }),
              tx.mediaAsset.findUnique({
                where: { id: input.mediaId },
                select: {
                  id: true,
                  ownerId: true,
                  status: true,
                  issue: { select: { id: true } },
                  twinPost: { select: { twinId: true } },
                },
              }),
            ]);
            if (existing) throw new AppException('ISSUE_ALREADY_PUBLISHED');
            if (!profile || !choice) {
              throw new AppException('VALIDATION', {
                colorId: ['오늘의 색을 먼저 골라 주세요.'],
              });
            }
            if (
              !media ||
              media.ownerId !== userId ||
              media.status !== 'READY' ||
              media.issue ||
              media.twinPost
            ) {
              throw new AppException('MEDIA_NOT_READY');
            }

            const garmentLinks = [];
            for (const [position, item] of (input.garments ?? []).entries()) {
              const garment = item.garmentId
                ? await tx.garment.findUnique({
                    where: { id: item.garmentId },
                    select: { id: true, ownerId: true },
                  })
                : await tx.garment.create({
                    data: {
                      ownerId: userId,
                      kind: item.kind,
                      name: item.name ?? '',
                      note: item.note ?? '',
                    },
                    select: { id: true, ownerId: true },
                  });
              if (!garment || garment.ownerId !== userId) {
                throw new AppException('VALIDATION', {
                  garmentId: ['내 옷만 다시 고를 수 있어요.'],
                });
              }
              garmentLinks.push({
                garmentId: garment.id,
                position: position + 1,
                todayColor: item.todayColor ?? false,
                x: item.x,
                y: item.y,
              });
            }

            const updatedProfile = await tx.profile.update({
              where: { userId },
              data: { issueCount: { increment: 1 } },
              select: { issueCount: true },
            });
            const issue = await tx.issue.create({
              data: {
                authorId: userId,
                serviceDate: date,
                issueNumber: updatedProfile.issueCount,
                colorId: choice.colorId,
                mediaId: media.id,
                caption: input.caption,
                faceMode: input.faceMode,
                garments: { create: garmentLinks },
              },
              select: { id: true },
            });
            await tx.userDailyChoice.update({
              where: { id: choice.id },
              data: { lockedAt: new Date() },
            });
            return issue.id;
          },
          { isolationLevel: Prisma.TransactionIsolationLevel.Serializable },
        );
        return (await this.get(userId, issueId)) as IssueOwnerDto;
      } catch (error) {
        if (isWriteConflict(error) && attempt < 4) continue;
        if (
          isWriteConflict(error) ||
          (error instanceof Prisma.PrismaClientKnownRequestError &&
            error.code === 'P2002')
        ) {
          throw new AppException('ISSUE_ALREADY_PUBLISHED');
        }
        throw error;
      }
    }
    throw new AppException('ISSUE_ALREADY_PUBLISHED');
  }

  async get(
    userId: string,
    issueId: string,
  ): Promise<IssuePublicDto | IssueOwnerDto> {
    const visible = await this.assertVisible(userId, issueId);
    const issue = await this.prisma.issue.findUnique({
      where: { id: visible.id },
      include: {
        author: { select: { profile: { select: { masthead: true } } } },
        color: true,
        media: {
          select: {
            id: true,
            mimeType: true,
            width: true,
            height: true,
          },
        },
        likes: { where: { userId }, select: { userId: true } },
        scraps: { where: { userId }, select: { userId: true } },
        garments: {
          include: { garment: true },
          orderBy: { position: 'asc' },
        },
        _count: { select: { likes: true, scraps: true, readerLines: true } },
      },
    });
    if (!issue?.author.profile) throw new AppException('NOT_FOUND');

    const result: IssuePublicDto = {
      id: issue.id,
      masthead: issue.author.profile.masthead,
      issueNumber: issue.issueNumber,
      serviceDate: this.dateKey(issue.serviceDate),
      publishedAt: issue.publishedAt.toISOString(),
      color: {
        id: issue.color.id,
        nameKo: issue.color.nameKo,
        nameEn: issue.color.nameEn,
        hex: issue.color.hex,
      },
      media: issue.media,
      caption: issue.caption,
      faceMode: issue.faceMode,
      garments: issue.garments.map(({ garment, todayColor, x, y }) => ({
        garmentId: garment.id,
        kind: garment.kind,
        name: garment.name,
        note: garment.note,
        todayColor,
        x,
        y,
      })),
      liked: issue.likes.length > 0,
      scrapped: issue.scraps.length > 0,
    };
    if (issue.authorId !== userId) return result;
    return {
      id: result.id,
      masthead: result.masthead,
      issueNumber: result.issueNumber,
      serviceDate: result.serviceDate,
      publishedAt: result.publishedAt,
      color: result.color,
      media: result.media,
      caption: result.caption,
      faceMode: result.faceMode,
      garments: result.garments,
      liked: result.liked,
      scrapped: result.scrapped,
      likeCount: issue._count.likes,
      scrapCount: issue._count.scraps,
      lineCount: issue._count.readerLines,
    };
  }

  async like(userId: string, issueId: string): Promise<ReactionStateDto> {
    await this.assertVisible(userId, issueId);
    await this.prisma.like.upsert({
      where: { userId_issueId: { userId, issueId } },
      create: { userId, issueId },
      update: {},
    });
    return this.reactionState(userId, issueId);
  }

  async unlike(userId: string, issueId: string): Promise<ReactionStateDto> {
    await this.assertVisible(userId, issueId);
    await this.prisma.like.deleteMany({ where: { userId, issueId } });
    return this.reactionState(userId, issueId);
  }

  async scrap(userId: string, issueId: string): Promise<ReactionStateDto> {
    await this.assertVisible(userId, issueId);
    await this.prisma.scrap.upsert({
      where: { userId_issueId: { userId, issueId } },
      create: { userId, issueId },
      update: {},
    });
    return this.reactionState(userId, issueId);
  }

  async unscrap(userId: string, issueId: string): Promise<ReactionStateDto> {
    await this.assertVisible(userId, issueId);
    await this.prisma.scrap.deleteMany({ where: { userId, issueId } });
    return this.reactionState(userId, issueId);
  }

  async publicIssue(userId: string, issueId: string): Promise<IssuePublicDto> {
    const issue = await this.get(userId, issueId);
    return {
      id: issue.id,
      masthead: issue.masthead,
      issueNumber: issue.issueNumber,
      serviceDate: issue.serviceDate,
      publishedAt: issue.publishedAt,
      color: issue.color,
      media: issue.media,
      caption: issue.caption,
      faceMode: issue.faceMode,
      garments: issue.garments,
      liked: issue.liked,
      scrapped: issue.scrapped,
    };
  }

  async lines(
    userId: string,
    issueId: string,
    cursor?: string,
  ): Promise<ReaderLinePageDto> {
    await this.assertVisible(userId, issueId);
    const cursorValue = cursor ? this.decodeLineCursor(cursor) : null;
    const blocked = await this.prisma.block.findMany({
      where: { blockerId: userId },
      select: { blockedId: true },
    });
    const lines = await this.prisma.readerLine.findMany({
      where: {
        issueId,
        authorId: { notIn: blocked.map(({ blockedId }) => blockedId) },
        ...(cursorValue
          ? {
              OR: [
                { createdAt: { lt: cursorValue.createdAt } },
                {
                  createdAt: cursorValue.createdAt,
                  id: { lt: cursorValue.id },
                },
              ],
            }
          : {}),
      },
      include: {
        author: { select: { profile: { select: { masthead: true } } } },
      },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take: 21,
    });
    const page = lines.slice(0, 20);
    return {
      items: page
        .filter(({ author }) => Boolean(author.profile))
        .map((line) => this.toReaderLineDto(line)),
      nextCursor:
        lines.length > 20 && page.at(-1)
          ? this.encodeLineCursor(page.at(-1)!)
          : null,
    };
  }

  async addLine(
    userId: string,
    issueId: string,
    input: AddLineDto,
  ): Promise<ReaderLinePublicDto> {
    await this.assertVisible(userId, issueId);
    this.readerLineRateLimiter.consume(`${userId}:${issueId}`);
    const profile = await this.prisma.profile.findUnique({
      where: { userId },
      select: { masthead: true },
    });
    if (!profile) throw new AppException('NOT_FOUND');
    const line = await this.prisma.readerLine.create({
      data: { authorId: userId, issueId, text: input.text },
    });
    return {
      id: line.id,
      authorMasthead: profile.masthead,
      text: line.text,
      createdAt: line.createdAt.toISOString(),
    };
  }

  private async reactionState(
    userId: string,
    issueId: string,
  ): Promise<ReactionStateDto> {
    const [like, scrap] = await Promise.all([
      this.prisma.like.findUnique({
        where: { userId_issueId: { userId, issueId } },
        select: { userId: true },
      }),
      this.prisma.scrap.findUnique({
        where: { userId_issueId: { userId, issueId } },
        select: { userId: true },
      }),
    ]);
    return { liked: Boolean(like), scrapped: Boolean(scrap) };
  }

  private validateGarmentPositions(input: PublishIssueDto): void {
    const ids = new Set<string>();
    for (const garment of input.garments ?? []) {
      if ((garment.x === undefined) !== (garment.y === undefined)) {
        throw new AppException('VALIDATION', {
          garments: ['사진 위 위치는 x와 y를 함께 보내 주세요.'],
        });
      }
      if (garment.garmentId) {
        if (ids.has(garment.garmentId)) {
          throw new AppException('VALIDATION', {
            garments: ['같은 옷은 한 호에 한 번만 넣을 수 있어요.'],
          });
        }
        ids.add(garment.garmentId);
      }
    }
  }

  async assertVisible(userId: string, issueId: string) {
    if (!UUID_PATTERN.test(issueId)) throw new AppException('NOT_FOUND');
    const issue = await this.prisma.issue.findUnique({
      where: { id: issueId },
      select: {
        id: true,
        authorId: true,
        serviceDate: true,
        colorId: true,
        deletedAt: true,
      },
    });
    if (!issue || issue.deletedAt) throw new AppException('NOT_FOUND');
    if (issue.authorId === userId) return issue;

    const block = await this.prisma.block.findUnique({
      where: {
        blockerId_blockedId: { blockerId: userId, blockedId: issue.authorId },
      },
      select: { id: true },
    });
    if (block) throw new AppException('NOT_FOUND');

    const todayKey = serviceDate(
      new Date(),
      this.config.getOrThrow<string>('SERVICE_TIME_ZONE'),
    );
    const issueDateKey = this.dateKey(issue.serviceDate);
    if (issueDateKey < todayKey) return issue;
    if (issueDateKey > todayKey) throw new AppException('NOT_FOUND');

    const today = new Date(`${todayKey}T00:00:00.000Z`);
    const ownIssue = await this.prisma.issue.findUnique({
      where: { authorId_serviceDate: { authorId: userId, serviceDate: today } },
      select: { id: true, deletedAt: true },
    });
    if (ownIssue && !ownIssue.deletedAt) return issue;

    const candidateIds = await this.candidateIds(todayKey, today);
    if (!candidateIds.includes(issue.colorId)) return issue;

    const preview = await this.prisma.issue.findMany({
      where: { serviceDate: today, colorId: issue.colorId, deletedAt: null },
      orderBy: [{ publishedAt: 'desc' }, { id: 'desc' }],
      take: 3,
      select: { id: true },
    });
    if (preview.some(({ id }) => id === issue.id)) return issue;
    throw new AppException('NOT_FOUND');
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

  private dateKey(date: Date): string {
    return date.toISOString().slice(0, 10);
  }

  private toReaderLineDto(line: {
    id: string;
    text: string;
    createdAt: Date;
    author: { profile: { masthead: string } | null };
  }): ReaderLinePublicDto {
    return {
      id: line.id,
      authorMasthead: line.author.profile?.masthead ?? '',
      text: line.text,
      createdAt: line.createdAt.toISOString(),
    };
  }

  private encodeLineCursor(line: { id: string; createdAt: Date }): string {
    return Buffer.from(
      JSON.stringify({ id: line.id, createdAt: line.createdAt.toISOString() }),
    ).toString('base64url');
  }

  private decodeLineCursor(cursor: string): { id: string; createdAt: Date } {
    try {
      const value = JSON.parse(
        Buffer.from(cursor, 'base64url').toString('utf8'),
      ) as { id?: unknown; createdAt?: unknown };
      if (
        typeof value.id !== 'string' ||
        !UUID_PATTERN.test(value.id) ||
        typeof value.createdAt !== 'string'
      ) {
        throw new Error('invalid cursor');
      }
      const createdAt = new Date(value.createdAt);
      if (Number.isNaN(createdAt.getTime())) throw new Error('invalid cursor');
      return { id: value.id, createdAt };
    } catch {
      throw new AppException('NOT_FOUND');
    }
  }
}

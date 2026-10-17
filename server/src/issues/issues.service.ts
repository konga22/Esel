import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AppException } from '../common/app-exception.js';
import { serviceDate } from '../common/service-date.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { dailyCandidateIds } from '../today/today.rules.js';
import { IssueOwnerDto } from './dto/issue-owner.dto.js';
import { IssuePublicDto } from './dto/issue-public.dto.js';
import { ReactionStateDto } from './dto/reaction-state.dto.js';
import { AddLineDto } from './dto/add-line.dto.js';
import { ReaderLinePageDto } from './dto/reader-line-page.dto.js';
import { ReaderLinePublicDto } from './dto/reader-line-public.dto.js';
import { ReaderLineRateLimiter } from './reader-line-rate-limiter.js';

const UUID_PATTERN =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

@Injectable()
export class IssuesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
    private readonly readerLineRateLimiter: ReaderLineRateLimiter,
  ) {}

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
    const lines = await this.prisma.readerLine.findMany({
      where: {
        issueId,
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

  async assertVisible(userId: string, issueId: string) {
    if (!UUID_PATTERN.test(issueId)) throw new AppException('NOT_FOUND');
    const issue = await this.prisma.issue.findUnique({
      where: { id: issueId },
      select: {
        id: true,
        authorId: true,
        serviceDate: true,
        colorId: true,
      },
    });
    if (!issue) throw new AppException('NOT_FOUND');
    if (issue.authorId === userId) return issue;

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
      select: { id: true },
    });
    if (ownIssue) return issue;

    const candidateIds = await this.candidateIds(todayKey, today);
    if (!candidateIds.includes(issue.colorId)) return issue;

    const preview = await this.prisma.issue.findMany({
      where: { serviceDate: today, colorId: issue.colorId },
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

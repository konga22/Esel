import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AppException } from '../common/app-exception.js';
import { serviceDate } from '../common/service-date.js';
import { IssueOwnerDto } from '../issues/dto/issue-owner.dto.js';
import { IssuesService } from '../issues/issues.service.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { IssueReactionsOwnerDto } from './dto/issue-reactions-owner.dto.js';
import { MagazineOwnerDto } from './dto/magazine-owner.dto.js';

@Injectable()
export class MeService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly issuesService: IssuesService,
    private readonly config: ConfigService,
  ) {}

  async magazine(userId: string, cursor?: string): Promise<MagazineOwnerDto> {
    const profile = await this.prisma.profile.findUnique({
      where: { userId },
      select: { masthead: true, issueCount: true },
    });
    const beforeIssueNumber = cursor ? this.decodeCursor(cursor) : null;
    const todayKey = serviceDate(
      new Date(),
      this.config.getOrThrow<string>('SERVICE_TIME_ZONE'),
    );
    const today = new Date(`${todayKey}T00:00:00.000Z`);
    const [todayRaw, rawPastIssues] = await Promise.all([
      this.prisma.issue.findUnique({
        where: {
          authorId_serviceDate: { authorId: userId, serviceDate: today },
        },
        select: { id: true, deletedAt: true },
      }),
      this.prisma.issue.findMany({
        where: {
          authorId: userId,
          serviceDate: { lt: today },
          deletedAt: null,
          ...(beforeIssueNumber
            ? { issueNumber: { lt: beforeIssueNumber } }
            : {}),
        },
        orderBy: [{ issueNumber: 'desc' }, { id: 'desc' }],
        take: 21,
        select: { id: true, issueNumber: true },
      }),
    ]);
    const pastRaw = rawPastIssues.slice(0, 20);
    const todayIssue =
      todayRaw && !todayRaw.deletedAt
        ? ((await this.issuesService.get(userId, todayRaw.id)) as IssueOwnerDto)
        : null;
    const pastIssues = (await Promise.all(
      pastRaw.map(({ id }) => this.issuesService.get(userId, id)),
    )) as IssueOwnerDto[];
    const last = pastRaw.at(-1);
    return {
      masthead: profile?.masthead ?? null,
      issueCount: profile?.issueCount ?? 0,
      todayIssue,
      pastIssues,
      nextCursor:
        rawPastIssues.length > 20 && last
          ? this.encodeCursor(last.issueNumber)
          : null,
    };
  }

  async reactions(
    userId: string,
    issueId: string,
  ): Promise<IssueReactionsOwnerDto> {
    const visible = await this.issuesService.assertVisible(userId, issueId);
    if (visible.authorId !== userId) throw new AppException('FORBIDDEN');
    const issue = await this.prisma.issue.findUniqueOrThrow({
      where: { id: issueId },
      include: {
        likes: {
          include: { user: { select: { profile: true } } },
          orderBy: { createdAt: 'desc' },
          take: 50,
        },
        scraps: {
          include: { user: { select: { profile: true } } },
          orderBy: { createdAt: 'desc' },
          take: 50,
        },
        readerLines: {
          include: { author: { select: { profile: true } } },
          orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
          take: 50,
        },
        _count: { select: { likes: true, scraps: true, readerLines: true } },
      },
    });
    return {
      issueId,
      likeCount: issue._count.likes,
      scrapCount: issue._count.scraps,
      lineCount: issue._count.readerLines,
      likes: issue.likes
        .filter(({ user }) => Boolean(user.profile))
        .map(({ user, createdAt }) => ({
          masthead: user.profile!.masthead,
          createdAt: createdAt.toISOString(),
        })),
      scraps: issue.scraps
        .filter(({ user }) => Boolean(user.profile))
        .map(({ user, createdAt }) => ({
          masthead: user.profile!.masthead,
          createdAt: createdAt.toISOString(),
        })),
      lines: issue.readerLines
        .filter(({ author }) => Boolean(author.profile))
        .map(({ id, author, text, createdAt }) => ({
          id,
          authorMasthead: author.profile!.masthead,
          text,
          createdAt: createdAt.toISOString(),
        })),
    };
  }

  private encodeCursor(issueNumber: number): string {
    return Buffer.from(JSON.stringify({ before: issueNumber })).toString(
      'base64url',
    );
  }

  private decodeCursor(cursor: string): number {
    try {
      const value = JSON.parse(
        Buffer.from(cursor, 'base64url').toString('utf8'),
      ) as { before?: unknown };
      if (
        typeof value.before !== 'number' ||
        !Number.isInteger(value.before) ||
        value.before < 1
      ) {
        throw new Error('invalid cursor');
      }
      return value.before;
    } catch {
      throw new AppException('NOT_FOUND');
    }
  }
}

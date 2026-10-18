import { Injectable } from '@nestjs/common';
import { AppException } from '../common/app-exception.js';
import { IssuesService } from '../issues/issues.service.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { MagazinePublicDto } from './dto/magazine-public.dto.js';
import { SubscriptionStateDto } from './dto/subscription-state.dto.js';

@Injectable()
export class MagazinesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly issuesService: IssuesService,
  ) {}

  async get(
    userId: string,
    masthead: string,
    cursor?: string,
  ): Promise<MagazinePublicDto> {
    const profile = await this.prisma.profile.findUnique({
      where: { masthead },
      select: { userId: true, masthead: true, issueCount: true },
    });
    if (!profile) throw new AppException('NOT_FOUND');

    const beforeIssueNumber = cursor ? this.decodeCursor(cursor) : null;

    const [subscription, rawIssues, block] = await Promise.all([
      this.prisma.subscription.findUnique({
        where: {
          subscriberId_magazineId: {
            subscriberId: userId,
            magazineId: profile.userId,
          },
        },
        select: { subscriberId: true },
      }),
      this.prisma.issue.findMany({
        where: {
          authorId: profile.userId,
          deletedAt: null,
          ...(beforeIssueNumber
            ? { issueNumber: { lt: beforeIssueNumber } }
            : {}),
        },
        orderBy: [{ issueNumber: 'desc' }, { id: 'desc' }],
        take: 21,
        select: { id: true, issueNumber: true },
      }),
      this.prisma.block.findUnique({
        where: {
          blockerId_blockedId: {
            blockerId: userId,
            blockedId: profile.userId,
          },
        },
        select: { id: true },
      }),
    ]);

    if (block) {
      return {
        masthead: profile.masthead,
        issueCount: profile.issueCount,
        isSubscribed: Boolean(subscription),
        issues: [],
        nextCursor: null,
      };
    }

    const page = rawIssues.slice(0, 20);
    const issues = [];
    for (const issue of page) {
      try {
        issues.push(await this.issuesService.publicIssue(userId, issue.id));
      } catch (error) {
        if (error instanceof AppException && error.code === 'NOT_FOUND') {
          continue;
        }
        throw error;
      }
    }
    return {
      masthead: profile.masthead,
      issueCount: profile.issueCount,
      isSubscribed: Boolean(subscription),
      issues,
      nextCursor:
        rawIssues.length > 20 && page.at(-1)
          ? this.encodeCursor(page.at(-1)!.issueNumber)
          : null,
    };
  }

  async subscribe(
    userId: string,
    masthead: string,
  ): Promise<SubscriptionStateDto> {
    const magazineId = await this.magazineId(masthead, userId);
    await this.prisma.subscription.upsert({
      where: {
        subscriberId_magazineId: { subscriberId: userId, magazineId },
      },
      create: { subscriberId: userId, magazineId },
      update: {},
    });
    return { subscribed: true };
  }

  async unsubscribe(
    userId: string,
    masthead: string,
  ): Promise<SubscriptionStateDto> {
    const magazineId = await this.magazineId(masthead, userId);
    await this.prisma.subscription.deleteMany({
      where: { subscriberId: userId, magazineId },
    });
    return { subscribed: false };
  }

  private async magazineId(masthead: string, userId: string): Promise<string> {
    const profile = await this.prisma.profile.findUnique({
      where: { masthead },
      select: { userId: true },
    });
    if (!profile || profile.userId === userId) {
      throw new AppException('NOT_FOUND');
    }
    return profile.userId;
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

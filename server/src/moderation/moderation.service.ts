import { Injectable, Logger } from '@nestjs/common';
import { AppException } from '../common/app-exception.js';
import { IssuesService } from '../issues/issues.service.js';
import { MediaService } from '../media/media.service.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { BlockStateDto } from './dto/block-state.dto.js';
import { BlockedUserPageDto } from './dto/blocked-user-page.dto.js';
import { CreateReportDto } from './dto/create-report.dto.js';
import { ReportReceiptDto } from './dto/report-receipt.dto.js';
import { ReportRateLimiter } from './report-rate-limiter.js';

const UUID_PATTERN =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

@Injectable()
export class ModerationService {
  private readonly logger = new Logger(ModerationService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly issuesService: IssuesService,
    private readonly mediaService: MediaService,
    private readonly reportRateLimiter: ReportRateLimiter,
  ) {}

  async block(userId: string, masthead: string): Promise<BlockStateDto> {
    const blockedId = await this.userId(masthead, userId);
    await this.prisma.block.upsert({
      where: { blockerId_blockedId: { blockerId: userId, blockedId } },
      create: { blockerId: userId, blockedId },
      update: {},
    });
    return { masthead, blocked: true };
  }

  async unblock(userId: string, masthead: string): Promise<BlockStateDto> {
    const blockedId = await this.userId(masthead, userId);
    await this.prisma.block.deleteMany({
      where: { blockerId: userId, blockedId },
    });
    return { masthead, blocked: false };
  }

  async blocks(userId: string, cursor?: string): Promise<BlockedUserPageDto> {
    const value = cursor ? this.decodeBlockCursor(cursor) : null;
    const blocks = await this.prisma.block.findMany({
      where: {
        blockerId: userId,
        ...(value
          ? {
              OR: [
                { createdAt: { lt: value.createdAt } },
                { createdAt: value.createdAt, id: { lt: value.id } },
              ],
            }
          : {}),
      },
      include: { blocked: { select: { profile: true } } },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take: 21,
    });
    const page = blocks.slice(0, 20);
    const last = page.at(-1);
    return {
      items: page
        .filter(({ blocked }) => Boolean(blocked.profile))
        .map(({ blocked, createdAt }) => ({
          masthead: blocked.profile!.masthead,
          blockedAt: createdAt.toISOString(),
        })),
      nextCursor:
        blocks.length > 20 && last
          ? this.encodeBlockCursor(last.createdAt, last.id)
          : null,
    };
  }

  async deleteIssue(userId: string, issueId: string): Promise<void> {
    const visible = await this.issuesService.assertVisible(userId, issueId);
    if (visible.authorId !== userId) throw new AppException('FORBIDDEN');
    const issue = await this.prisma.issue.findUnique({
      where: { id: issueId },
      select: { media: { select: { id: true, storageKey: true } } },
    });
    if (!issue) throw new AppException('NOT_FOUND');

    const deleted = await this.prisma.$transaction(async (tx) => {
      const result = await tx.issue.updateMany({
        where: { id: issueId, authorId: userId, deletedAt: null },
        data: { deletedAt: new Date() },
      });
      if (result.count !== 1) return false;
      await tx.mediaAsset.update({
        where: { id: issue.media.id },
        data: { status: 'DELETED' },
      });
      return true;
    });
    if (!deleted) throw new AppException('NOT_FOUND');
    try {
      await this.mediaService.removeStoredFiles(
        issue.media.storageKey,
        issue.media.id,
      );
    } catch (error) {
      this.logger.warn(
        `삭제된 미디어 파일 정리에 실패했어요: ${issue.media.id}`,
        error,
      );
    }
  }

  async reportIssue(
    userId: string,
    issueId: string,
    input: CreateReportDto,
  ): Promise<ReportReceiptDto> {
    const issue = await this.issuesService.assertVisible(userId, issueId);
    this.reportRateLimiter.consume(userId);
    const report = await this.prisma.report.create({
      data: {
        reporterId: userId,
        issueId: issue.id,
        reason: input.reason,
        details: input.details ?? '',
      },
    });
    return this.receipt(report);
  }

  async reportLine(
    userId: string,
    issueId: string,
    lineId: string,
    input: CreateReportDto,
  ): Promise<ReportReceiptDto> {
    const issue = await this.issuesService.assertVisible(userId, issueId);
    const line = await this.prisma.readerLine.findFirst({
      where: { id: lineId, issueId: issue.id },
      select: { id: true, authorId: true },
    });
    if (!line) throw new AppException('NOT_FOUND');
    const block = await this.prisma.block.findUnique({
      where: {
        blockerId_blockedId: {
          blockerId: userId,
          blockedId: line.authorId,
        },
      },
      select: { id: true },
    });
    if (block) throw new AppException('NOT_FOUND');
    this.reportRateLimiter.consume(userId);
    const report = await this.prisma.report.create({
      data: {
        reporterId: userId,
        issueId: issue.id,
        lineId: line.id,
        reason: input.reason,
        details: input.details ?? '',
      },
    });
    return this.receipt(report);
  }

  private async userId(masthead: string, ownId: string): Promise<string> {
    const profile = await this.prisma.profile.findUnique({
      where: { masthead },
      select: { userId: true },
    });
    if (!profile || profile.userId === ownId) {
      throw new AppException('NOT_FOUND');
    }
    return profile.userId;
  }

  private receipt(report: { id: string; createdAt: Date }): ReportReceiptDto {
    return {
      id: report.id,
      status: 'RECEIVED',
      createdAt: report.createdAt.toISOString(),
    };
  }

  private encodeBlockCursor(createdAt: Date, id: string): string {
    return Buffer.from(
      JSON.stringify({ createdAt: createdAt.toISOString(), id }),
    ).toString('base64url');
  }

  private decodeBlockCursor(cursor: string): { createdAt: Date; id: string } {
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
      throw new AppException('NOT_FOUND');
    }
  }
}

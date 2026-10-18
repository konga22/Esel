import { Injectable } from '@nestjs/common';
import { AppException } from '../common/app-exception.js';
import { IssuesService } from '../issues/issues.service.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { CreateReportDto } from './dto/create-report.dto.js';
import { ReportReceiptDto } from './dto/report-receipt.dto.js';
import { ReportRateLimiter } from './report-rate-limiter.js';

@Injectable()
export class ModerationService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly issuesService: IssuesService,
    private readonly reportRateLimiter: ReportRateLimiter,
  ) {}

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
      select: { id: true },
    });
    if (!line) throw new AppException('NOT_FOUND');
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

  private receipt(report: { id: string; createdAt: Date }): ReportReceiptDto {
    return {
      id: report.id,
      status: 'RECEIVED',
      createdAt: report.createdAt.toISOString(),
    };
  }
}

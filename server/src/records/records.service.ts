import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Prisma } from '../generated/prisma/client.js';
import { AppException } from '../common/app-exception.js';
import { serviceDate } from '../common/service-date.js';
import { isWriteConflict } from '../prisma/is-write-conflict.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { dailyCandidateIds } from '../today/today.rules.js';
import { DayRecordDto } from './dto/day-record.dto.js';
import { MonthRecordDto } from './dto/month-record.dto.js';
import { RestoreColorDto } from './dto/restore-color.dto.js';

@Injectable()
export class RecordsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
  ) {}

  async month(userId: string, month: string): Promise<MonthRecordDto> {
    const { start, end } = this.monthRange(month);
    const [issues, restored] = await Promise.all([
      this.prisma.issue.findMany({
        where: { authorId: userId, serviceDate: { gte: start, lt: end } },
        include: { color: true, media: true },
      }),
      this.prisma.restoredColor.findMany({
        where: { userId, serviceDate: { gte: start, lt: end } },
        include: { color: true },
      }),
    ]);
    const days: DayRecordDto[] = [
      ...issues.map((issue) => ({
        serviceDate: this.dateKey(issue.serviceDate),
        kind: 'ISSUE' as const,
        color: this.toColor(issue.color),
        issueId: issue.id,
        media: {
          id: issue.media.id,
          mimeType: issue.media.mimeType,
          width: issue.media.width,
          height: issue.media.height,
        },
      })),
      ...restored.map((record) => ({
        serviceDate: this.dateKey(record.serviceDate),
        kind: 'RESTORED' as const,
        color: this.toColor(record.color),
        issueId: null,
        media: null,
      })),
    ].sort((left, right) => left.serviceDate.localeCompare(right.serviceDate));
    return {
      month,
      remainingRestores: Math.max(0, 2 - restored.length),
      days,
    };
  }

  async restore(
    userId: string,
    dateKey: string,
    input: RestoreColorDto,
  ): Promise<DayRecordDto> {
    const date = this.validDate(dateKey);
    const todayKey = serviceDate(
      new Date(),
      this.config.getOrThrow<string>('SERVICE_TIME_ZONE'),
    );
    if (dateKey.slice(0, 7) !== todayKey.slice(0, 7) || dateKey >= todayKey) {
      throw new AppException('RESTORE_NOT_ALLOWED');
    }
    const candidates = await this.candidateIds(dateKey, date);
    if (!candidates.includes(input.colorId)) {
      throw new AppException('COLOR_NOT_CANDIDATE');
    }
    const { start, end } = this.monthRange(dateKey.slice(0, 7));

    const maxAttempts = 5;
    for (let attempt = 0; attempt < maxAttempts; attempt += 1) {
      try {
        const record = await this.prisma.$transaction(
          async (tx) => {
            const issue = await tx.issue.findUnique({
              where: {
                authorId_serviceDate: { authorId: userId, serviceDate: date },
              },
              select: { id: true },
            });
            const existing = await tx.restoredColor.findUnique({
              where: { userId_serviceDate: { userId, serviceDate: date } },
              select: { id: true },
            });
            if (issue || existing)
              throw new AppException('RESTORE_NOT_ALLOWED');
            const used = await tx.restoredColor.count({
              where: { userId, serviceDate: { gte: start, lt: end } },
            });
            if (used >= 2) throw new AppException('RESTORE_LIMIT');
            return tx.restoredColor.create({
              data: { userId, serviceDate: date, colorId: input.colorId },
              include: { color: true },
            });
          },
          { isolationLevel: Prisma.TransactionIsolationLevel.Serializable },
        );
        return {
          serviceDate: dateKey,
          kind: 'RESTORED',
          color: this.toColor(record.color),
          issueId: null,
          media: null,
        };
      } catch (error) {
        if (isWriteConflict(error)) {
          if (attempt < maxAttempts - 1) continue;
          throw new AppException('RESTORE_LIMIT');
        }
        if (
          error instanceof Prisma.PrismaClientKnownRequestError &&
          error.code === 'P2002'
        ) {
          throw new AppException('RESTORE_NOT_ALLOWED');
        }
        throw error;
      }
    }
    throw new AppException('RESTORE_LIMIT');
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

  private validDate(key: string): Date {
    const date = new Date(`${key}T00:00:00.000Z`);
    if (Number.isNaN(date.getTime()) || this.dateKey(date) !== key) {
      throw new AppException('RESTORE_NOT_ALLOWED');
    }
    return date;
  }

  private monthRange(month: string): { start: Date; end: Date } {
    const [year, monthNumber] = month.split('-').map(Number);
    const start = new Date(Date.UTC(year!, monthNumber! - 1, 1));
    const end = new Date(Date.UTC(year!, monthNumber!, 1));
    return { start, end };
  }

  private dateKey(date: Date): string {
    return date.toISOString().slice(0, 10);
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
}

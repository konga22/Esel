import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Prisma } from '../generated/prisma/client.js';
import { AppException } from '../common/app-exception.js';
import { serviceDate } from '../common/service-date.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { ChooseColorDto } from './dto/choose-color.dto.js';
import { ColorDto } from './dto/color.dto.js';
import { TodayDto } from './dto/today.dto.js';
import {
  TodayCoverIssueDto,
  TodayCoverPublicDto,
} from './dto/today-cover-public.dto.js';
import { dailyCandidateIds } from './today.rules.js';

const paletteInclude = {
  colors: { include: { color: true }, orderBy: { position: 'asc' as const } },
};

type PaletteWithColors = Prisma.DailyPaletteGetPayload<{
  include: typeof paletteInclude;
}>;

@Injectable()
export class TodayService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
  ) {}

  async get(userId: string): Promise<TodayDto> {
    const { key, date } = this.currentServiceDate();
    const palette = await this.prisma.dailyPalette.findUnique({
      where: { serviceDate: date },
      include: paletteInclude,
    });
    const candidates = palette
      ? this.paletteCandidates(palette)
      : await this.generatedCandidates(key);
    return this.toDto(userId, key, date, candidates);
  }

  async cover(): Promise<TodayCoverPublicDto> {
    const { key, date } = this.currentServiceDate();
    const issues = await this.prisma.issue.findMany({
      where: { serviceDate: date, deletedAt: null },
      include: {
        author: { select: { profile: { select: { masthead: true } } } },
        color: true,
        media: {
          select: { id: true, mimeType: true, width: true, height: true },
        },
        garments: {
          include: { garment: true },
          orderBy: { position: 'asc' },
        },
      },
      orderBy: [{ publishedAt: 'desc' }, { id: 'desc' }],
    });
    const perColor = new Map<string, number>();
    const visible: TodayCoverIssueDto[] = [];
    for (const issue of issues) {
      const seen = perColor.get(issue.colorId) ?? 0;
      if (seen >= 3 || !issue.author.profile) continue;
      perColor.set(issue.colorId, seen + 1);
      visible.push({
        id: issue.id,
        masthead: issue.author.profile.masthead,
        issueNumber: issue.issueNumber,
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
      });
      if (visible.length === 3) break;
    }
    return {
      serviceDate: key,
      cover: visible[0] ?? null,
      pages: visible.slice(1, 3),
    };
  }

  async choose(userId: string, input: ChooseColorDto): Promise<TodayDto> {
    const { key, date } = this.currentServiceDate();
    const palette = await this.getOrCreatePalette(key, date);
    if (!palette.colors.some(({ colorId }) => colorId === input.colorId)) {
      throw new AppException('COLOR_NOT_CANDIDATE');
    }

    const [choice, issue] = await Promise.all([
      this.prisma.userDailyChoice.findUnique({
        where: { userId_serviceDate: { userId, serviceDate: date } },
        select: { lockedAt: true },
      }),
      this.prisma.issue.findUnique({
        where: {
          authorId_serviceDate: { authorId: userId, serviceDate: date },
        },
        select: { id: true, deletedAt: true },
      }),
    ]);
    if (choice?.lockedAt || issue) throw new AppException('CHOICE_LOCKED');

    await this.prisma.userDailyChoice.upsert({
      where: { userId_serviceDate: { userId, serviceDate: date } },
      create: { userId, serviceDate: date, colorId: input.colorId },
      update: { colorId: input.colorId },
    });
    return this.toDto(userId, key, date, this.paletteCandidates(palette));
  }

  private currentServiceDate(): { key: string; date: Date } {
    const key = serviceDate(
      new Date(),
      this.config.getOrThrow<string>('SERVICE_TIME_ZONE'),
    );
    return { key, date: new Date(`${key}T00:00:00.000Z`) };
  }

  private async getOrCreatePalette(
    key: string,
    date: Date,
  ): Promise<PaletteWithColors> {
    const existing = await this.prisma.dailyPalette.findUnique({
      where: { serviceDate: date },
      include: paletteInclude,
    });
    if (existing) return existing;

    const candidateIds = (await this.generatedCandidates(key)).map(
      ({ id }) => id,
    );
    try {
      return await this.prisma.dailyPalette.create({
        data: {
          serviceDate: date,
          colors: {
            create: candidateIds.map((colorId, index) => ({
              colorId,
              position: index + 1,
            })),
          },
        },
        include: paletteInclude,
      });
    } catch (error) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        return this.prisma.dailyPalette.findUniqueOrThrow({
          where: { serviceDate: date },
          include: paletteInclude,
        });
      }
      throw error;
    }
  }

  private async generatedCandidates(key: string): Promise<ColorDto[]> {
    const colors = await this.prisma.color.findMany({
      orderBy: { sortOrder: 'asc' },
    });
    const byId = new Map(colors.map((color) => [color.id, color]));
    return dailyCandidateIds(
      key,
      colors.map(({ id }) => id),
    ).map((id) => {
      const color = byId.get(id);
      if (!color) throw new Error(`색 기준 데이터가 없어요: ${id}`);
      return {
        id: color.id,
        nameKo: color.nameKo,
        nameEn: color.nameEn,
        hex: color.hex,
      };
    });
  }

  private paletteCandidates(palette: PaletteWithColors): ColorDto[] {
    return palette.colors.map(({ color }) => ({
      id: color.id,
      nameKo: color.nameKo,
      nameEn: color.nameEn,
      hex: color.hex,
    }));
  }

  private async toDto(
    userId: string,
    key: string,
    date: Date,
    candidates: ColorDto[],
  ): Promise<TodayDto> {
    const [choice, issue] = await Promise.all([
      this.prisma.userDailyChoice.findUnique({
        where: { userId_serviceDate: { userId, serviceDate: date } },
        select: { colorId: true },
      }),
      this.prisma.issue.findUnique({
        where: {
          authorId_serviceDate: { authorId: userId, serviceDate: date },
        },
        select: { id: true, deletedAt: true },
      }),
    ]);
    return {
      serviceDate: key,
      candidates,
      selectedColorId: choice?.colorId ?? null,
      hasPublishedToday: Boolean(issue && !issue.deletedAt),
    };
  }
}

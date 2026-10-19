import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createHash, randomBytes } from 'node:crypto';
import { AppException } from '../common/app-exception.js';
import { serviceDate } from '../common/service-date.js';
import { IssuesService } from '../issues/issues.service.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { CreateShareLinkDto } from './dto/create-share-link.dto.js';
import { ShareLinkDto } from './dto/share-link.dto.js';
import {
  SharedIssueDto,
  SharedIssuePublicDto,
} from './dto/shared-issue-public.dto.js';

@Injectable()
export class ShareService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly issuesService: IssuesService,
    private readonly config: ConfigService,
  ) {}

  async open(
    userId: string | null,
    token: string,
  ): Promise<SharedIssuePublicDto> {
    const link = await this.prisma.shareLink.findUnique({
      where: { tokenHash: createHash('sha256').update(token).digest('hex') },
      include: {
        issue: {
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
        },
        twin: {
          include: {
            participations: {
              include: {
                user: { select: { profile: { select: { masthead: true } } } },
                post: { include: { media: true, color: true } },
              },
            },
          },
        },
      },
    });
    if (!link) throw new AppException('NOT_FOUND');

    if (link.issue) {
      if (link.issue.deletedAt) throw new AppException('NOT_FOUND');
      if (userId) {
        const issue = await this.issuesService.publicIssue(
          userId,
          link.issue.id,
        );
        return { kind: 'ISSUE', issue: this.sharedIssue(issue), twin: null };
      }
      const today = serviceDate(
        new Date(),
        this.config.getOrThrow<string>('SERVICE_TIME_ZONE'),
      );
      if (this.dateKey(link.issue.serviceDate) >= today) {
        throw new AppException('NOT_FOUND');
      }
      if (!link.issue.author.profile) throw new AppException('NOT_FOUND');
      return {
        kind: 'ISSUE',
        issue: {
          masthead: link.issue.author.profile.masthead,
          issueNumber: link.issue.issueNumber,
          serviceDate: this.dateKey(link.issue.serviceDate),
          publishedAt: link.issue.publishedAt.toISOString(),
          color: this.color(link.issue.color),
          media: link.issue.media,
          caption: link.issue.caption,
          faceCrop: link.issue.faceCrop,
          paintStroke: link.issue.paintStroke,
          garments: link.issue.garments.map(
            ({ garment, todayColor, x, y }) => ({
              garmentId: garment.id,
              kind: garment.kind,
              name: garment.name,
              note: garment.note,
              todayColor,
              x,
              y,
            }),
          ),
        },
        twin: null,
      };
    }

    if (!link.twin?.publishedAt) throw new AppException('NOT_FOUND');
    if (userId) {
      const participantIds = link.twin.participations.map(
        ({ userId: id }) => id,
      );
      const block = await this.prisma.block.findFirst({
        where: { blockerId: userId, blockedId: { in: participantIds } },
        select: { id: true },
      });
      if (block) throw new AppException('NOT_FOUND');
    }
    const posts = link.twin.participations.map((participant) => {
      if (!participant.user.profile || !participant.post) {
        throw new AppException('NOT_FOUND');
      }
      return {
        masthead: participant.user.profile.masthead,
        color: this.color(participant.post.color),
        media: {
          id: participant.post.media.id,
          mimeType: participant.post.media.mimeType,
          width: participant.post.media.width,
          height: participant.post.media.height,
        },
        postedAt: participant.post.createdAt.toISOString(),
      };
    });
    return {
      kind: 'TWIN',
      issue: null,
      twin: {
        serviceDate: this.dateKey(link.twin.serviceDate),
        publishedAt: link.twin.publishedAt.toISOString(),
        posts,
      },
    };
  }

  async create(
    userId: string,
    input: CreateShareLinkDto,
  ): Promise<ShareLinkDto> {
    if (Boolean(input.issueId) === Boolean(input.twinId)) {
      throw new AppException('VALIDATION', {
        target: ['issueId 또는 twinId 중 하나만 보내 주세요.'],
      });
    }

    if (input.issueId) {
      await this.issuesService.assertVisible(userId, input.issueId);
    } else {
      const twin = await this.prisma.twin.findUnique({
        where: { id: input.twinId },
        select: {
          publishedAt: true,
          participations: {
            where: { userId },
            select: { userId: true },
          },
        },
      });
      if (!twin || twin.participations.length === 0) {
        throw new AppException('NOT_FOUND');
      }
      if (!twin.publishedAt) throw new AppException('SHARE_NOT_PUBLIC');
    }

    const token = randomBytes(32).toString('base64url');
    const link = await this.prisma.shareLink.create({
      data: {
        creatorId: userId,
        tokenHash: createHash('sha256').update(token).digest('hex'),
        issueId: input.issueId,
        twinId: input.twinId,
      },
    });
    return {
      token,
      path: `/api/share-links/${token}`,
      createdAt: link.createdAt.toISOString(),
    };
  }

  private sharedIssue(issue: {
    masthead: string;
    issueNumber: number;
    serviceDate: string;
    publishedAt: string;
    color: { id: string; nameKo: string; nameEn: string; hex: string };
    media: {
      id: string;
      mimeType: string;
      width: number | null;
      height: number | null;
    };
    caption: string;
    faceCrop: string;
    paintStroke: boolean;
    garments: SharedIssueDto['garments'];
  }): SharedIssueDto {
    return {
      masthead: issue.masthead,
      issueNumber: issue.issueNumber,
      serviceDate: issue.serviceDate,
      publishedAt: issue.publishedAt,
      color: issue.color,
      media: issue.media,
      caption: issue.caption,
      faceCrop: issue.faceCrop,
      paintStroke: issue.paintStroke,
      garments: issue.garments,
    };
  }

  private color(color: {
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
}

import { Injectable } from '@nestjs/common';
import { createHash, randomBytes } from 'node:crypto';
import { AppException } from '../common/app-exception.js';
import { IssuesService } from '../issues/issues.service.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { CreateShareLinkDto } from './dto/create-share-link.dto.js';
import { ShareLinkDto } from './dto/share-link.dto.js';

@Injectable()
export class ShareService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly issuesService: IssuesService,
  ) {}

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
}

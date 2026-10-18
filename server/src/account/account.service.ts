import { Injectable, Logger } from '@nestjs/common';
import { Prisma } from '../generated/prisma/client.js';
import { AppException } from '../common/app-exception.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { MediaService } from '../media/media.service.js';
import { ProfileOwnerDto } from '../profile/dto/profile-owner.dto.js';
import { DeleteAccountDto } from './dto/delete-account.dto.js';
import { NotificationSettingsDto } from './dto/notification-settings.dto.js';
import { UpdateProfileDto } from './dto/update-profile.dto.js';

const MASTHEAD_PATTERN = /^[a-z]{2,10}$/;

const DEFAULT_NOTIFICATION_SETTINGS: NotificationSettingsDto = {
  enabled: true,
  newIssue: true,
  reactions: true,
};

@Injectable()
export class AccountService {
  private readonly logger = new Logger(AccountService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly mediaService: MediaService,
  ) {}

  async updateProfile(
    userId: string,
    input: UpdateProfileDto,
  ): Promise<ProfileOwnerDto> {
    if (input.masthead === undefined && input.bio === undefined) {
      throw new AppException('VALIDATION', {
        body: ['masthead 또는 bio 중 하나는 보내야 합니다.'],
      });
    }
    if (
      input.masthead !== undefined &&
      !MASTHEAD_PATTERN.test(input.masthead)
    ) {
      throw new AppException('MASTHEAD_INVALID');
    }

    try {
      return await this.prisma.profile.update({
        where: { userId },
        data: {
          masthead: input.masthead,
          bio: input.bio?.trim(),
        },
        select: { id: true, masthead: true, bio: true, issueCount: true },
      });
    } catch (error) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        throw new AppException('MASTHEAD_TAKEN');
      }
      throw error;
    }
  }

  async notifications(userId: string): Promise<NotificationSettingsDto> {
    const settings = await this.prisma.notificationSettings.findUnique({
      where: { userId },
      select: { enabled: true, newIssue: true, reactions: true },
    });
    if (settings) {
      return settings;
    }

    return {
      enabled: DEFAULT_NOTIFICATION_SETTINGS.enabled,
      newIssue: DEFAULT_NOTIFICATION_SETTINGS.newIssue,
      reactions: DEFAULT_NOTIFICATION_SETTINGS.reactions,
    };
  }

  async setNotifications(
    userId: string,
    input: NotificationSettingsDto,
  ): Promise<NotificationSettingsDto> {
    return this.prisma.notificationSettings.upsert({
      where: { userId },
      create: {
        userId,
        enabled: input.enabled,
        newIssue: input.newIssue,
        reactions: input.reactions,
      },
      update: {
        enabled: input.enabled,
        newIssue: input.newIssue,
        reactions: input.reactions,
      },
      select: { enabled: true, newIssue: true, reactions: true },
    });
  }

  async deleteAccount(userId: string, _input: DeleteAccountDto): Promise<void> {
    const files = await this.prisma.$transaction(async (tx) => {
      const participations = await tx.twinParticipation.findMany({
        where: { userId },
        select: { twinId: true },
      });
      const twinIds = participations.map(({ twinId }) => twinId);
      const [ownedMedia, twinPosts] = await Promise.all([
        tx.mediaAsset.findMany({
          where: { ownerId: userId },
          select: { id: true, storageKey: true },
        }),
        tx.twinPost.findMany({
          where: { twinId: { in: twinIds } },
          select: { media: { select: { id: true, storageKey: true } } },
        }),
      ]);
      const media = Array.from(
        new Map(
          [...ownedMedia, ...twinPosts.map(({ media }) => media)].map(
            (item) => [item.id, item] as const,
          ),
        ).values(),
      );
      await tx.twin.deleteMany({
        where: { id: { in: twinIds } },
      });
      await tx.issue.deleteMany({ where: { authorId: userId } });
      await tx.mediaAsset.deleteMany({
        where: { id: { in: media.map(({ id }) => id) } },
      });
      await tx.user.delete({ where: { id: userId } });
      return media;
    });

    const removed = await Promise.allSettled(
      files.map(({ id, storageKey }) =>
        this.mediaService.removeStoredFiles(storageKey, id),
      ),
    );
    const failures = removed.filter(({ status }) => status === 'rejected');
    if (failures.length > 0) {
      this.logger.warn(
        `계정 데이터는 삭제됐지만 미디어 파일 ${failures.length}개 정리에 실패했습니다.`,
      );
    }
  }
}

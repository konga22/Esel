import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import { NotificationSettingsDto } from './dto/notification-settings.dto.js';

const DEFAULT_NOTIFICATION_SETTINGS: NotificationSettingsDto = {
  enabled: true,
  newIssue: true,
  reactions: true,
};

@Injectable()
export class AccountService {
  constructor(private readonly prisma: PrismaService) {}

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
}

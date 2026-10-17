import { Injectable } from '@nestjs/common';
import { AppException } from '../common/app-exception.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { UserPublicDto } from './dto/user-public.dto.js';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async get(masthead: string): Promise<UserPublicDto> {
    const profile = await this.prisma.profile.findUnique({
      where: { masthead },
      select: { masthead: true, issueCount: true },
    });
    if (!profile) throw new AppException('NOT_FOUND');
    return profile;
  }
}

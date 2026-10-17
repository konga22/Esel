import { Injectable } from '@nestjs/common';
import { Prisma } from '../generated/prisma/client.js';
import { AppException } from '../common/app-exception.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { CreateProfileDto } from './dto/create-profile.dto.js';
import { MastheadAvailabilityDto } from './dto/masthead-availability.dto.js';
import { ProfileOwnerDto } from './dto/profile-owner.dto.js';

const MASTHEAD_PATTERN = /^[a-z]{2,10}$/;

@Injectable()
export class ProfileService {
  constructor(private readonly prisma: PrismaService) {}

  async mastheadAvailability(name: string): Promise<MastheadAvailabilityDto> {
    this.assertValidMasthead(name);
    const profile = await this.prisma.profile.findUnique({
      where: { masthead: name },
      select: { id: true },
    });
    return { masthead: name, available: !profile };
  }

  async create(
    userId: string,
    input: CreateProfileDto,
  ): Promise<ProfileOwnerDto> {
    this.assertValidMasthead(input.masthead);
    const existing = await this.prisma.profile.findUnique({
      where: { userId },
      select: { id: true },
    });
    if (existing) throw new AppException('PROFILE_EXISTS');

    try {
      return await this.prisma.profile.create({
        data: { userId, masthead: input.masthead },
        select: { id: true, masthead: true, issueCount: true },
      });
    } catch (error) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        const ownProfile = await this.prisma.profile.findUnique({
          where: { userId },
          select: { id: true },
        });
        throw new AppException(
          ownProfile ? 'PROFILE_EXISTS' : 'MASTHEAD_TAKEN',
        );
      }
      throw error;
    }
  }

  private assertValidMasthead(masthead: string): void {
    if (!MASTHEAD_PATTERN.test(masthead)) {
      throw new AppException('MASTHEAD_INVALID');
    }
  }
}

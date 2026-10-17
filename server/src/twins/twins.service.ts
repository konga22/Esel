import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Prisma } from '../generated/prisma/client.js';
import { AppException } from '../common/app-exception.js';
import { serviceDate } from '../common/service-date.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { ChooseColorDto } from '../today/dto/choose-color.dto.js';
import { TwinInviteDto } from './dto/twin-invite.dto.js';
import { TwinPostDto } from './dto/twin-post.dto.js';
import {
  TwinVisibilityDto,
  TwinVisibilityInput,
} from './dto/twin-visibility.dto.js';
import { TwinDto, TwinPostViewDto } from './dto/twin.dto.js';
import { twinCandidateIds } from './twins.rules.js';

const UUID_PATTERN =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

const twinInclude = {
  participations: {
    include: {
      user: { select: { profile: { select: { masthead: true } } } },
      candidates: {
        include: { color: true },
        orderBy: { position: 'asc' as const },
      },
      post: { include: { media: true } },
    },
  },
} satisfies Prisma.TwinInclude;

type TwinWithDetails = Prisma.TwinGetPayload<{ include: typeof twinInclude }>;

@Injectable()
export class TwinsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
  ) {}

  async invite(userId: string, input: TwinInviteDto): Promise<TwinDto> {
    const [userAId, userBId] = this.orderedPair(userId, input.friendId);
    const friendship = await this.prisma.friendship.findUnique({
      where: { userAId_userBId: { userAId, userBId } },
      select: { id: true },
    });
    if (!friendship) throw new AppException('NOT_FOUND');

    const { key, date } = this.currentServiceDate();
    const colors = await this.prisma.color.findMany({
      orderBy: { sortOrder: 'asc' },
      select: { id: true },
    });
    const recommendations = twinCandidateIds(
      `${key}:${userAId}:${userBId}`,
      colors.map(({ id }) => id),
    );
    const candidateByUser = new Map([
      [userAId, recommendations.userA],
      [userBId, recommendations.userB],
    ]);

    try {
      const twin = await this.prisma.twin.create({
        data: {
          serviceDate: date,
          participations: {
            create: [userId, input.friendId].map((participantId) => ({
              userId: participantId,
              serviceDate: date,
              role: participantId === userId ? 'INVITER' : 'INVITEE',
              candidates: {
                create: (candidateByUser.get(participantId) ?? []).map(
                  (colorId, index) => ({ colorId, position: index + 1 }),
                ),
              },
            })),
          },
        },
        include: twinInclude,
      });
      return this.toDto(userId, twin);
    } catch (error) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        throw new AppException('TWIN_STATE');
      }
      throw error;
    }
  }

  async get(userId: string, twinId: string): Promise<TwinDto> {
    return this.toDto(userId, await this.requireTwin(userId, twinId));
  }

  async accept(userId: string, twinId: string): Promise<TwinDto> {
    const twin = await this.requireTwin(userId, twinId);
    const me = twin.participations.find(({ userId: id }) => id === userId);
    if (twin.status !== 'INVITED' || me?.role !== 'INVITEE') {
      throw new AppException('TWIN_STATE');
    }
    const updated = await this.prisma.twin.updateMany({
      where: { id: twinId, status: 'INVITED' },
      data: { status: 'ACCEPTED', acceptedAt: new Date() },
    });
    if (updated.count !== 1) throw new AppException('TWIN_STATE');
    return this.toDto(userId, await this.requireTwin(userId, twinId));
  }

  async choose(
    userId: string,
    twinId: string,
    input: ChooseColorDto,
  ): Promise<TwinDto> {
    const twin = await this.requireTwin(userId, twinId);
    const me = twin.participations.find(({ userId: id }) => id === userId);
    if (twin.status !== 'ACCEPTED' || !me || me.post) {
      throw new AppException('TWIN_STATE');
    }
    if (!me.candidates.some(({ colorId }) => colorId === input.colorId)) {
      throw new AppException('COLOR_NOT_CANDIDATE');
    }
    await this.prisma.twinParticipation.update({
      where: { twinId_userId: { twinId, userId } },
      data: { choiceColorId: input.colorId },
    });
    return this.toDto(userId, await this.requireTwin(userId, twinId));
  }

  async post(
    userId: string,
    twinId: string,
    input: TwinPostDto,
  ): Promise<TwinDto> {
    const twin = await this.requireTwin(userId, twinId);
    const me = twin.participations.find(({ userId: id }) => id === userId);
    if (twin.status !== 'ACCEPTED' || !me?.choiceColorId || me.post) {
      throw new AppException('TWIN_STATE');
    }
    const media = await this.prisma.mediaAsset.findUnique({
      where: { id: input.mediaId },
      include: { issue: { select: { id: true } }, twinPost: true },
    });
    if (!media || media.ownerId !== userId) {
      throw new AppException('NOT_FOUND');
    }
    if (media.status !== 'READY') throw new AppException('MEDIA_NOT_READY');
    if (media.issue || media.twinPost) throw new AppException('TWIN_STATE');

    try {
      await this.prisma.twinPost.create({
        data: {
          twinId,
          userId,
          mediaId: input.mediaId,
          colorId: me.choiceColorId,
        },
      });
    } catch (error) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        throw new AppException('TWIN_STATE');
      }
      throw error;
    }
    return this.toDto(userId, await this.requireTwin(userId, twinId));
  }

  async visibility(
    userId: string,
    twinId: string,
    input: TwinVisibilityDto,
  ): Promise<TwinDto> {
    const twin = await this.requireTwin(userId, twinId);
    if (twin.publishedAt || !twin.participations.every(({ post }) => post)) {
      throw new AppException('TWIN_STATE');
    }

    await this.prisma.$transaction([
      this.prisma.twinParticipation.updateMany({
        where: { twinId },
        data: { consentedAt: null },
      }),
      this.prisma.twinParticipation.update({
        where: { twinId_userId: { twinId, userId } },
        data: {
          visibility: input.visibility.toUpperCase() as
            'PRIVATE' | 'SOLO' | 'JOINT',
        },
      }),
    ]);
    return this.toDto(userId, await this.requireTwin(userId, twinId));
  }

  async consent(userId: string, twinId: string): Promise<TwinDto> {
    const twin = await this.requireTwin(userId, twinId);
    if (
      twin.publishedAt ||
      !twin.participations.every(
        ({ post, visibility }) => post && visibility === 'JOINT',
      )
    ) {
      throw new AppException('TWIN_STATE');
    }
    await this.prisma.twinParticipation.updateMany({
      where: { twinId, userId, visibility: 'JOINT', consentedAt: null },
      data: { consentedAt: new Date() },
    });
    return this.toDto(userId, await this.requireTwin(userId, twinId));
  }

  async publish(userId: string, twinId: string): Promise<TwinDto> {
    const twin = await this.requireTwin(userId, twinId);
    if (
      twin.publishedAt ||
      !twin.participations.every(
        ({ post, visibility }) => post && visibility === 'JOINT',
      )
    ) {
      throw new AppException('TWIN_STATE');
    }
    if (!twin.participations.every(({ consentedAt }) => consentedAt)) {
      throw new AppException('TWIN_CONSENT_REQUIRED');
    }
    const updated = await this.prisma.twin.updateMany({
      where: { id: twinId, publishedAt: null },
      data: { publishedAt: new Date() },
    });
    if (updated.count !== 1) throw new AppException('TWIN_STATE');
    return this.toDto(userId, await this.requireTwin(userId, twinId));
  }

  private async requireTwin(
    userId: string,
    twinId: string,
  ): Promise<TwinWithDetails> {
    if (!UUID_PATTERN.test(twinId)) throw new AppException('NOT_FOUND');
    const twin = await this.prisma.twin.findUnique({
      where: { id: twinId },
      include: twinInclude,
    });
    if (!twin?.participations.some(({ userId: id }) => id === userId)) {
      throw new AppException('NOT_FOUND');
    }
    return twin;
  }

  private toDto(userId: string, twin: TwinWithDetails): TwinDto {
    const me = twin.participations.find(({ userId: id }) => id === userId);
    const partner = twin.participations.find(({ userId: id }) => id !== userId);
    if (!me || !partner?.user.profile) throw new AppException('NOT_FOUND');
    const accepted = twin.status === 'ACCEPTED';
    const bothPosted = twin.participations.every(({ post }) => Boolean(post));
    const bothChose = twin.participations.every(({ choiceColorId }) =>
      Boolean(choiceColorId),
    );
    const bothJoint = twin.participations.every(
      ({ visibility }) => visibility === 'JOINT',
    );
    const anyVisibility = twin.participations.some(({ visibility }) =>
      Boolean(visibility),
    );
    return {
      id: twin.id,
      serviceDate: this.dateKey(twin.serviceDate),
      status: !accepted
        ? 'INVITED'
        : twin.publishedAt
          ? 'PUBLISHED'
          : bothPosted && bothJoint
            ? 'CONSENT_WAITING'
            : bothPosted && anyVisibility
              ? 'SHARING'
              : bothPosted
                ? 'REVEALED'
                : bothChose
                  ? 'POSTING'
                  : 'CHOOSING',
      invitedByMe: me.role === 'INVITER',
      partner: {
        friendId: partner.userId,
        masthead: partner.user.profile.masthead,
      },
      myCandidates: accepted
        ? me.candidates.map(({ color }) => this.colorDto(color))
        : [],
      partnerCandidates: accepted
        ? partner.candidates.map(({ color }) => this.colorDto(color))
        : [],
      myColorId: me.choiceColorId,
      partnerColorId: partner.choiceColorId,
      myPost: me.post ? this.postDto(me.post) : null,
      partnerPost:
        bothPosted && partner.post ? this.postDto(partner.post) : null,
      myVisibility: this.visibilityValue(me.visibility),
      partnerVisibility: this.visibilityValue(partner.visibility),
      myConsented: Boolean(me.consentedAt),
      partnerConsented: Boolean(partner.consentedAt),
      publishedAt: twin.publishedAt?.toISOString() ?? null,
    };
  }

  private visibilityValue(
    visibility: 'PRIVATE' | 'SOLO' | 'JOINT' | null,
  ): TwinVisibilityInput | null {
    if (!visibility) return null;
    return TwinVisibilityInput[visibility] as TwinVisibilityInput;
  }

  private postDto(post: {
    colorId: string;
    createdAt: Date;
    media: {
      id: string;
      mimeType: string;
      width: number | null;
      height: number | null;
    };
  }): TwinPostViewDto {
    return {
      colorId: post.colorId,
      postedAt: post.createdAt.toISOString(),
      media: {
        id: post.media.id,
        mimeType: post.media.mimeType,
        width: post.media.width,
        height: post.media.height,
      },
    };
  }

  private colorDto(color: {
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

  private currentServiceDate(): { key: string; date: Date } {
    const key = serviceDate(
      new Date(),
      this.config.getOrThrow<string>('SERVICE_TIME_ZONE'),
    );
    return { key, date: new Date(`${key}T00:00:00.000Z`) };
  }

  private dateKey(date: Date): string {
    return date.toISOString().slice(0, 10);
  }

  private orderedPair(left: string, right: string): [string, string] {
    return left < right ? [left, right] : [right, left];
  }
}

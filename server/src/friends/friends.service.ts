import { Injectable } from '@nestjs/common';
import { Prisma } from '../generated/prisma/client.js';
import { AppException } from '../common/app-exception.js';
import { isWriteConflict } from '../prisma/is-write-conflict.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { FriendPageDto } from './dto/friend-page.dto.js';
import { FriendDto } from './dto/friend.dto.js';
import { FriendRequestCreateDto } from './dto/friend-request-create.dto.js';
import { FriendRequestPageDto } from './dto/friend-request-page.dto.js';
import { FriendRequestDto } from './dto/friend-request.dto.js';

const PAGE_SIZE = 20;
const UUID_PATTERN =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

type Cursor = { id: string; createdAt: Date };

@Injectable()
export class FriendsService {
  constructor(private readonly prisma: PrismaService) {}

  async list(userId: string, cursor?: string): Promise<FriendPageDto> {
    const cursorValue = this.decodeCursor(cursor);
    const friendships = await this.prisma.friendship.findMany({
      where: {
        AND: [
          { OR: [{ userAId: userId }, { userBId: userId }] },
          ...(cursorValue ? [this.beforeCursor(cursorValue)] : []),
        ],
      },
      include: {
        userA: { select: { profile: { select: { masthead: true } } } },
        userB: { select: { profile: { select: { masthead: true } } } },
      },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take: PAGE_SIZE + 1,
    });
    const page = friendships.slice(0, PAGE_SIZE);
    return {
      items: page
        .map((friendship) => this.toFriendDto(userId, friendship))
        .filter((friend): friend is FriendDto => friend !== null),
      nextCursor:
        friendships.length > PAGE_SIZE && page.at(-1)
          ? this.encodeCursor(page.at(-1)!)
          : null,
    };
  }

  async requests(
    userId: string,
    cursor?: string,
  ): Promise<FriendRequestPageDto> {
    const cursorValue = this.decodeCursor(cursor);
    const requests = await this.prisma.friendRequest.findMany({
      where: {
        receiverId: userId,
        ...(cursorValue ? this.beforeCursor(cursorValue) : {}),
      },
      include: {
        sender: { select: { profile: { select: { masthead: true } } } },
      },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take: PAGE_SIZE + 1,
    });
    const page = requests.slice(0, PAGE_SIZE);
    return {
      items: page
        .filter(({ sender }) => Boolean(sender.profile))
        .map((request) => ({
          id: request.id,
          masthead: request.sender.profile?.masthead ?? '',
          createdAt: request.createdAt.toISOString(),
        })),
      nextCursor:
        requests.length > PAGE_SIZE && page.at(-1)
          ? this.encodeCursor(page.at(-1)!)
          : null,
    };
  }

  async request(
    userId: string,
    input: FriendRequestCreateDto,
  ): Promise<FriendRequestDto> {
    const target = await this.prisma.profile.findUnique({
      where: { masthead: input.masthead },
      select: { userId: true, masthead: true },
    });
    if (!target) throw new AppException('NOT_FOUND');
    if (target.userId === userId) throw new AppException('ALREADY_FRIENDS');

    const [userAId, userBId] = this.orderedPair(userId, target.userId);
    for (let attempt = 0; attempt < 5; attempt += 1) {
      try {
        const request = await this.prisma.$transaction(
          async (tx) => {
            const existingFriend = await tx.friendship.findUnique({
              where: { userAId_userBId: { userAId, userBId } },
              select: { id: true },
            });
            if (existingFriend) throw new AppException('ALREADY_FRIENDS');
            return tx.friendRequest.create({
              data: {
                pairKey: this.pairKey(userAId, userBId),
                senderId: userId,
                receiverId: target.userId,
              },
            });
          },
          { isolationLevel: Prisma.TransactionIsolationLevel.Serializable },
        );
        return {
          id: request.id,
          masthead: target.masthead,
          createdAt: request.createdAt.toISOString(),
        };
      } catch (error) {
        if (error instanceof AppException) throw error;
        if (
          error instanceof Prisma.PrismaClientKnownRequestError &&
          error.code === 'P2002'
        ) {
          throw new AppException('REQUEST_EXISTS');
        }
        if (isWriteConflict(error) && attempt < 4) continue;
        throw error;
      }
    }
    throw new AppException('REQUEST_EXISTS');
  }

  async accept(userId: string, requestId: string): Promise<FriendDto> {
    this.assertUuid(requestId);
    for (let attempt = 0; attempt < 5; attempt += 1) {
      try {
        return await this.prisma.$transaction(
          async (tx) => {
            const request = await tx.friendRequest.findUnique({
              where: { id: requestId },
              include: {
                sender: {
                  select: { profile: { select: { masthead: true } } },
                },
              },
            });
            this.assertRequestOwner(userId, request);
            if (!request?.sender.profile) throw new AppException('NOT_FOUND');

            const [userAId, userBId] = this.orderedPair(
              request.senderId,
              request.receiverId,
            );
            const friendship = await tx.friendship.upsert({
              where: { userAId_userBId: { userAId, userBId } },
              create: { userAId, userBId },
              update: {},
            });
            const deleted = await tx.friendRequest.deleteMany({
              where: { id: requestId },
            });
            if (deleted.count !== 1) throw new AppException('NOT_FOUND');
            return {
              friendId: request.senderId,
              masthead: request.sender.profile.masthead,
              friendsSince: friendship.createdAt.toISOString(),
            };
          },
          { isolationLevel: Prisma.TransactionIsolationLevel.Serializable },
        );
      } catch (error) {
        if (isWriteConflict(error) && attempt < 4) continue;
        throw error;
      }
    }
    throw new AppException('NOT_FOUND');
  }

  async decline(userId: string, requestId: string): Promise<void> {
    this.assertUuid(requestId);
    const request = await this.prisma.friendRequest.findUnique({
      where: { id: requestId },
      select: { senderId: true, receiverId: true },
    });
    this.assertRequestOwner(userId, request);
    await this.prisma.friendRequest.delete({ where: { id: requestId } });
  }

  private assertRequestOwner(
    userId: string,
    request: { senderId: string; receiverId: string } | null,
  ): void {
    if (!request) throw new AppException('NOT_FOUND');
    if (request.receiverId === userId) return;
    if (request.senderId === userId) throw new AppException('FORBIDDEN');
    throw new AppException('NOT_FOUND');
  }

  private toFriendDto(
    userId: string,
    friendship: {
      id: string;
      userAId: string;
      userBId: string;
      createdAt: Date;
      userA: { profile: { masthead: string } | null };
      userB: { profile: { masthead: string } | null };
    },
  ): FriendDto | null {
    const friendIsA = friendship.userBId === userId;
    const friend = friendIsA ? friendship.userA : friendship.userB;
    const friendId = friendIsA ? friendship.userAId : friendship.userBId;
    if (!friend.profile) return null;
    return {
      friendId,
      masthead: friend.profile.masthead,
      friendsSince: friendship.createdAt.toISOString(),
    };
  }

  private orderedPair(left: string, right: string): [string, string] {
    return left < right ? [left, right] : [right, left];
  }

  private pairKey(userAId: string, userBId: string): string {
    return `${userAId}:${userBId}`;
  }

  private beforeCursor(cursor: Cursor) {
    return {
      OR: [
        { createdAt: { lt: cursor.createdAt } },
        { createdAt: cursor.createdAt, id: { lt: cursor.id } },
      ],
    };
  }

  private encodeCursor(value: { id: string; createdAt: Date }): string {
    return Buffer.from(
      JSON.stringify({
        id: value.id,
        createdAt: value.createdAt.toISOString(),
      }),
    ).toString('base64url');
  }

  private decodeCursor(cursor?: string): Cursor | null {
    if (!cursor) return null;
    try {
      const value = JSON.parse(
        Buffer.from(cursor, 'base64url').toString('utf8'),
      ) as { id?: unknown; createdAt?: unknown };
      if (
        typeof value.id !== 'string' ||
        !UUID_PATTERN.test(value.id) ||
        typeof value.createdAt !== 'string'
      ) {
        return null;
      }
      const createdAt = new Date(value.createdAt);
      return Number.isNaN(createdAt.getTime())
        ? null
        : { id: value.id, createdAt };
    } catch {
      return null;
    }
  }

  private assertUuid(id: string): void {
    if (!UUID_PATTERN.test(id)) throw new AppException('NOT_FOUND');
  }
}

import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { randomUUID } from 'node:crypto';
import { createReadStream, createWriteStream } from 'node:fs';
import { mkdir, readFile, rename, rm, stat } from 'node:fs/promises';
import { Readable, Transform } from 'node:stream';
import { finished, pipeline } from 'node:stream/promises';
import path from 'node:path';
import sharp from 'sharp';
import { AppException } from '../common/app-exception.js';
import type { AppErrorCode } from '../common/errors.js';
import { IssuesService } from '../issues/issues.service.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { MediaOwnerDto } from './dto/media-owner.dto.js';
import { MediaSize } from './dto/media-size-query.dto.js';
import { MediaUploadDto } from './dto/media-upload.dto.js';
import { PrepareMediaDto } from './dto/prepare-media.dto.js';
import {
  ALLOWED_MEDIA_TYPES,
  inspectImage,
  MAX_MEDIA_SIZE_BYTES,
} from './media.rules.js';

@Injectable()
export class MediaService {
  private readonly storageRoot: string;

  constructor(
    private readonly prisma: PrismaService,
    private readonly issuesService: IssuesService,
    config: ConfigService,
  ) {
    this.storageRoot = path.resolve(
      config.getOrThrow<string>('MEDIA_STORAGE_ROOT'),
    );
  }

  async prepare(
    userId: string,
    input: PrepareMediaDto,
  ): Promise<MediaUploadDto> {
    if (!ALLOWED_MEDIA_TYPES.includes(input.mimeType as never)) {
      throw new AppException('MEDIA_TYPE');
    }
    if (input.sizeBytes > MAX_MEDIA_SIZE_BYTES) {
      throw new AppException('MEDIA_TOO_LARGE');
    }

    const id = randomUUID();
    const storageKey = `pending/${id}.upload`;
    const uploadPath = this.pathFor(storageKey);
    await mkdir(path.dirname(uploadPath), { recursive: true });
    await this.prisma.mediaAsset.create({
      data: {
        id,
        ownerId: userId,
        storageKey,
        mimeType: input.mimeType,
        sizeBytes: input.sizeBytes,
      },
    });
    return {
      id,
      uploadUrl: `/api/media/${id}/file`,
      maxSizeBytes: MAX_MEDIA_SIZE_BYTES,
      allowedMimeTypes: [...ALLOWED_MEDIA_TYPES],
    };
  }

  async upload(
    userId: string,
    id: string,
    stream: Readable,
    contentType: string | undefined,
    contentLength: number | undefined,
  ): Promise<void> {
    const media = await this.requireOwnedPending(userId, id);
    const normalizedType = contentType?.split(';', 1)[0]?.trim().toLowerCase();
    if (!normalizedType || normalizedType !== media.mimeType) {
      throw new AppException('MEDIA_TYPE');
    }
    if (contentLength !== undefined && contentLength > MAX_MEDIA_SIZE_BYTES) {
      stream.resume();
      await finished(stream);
      throw new AppException('MEDIA_TOO_LARGE');
    }

    const candidateStorageKey = `pending/${id}-${randomUUID()}.upload`;
    const target = this.pathFor(candidateStorageKey);
    const temporary = `${target}.${randomUUID()}.part`;
    await mkdir(path.dirname(target), { recursive: true });
    let received = 0;
    const limiter = new Transform({
      transform(chunk: Buffer, _encoding, callback) {
        received += chunk.length;
        callback(
          received > MAX_MEDIA_SIZE_BYTES
            ? new AppException('MEDIA_TOO_LARGE')
            : null,
          chunk,
        );
      },
    });

    let candidateReady = false;
    let claimed = false;
    try {
      await pipeline(
        stream,
        limiter,
        createWriteStream(temporary, { flags: 'wx' }),
      );
      if (received < 1) throw new AppException('MEDIA_TYPE');
      await rename(temporary, target);
      candidateReady = true;
      const updated = await this.prisma.mediaAsset.updateMany({
        where: {
          id,
          ownerId: userId,
          status: 'PENDING',
          updatedAt: media.updatedAt,
        },
        data: { storageKey: candidateStorageKey, sizeBytes: received },
      });
      if (updated.count !== 1) throw new AppException('MEDIA_NOT_PENDING');
      claimed = true;
      await rm(this.pathFor(media.storageKey), { force: true }).catch(
        () => undefined,
      );
    } catch (error) {
      await rm(temporary, { force: true });
      if (candidateReady && !claimed) await rm(target, { force: true });
      throw error;
    }
  }

  async complete(userId: string, id: string): Promise<MediaOwnerDto> {
    const media = await this.requireOwnedPending(userId, id);

    const uploadPath = this.pathFor(media.storageKey);
    let fileSize: number;
    let bytes: Buffer;
    try {
      const file = await stat(uploadPath);
      if (!file.isFile()) throw new AppException('NOT_FOUND');
      fileSize = file.size;
      if (fileSize > MAX_MEDIA_SIZE_BYTES) {
        return this.reject(id, 'MEDIA_TOO_LARGE');
      }
      bytes = await readFile(uploadPath);
    } catch (error) {
      if (error instanceof AppException) throw error;
      if ((error as NodeJS.ErrnoException).code === 'ENOENT') {
        throw new AppException('NOT_FOUND');
      }
      throw error;
    }

    const image = inspectImage(bytes);
    if (!image || image.mimeType !== media.mimeType) {
      return this.reject(id, 'MEDIA_TYPE');
    }
    await this.createThumbnail(id, bytes, image.mimeType);
    return this.prisma.mediaAsset.update({
      where: { id },
      data: {
        status: 'READY',
        sizeBytes: fileSize,
        width: image.width,
        height: image.height,
      },
      select: {
        id: true,
        status: true,
        mimeType: true,
        sizeBytes: true,
        width: true,
        height: true,
      },
    });
  }

  async file(userId: string | null, id: string, size: MediaSize) {
    this.assertUuid(id);
    const media = await this.prisma.mediaAsset.findUnique({
      where: { id },
      include: {
        issue: { select: { id: true } },
        twinPost: {
          include: {
            participant: {
              include: {
                twin: {
                  select: {
                    publishedAt: true,
                    participations: {
                      select: {
                        userId: true,
                        visibility: true,
                        post: { select: { userId: true } },
                      },
                    },
                  },
                },
              },
            },
          },
        },
      },
    });
    if (!media || media.status !== 'READY') throw new AppException('NOT_FOUND');

    if (media.ownerId !== userId) {
      if (media.issue) {
        await this.issuesService.assertVisible(userId, media.issue.id);
      } else if (media.twinPost) {
        if (userId) {
          const block = await this.prisma.block.findUnique({
            where: {
              blockerId_blockedId: {
                blockerId: userId,
                blockedId: media.ownerId,
              },
            },
            select: { id: true },
          });
          if (block) throw new AppException('NOT_FOUND');
        }
        const { twin } = media.twinPost.participant;
        const participant = Boolean(
          userId &&
          twin.participations.some(
            ({ userId: participantId }) => participantId === userId,
          ),
        );
        const bothPosted = twin.participations.every(({ post }) => post);
        const owner = twin.participations.find(
          ({ userId: participantId }) => participantId === media.ownerId,
        );
        const publiclyVisible =
          Boolean(twin.publishedAt) || owner?.visibility === 'SOLO';
        if (!(publiclyVisible || (participant && bothPosted))) {
          throw new AppException('NOT_FOUND');
        }
      } else {
        throw new AppException('NOT_FOUND');
      }
    }

    const filePath =
      size === MediaSize.THUMB
        ? this.thumbnailPath(media.id)
        : this.pathFor(media.storageKey);
    let fileSize: number;
    try {
      const file = await stat(filePath);
      if (!file.isFile()) throw new AppException('NOT_FOUND');
      fileSize = file.size;
    } catch (error) {
      if (error instanceof AppException) throw error;
      if ((error as NodeJS.ErrnoException).code === 'ENOENT') {
        throw new AppException('NOT_FOUND');
      }
      throw error;
    }
    return {
      stream: createReadStream(filePath),
      mimeType: size === MediaSize.THUMB ? 'image/jpeg' : media.mimeType,
      sizeBytes: fileSize,
    };
  }

  async removeStoredFiles(storageKey: string, id: string): Promise<void> {
    await Promise.all([
      rm(this.pathFor(storageKey), { force: true }),
      rm(this.thumbnailPath(id), { force: true }),
    ]);
  }

  private async requireOwnedPending(userId: string, id: string) {
    this.assertUuid(id);
    const media = await this.prisma.mediaAsset.findUnique({ where: { id } });
    if (!media) throw new AppException('NOT_FOUND');
    if (media.ownerId !== userId) throw new AppException('FORBIDDEN');
    if (media.status !== 'PENDING') throw new AppException('MEDIA_NOT_PENDING');
    return media;
  }

  private async createThumbnail(
    id: string,
    bytes: Buffer,
    mimeType: string,
  ): Promise<void> {
    const target = this.thumbnailPath(id);
    const temporary = `${target}.${randomUUID()}.part`;
    await mkdir(path.dirname(target), { recursive: true });
    try {
      await sharp(bytes)
        .rotate()
        .resize(480, 480, { fit: 'inside', withoutEnlargement: true })
        .jpeg({ quality: 72, mozjpeg: true })
        .toFile(temporary);
      await rm(target, { force: true });
      await rename(temporary, target);
    } catch {
      await rm(temporary, { force: true });
      if (mimeType === 'image/heic') return;
      await this.reject(id, 'MEDIA_TYPE');
    }
  }

  private async reject(id: string, code: AppErrorCode): Promise<never> {
    await this.prisma.mediaAsset.update({
      where: { id },
      data: { status: 'REJECTED' },
    });
    throw new AppException(code);
  }

  private pathFor(storageKey: string): string {
    const target = path.resolve(this.storageRoot, storageKey);
    if (!target.startsWith(`${this.storageRoot}${path.sep}`)) {
      throw new Error('미디어 저장 경로가 루트 밖을 가리켜요.');
    }
    return target;
  }

  private thumbnailPath(id: string): string {
    return this.pathFor(`thumbs/${id}.jpg`);
  }

  private assertUuid(id: string): void {
    if (
      !/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(
        id,
      )
    ) {
      throw new AppException('NOT_FOUND');
    }
  }
}

import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { randomUUID } from 'node:crypto';
import { mkdir, readFile, stat } from 'node:fs/promises';
import path from 'node:path';
import { AppException } from '../common/app-exception.js';
import type { AppErrorCode } from '../common/errors.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { MediaOwnerDto } from './dto/media-owner.dto.js';
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
      storageKey,
      uploadPath,
      maxSizeBytes: MAX_MEDIA_SIZE_BYTES,
      allowedMimeTypes: [...ALLOWED_MEDIA_TYPES],
    };
  }

  async complete(userId: string, id: string): Promise<MediaOwnerDto> {
    if (
      !/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(
        id,
      )
    ) {
      throw new AppException('NOT_FOUND');
    }
    const media = await this.prisma.mediaAsset.findUnique({ where: { id } });
    if (!media) throw new AppException('NOT_FOUND');
    if (media.ownerId !== userId) throw new AppException('FORBIDDEN');

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
        storageKey: true,
      },
    });
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
}

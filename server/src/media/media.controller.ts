import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Post,
  Put,
  Query,
  Req,
  Res,
  StreamableFile,
} from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiBody,
  ApiCreatedResponse,
  ApiConflictResponse,
  ApiForbiddenResponse,
  ApiNotFoundResponse,
  ApiOperation,
  ApiOkResponse,
  ApiPayloadTooLargeResponse,
  ApiProduces,
  ApiTags,
  ApiUnauthorizedResponse,
  ApiUnsupportedMediaTypeResponse,
} from '@nestjs/swagger';
import type { Request, Response } from 'express';
import type { AuthUser } from '../auth/auth-user.js';
import { CurrentUser } from '../auth/current-user.decorator.js';
import { OptionalCurrentUser } from '../auth/optional-current-user.decorator.js';
import { Public } from '../common/public.decorator.js';
import { MediaOwnerDto } from './dto/media-owner.dto.js';
import { MediaSizeQueryDto } from './dto/media-size-query.dto.js';
import { MediaUploadDto } from './dto/media-upload.dto.js';
import { PrepareMediaDto } from './dto/prepare-media.dto.js';
import { MediaService } from './media.service.js';

@ApiTags('media')
@Controller('media')
export class MediaController {
  constructor(private readonly mediaService: MediaService) {}

  @Post()
  @ApiBearerAuth()
  @ApiOperation({ summary: '사진 올리기 준비(업로드 API 주소 받기)' })
  @ApiCreatedResponse({ type: MediaUploadDto })
  @ApiBadRequestResponse({ description: 'VALIDATION' })
  @ApiUnauthorizedResponse({ description: 'AUTH_REQUIRED 또는 TOKEN_EXPIRED' })
  @ApiPayloadTooLargeResponse({ description: 'MEDIA_TOO_LARGE' })
  @ApiUnsupportedMediaTypeResponse({ description: 'MEDIA_TYPE' })
  prepare(
    @CurrentUser() user: AuthUser,
    @Body() input: PrepareMediaDto,
  ): Promise<MediaUploadDto> {
    return this.mediaService.prepare(user.id, input);
  }

  @Put(':id/file')
  @ApiBearerAuth()
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: '서버 영구 디스크에 사진 파일 올리기' })
  @ApiBody({ schema: { type: 'string', format: 'binary' } })
  @ApiUnauthorizedResponse({ description: 'AUTH_REQUIRED 또는 TOKEN_EXPIRED' })
  @ApiForbiddenResponse({ description: 'FORBIDDEN' })
  @ApiNotFoundResponse({ description: 'NOT_FOUND' })
  @ApiConflictResponse({ description: 'MEDIA_NOT_PENDING' })
  @ApiPayloadTooLargeResponse({ description: 'MEDIA_TOO_LARGE' })
  @ApiUnsupportedMediaTypeResponse({ description: 'MEDIA_TYPE' })
  async upload(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
    @Req() request: Request,
  ): Promise<void> {
    const contentLengthHeader = request.headers['content-length'];
    const contentLength = contentLengthHeader
      ? Number(contentLengthHeader)
      : undefined;
    await this.mediaService.upload(
      user.id,
      id,
      request,
      request.headers['content-type'],
      Number.isFinite(contentLength) ? contentLength : undefined,
    );
  }

  @Post(':id/complete')
  @ApiBearerAuth()
  @ApiOperation({ summary: '사진 올리기 완료 확인·검증과 썸네일 생성' })
  @ApiCreatedResponse({ type: MediaOwnerDto })
  @ApiUnauthorizedResponse({ description: 'AUTH_REQUIRED 또는 TOKEN_EXPIRED' })
  @ApiForbiddenResponse({ description: 'FORBIDDEN' })
  @ApiNotFoundResponse({ description: 'NOT_FOUND' })
  @ApiConflictResponse({ description: 'MEDIA_NOT_PENDING' })
  @ApiPayloadTooLargeResponse({ description: 'MEDIA_TOO_LARGE' })
  @ApiUnsupportedMediaTypeResponse({ description: 'MEDIA_TYPE' })
  complete(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
  ): Promise<MediaOwnerDto> {
    return this.mediaService.complete(user.id, id);
  }

  @Get(':id')
  @Public()
  @ApiOperation({ summary: '공개 권한을 확인해 원본 또는 썸네일 사진 보기' })
  @ApiProduces('image/jpeg', 'image/png', 'image/heic')
  @ApiOkResponse({ schema: { type: 'string', format: 'binary' } })
  @ApiBadRequestResponse({ description: 'VALIDATION' })
  @ApiUnauthorizedResponse({ description: 'AUTH_REQUIRED 또는 TOKEN_EXPIRED' })
  @ApiNotFoundResponse({ description: 'NOT_FOUND' })
  async file(
    @OptionalCurrentUser() user: AuthUser | null,
    @Param('id') id: string,
    @Query() query: MediaSizeQueryDto,
    @Res({ passthrough: true }) response: Response,
  ): Promise<StreamableFile> {
    const file = await this.mediaService.file(user?.id ?? null, id, query.size);
    response.setHeader('Content-Type', file.mimeType);
    response.setHeader('Content-Length', file.sizeBytes);
    response.setHeader('Cache-Control', 'private, no-store');
    return new StreamableFile(file.stream);
  }
}

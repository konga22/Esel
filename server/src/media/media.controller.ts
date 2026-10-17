import { Body, Controller, Param, Post } from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiCreatedResponse,
  ApiConflictResponse,
  ApiForbiddenResponse,
  ApiNotFoundResponse,
  ApiOperation,
  ApiPayloadTooLargeResponse,
  ApiTags,
  ApiUnauthorizedResponse,
  ApiUnsupportedMediaTypeResponse,
} from '@nestjs/swagger';
import type { AuthUser } from '../auth/auth-user.js';
import { CurrentUser } from '../auth/current-user.decorator.js';
import { MediaOwnerDto } from './dto/media-owner.dto.js';
import { MediaUploadDto } from './dto/media-upload.dto.js';
import { PrepareMediaDto } from './dto/prepare-media.dto.js';
import { MediaService } from './media.service.js';

@ApiTags('media')
@ApiBearerAuth()
@Controller('media')
export class MediaController {
  constructor(private readonly mediaService: MediaService) {}

  @Post()
  @ApiOperation({ summary: '사진 올리기 준비(저장 위치 받기)' })
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

  @Post(':id/complete')
  @ApiOperation({ summary: '사진 올리기 완료 확인과 검증' })
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
}

import { Body, Controller, Post } from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiCreatedResponse,
  ApiNotFoundResponse,
  ApiOperation,
  ApiTags,
  ApiUnauthorizedResponse,
  ApiUnprocessableEntityResponse,
} from '@nestjs/swagger';
import type { AuthUser } from '../auth/auth-user.js';
import { CurrentUser } from '../auth/current-user.decorator.js';
import { CreateShareLinkDto } from './dto/create-share-link.dto.js';
import { ShareLinkDto } from './dto/share-link.dto.js';
import { ShareService } from './share.service.js';

@ApiTags('share')
@ApiBearerAuth()
@Controller('share-links')
export class ShareController {
  constructor(private readonly shareService: ShareService) {}

  @Post()
  @ApiOperation({ summary: '공개된 표지·공동 트윈의 공유 링크 만들기' })
  @ApiCreatedResponse({ type: ShareLinkDto })
  @ApiBadRequestResponse({ description: 'VALIDATION' })
  @ApiUnauthorizedResponse({ description: 'AUTH_REQUIRED 또는 TOKEN_EXPIRED' })
  @ApiNotFoundResponse({ description: 'NOT_FOUND' })
  @ApiUnprocessableEntityResponse({ description: 'SHARE_NOT_PUBLIC' })
  create(
    @CurrentUser() user: AuthUser,
    @Body() input: CreateShareLinkDto,
  ): Promise<ShareLinkDto> {
    return this.shareService.create(user.id, input);
  }
}

import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiCreatedResponse,
  ApiNotFoundResponse,
  ApiOperation,
  ApiOkResponse,
  ApiTags,
  ApiUnauthorizedResponse,
  ApiUnprocessableEntityResponse,
} from '@nestjs/swagger';
import type { AuthUser } from '../auth/auth-user.js';
import { CurrentUser } from '../auth/current-user.decorator.js';
import { OptionalCurrentUser } from '../auth/optional-current-user.decorator.js';
import { Public } from '../common/public.decorator.js';
import { CreateShareLinkDto } from './dto/create-share-link.dto.js';
import { ShareLinkDto } from './dto/share-link.dto.js';
import { SharedIssuePublicDto } from './dto/shared-issue-public.dto.js';
import { ShareService } from './share.service.js';

@ApiTags('share')
@ApiBearerAuth()
@Controller('share-links')
export class ShareController {
  constructor(private readonly shareService: ShareService) {}

  @Public()
  @Get(':token')
  @ApiOperation({ summary: '공유 링크 열기' })
  @ApiOkResponse({ type: SharedIssuePublicDto })
  @ApiNotFoundResponse({ description: 'NOT_FOUND' })
  open(
    @OptionalCurrentUser() user: AuthUser | null,
    @Param('token') token: string,
  ): Promise<SharedIssuePublicDto> {
    return this.shareService.open(user?.id ?? null, token);
  }

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

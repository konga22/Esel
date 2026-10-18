import { Controller, Get, Query } from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import type { AuthUser } from '../auth/auth-user.js';
import { CurrentUser } from '../auth/current-user.decorator.js';
import { FeedPageDto } from './dto/feed-page.dto.js';
import { FeedQueryDto } from './dto/feed-query.dto.js';
import { FeedService } from './feed.service.js';

@ApiTags('feed')
@ApiBearerAuth()
@Controller('feed')
export class FeedController {
  constructor(private readonly feedService: FeedService) {}

  @Get()
  @ApiOperation({ summary: '홈 피드(구독 + 추천, 공개 권한 먼저)' })
  @ApiOkResponse({ type: FeedPageDto })
  @ApiBadRequestResponse({ description: 'VALIDATION' })
  @ApiUnauthorizedResponse({ description: 'AUTH_REQUIRED 또는 TOKEN_EXPIRED' })
  list(
    @CurrentUser() user: AuthUser,
    @Query() query: FeedQueryDto,
  ): Promise<FeedPageDto> {
    return this.feedService.list(user.id, query.cursor);
  }
}

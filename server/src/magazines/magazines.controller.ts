import { Controller, Delete, Get, Param, Post, Query } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiCreatedResponse,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiOperation,
  ApiQuery,
  ApiTags,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import type { AuthUser } from '../auth/auth-user.js';
import { CurrentUser } from '../auth/current-user.decorator.js';
import { MagazinePublicDto } from './dto/magazine-public.dto.js';
import { SubscriptionStateDto } from './dto/subscription-state.dto.js';
import { MagazinesService } from './magazines.service.js';

@ApiTags('magazines')
@ApiBearerAuth()
@Controller('magazines')
export class MagazinesController {
  constructor(private readonly magazinesService: MagazinesService) {}

  @Get(':masthead')
  @ApiOperation({ summary: '남의 잡지(서가)와 지난 호' })
  @ApiQuery({ name: 'cursor', required: false })
  @ApiOkResponse({ type: MagazinePublicDto })
  @ApiUnauthorizedResponse({ description: 'AUTH_REQUIRED 또는 TOKEN_EXPIRED' })
  @ApiNotFoundResponse({ description: 'NOT_FOUND' })
  get(
    @CurrentUser() user: AuthUser,
    @Param('masthead') masthead: string,
    @Query('cursor') cursor?: string,
  ): Promise<MagazinePublicDto> {
    return this.magazinesService.get(user.id, masthead, cursor);
  }

  @Post(':masthead/subscription')
  @ApiOperation({ summary: '구독' })
  @ApiCreatedResponse({ type: SubscriptionStateDto })
  @ApiUnauthorizedResponse({ description: 'AUTH_REQUIRED 또는 TOKEN_EXPIRED' })
  @ApiNotFoundResponse({ description: 'NOT_FOUND' })
  subscribe(
    @CurrentUser() user: AuthUser,
    @Param('masthead') masthead: string,
  ): Promise<SubscriptionStateDto> {
    return this.magazinesService.subscribe(user.id, masthead);
  }

  @Delete(':masthead/subscription')
  @ApiOperation({ summary: '구독 취소' })
  @ApiOkResponse({ type: SubscriptionStateDto })
  @ApiUnauthorizedResponse({ description: 'AUTH_REQUIRED 또는 TOKEN_EXPIRED' })
  @ApiNotFoundResponse({ description: 'NOT_FOUND' })
  unsubscribe(
    @CurrentUser() user: AuthUser,
    @Param('masthead') masthead: string,
  ): Promise<SubscriptionStateDto> {
    return this.magazinesService.unsubscribe(user.id, masthead);
  }
}

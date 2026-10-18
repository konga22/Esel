import { Controller, Get, Param, Query } from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiForbiddenResponse,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiOperation,
  ApiQuery,
  ApiTags,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import type { AuthUser } from '../auth/auth-user.js';
import { CurrentUser } from '../auth/current-user.decorator.js';
import { IssueReactionsOwnerDto } from './dto/issue-reactions-owner.dto.js';
import { MagazineOwnerDto } from './dto/magazine-owner.dto.js';
import { ScrapPageDto } from './dto/scrap-page.dto.js';
import { ScrapsQueryDto } from './dto/scraps-query.dto.js';
import { MeService } from './me.service.js';

@ApiTags('me')
@ApiBearerAuth()
@Controller('me')
export class MeController {
  constructor(private readonly meService: MeService) {}

  @Get('magazine')
  @ApiOperation({ summary: '내 잡지(오늘 호, 지난 호, 소유자 숫자)' })
  @ApiQuery({ name: 'cursor', required: false })
  @ApiOkResponse({ type: MagazineOwnerDto })
  @ApiUnauthorizedResponse({ description: 'AUTH_REQUIRED 또는 TOKEN_EXPIRED' })
  magazine(
    @CurrentUser() user: AuthUser,
    @Query('cursor') cursor?: string,
  ): Promise<MagazineOwnerDto> {
    return this.meService.magazine(user.id, cursor);
  }

  @Get('scraps')
  @ApiOperation({ summary: '내가 저장한 캔버스 목록' })
  @ApiOkResponse({ type: ScrapPageDto })
  @ApiBadRequestResponse({ description: 'VALIDATION' })
  @ApiUnauthorizedResponse({ description: 'AUTH_REQUIRED 또는 TOKEN_EXPIRED' })
  scraps(
    @CurrentUser() user: AuthUser,
    @Query() query: ScrapsQueryDto,
  ): Promise<ScrapPageDto> {
    return this.meService.scraps(user.id, query.cursor);
  }

  @Get('issues/:id/reactions')
  @ApiOperation({ summary: '내 표지의 반응 수와 최근 목록' })
  @ApiOkResponse({ type: IssueReactionsOwnerDto })
  @ApiUnauthorizedResponse({ description: 'AUTH_REQUIRED 또는 TOKEN_EXPIRED' })
  @ApiForbiddenResponse({ description: 'FORBIDDEN' })
  @ApiNotFoundResponse({ description: 'NOT_FOUND' })
  reactions(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
  ): Promise<IssueReactionsOwnerDto> {
    return this.meService.reactions(user.id, id);
  }
}

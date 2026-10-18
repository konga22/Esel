import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Post,
  Query,
} from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiCreatedResponse,
  ApiForbiddenResponse,
  ApiNotFoundResponse,
  ApiNoContentResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
  ApiTooManyRequestsResponse,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import type { AuthUser } from '../auth/auth-user.js';
import { CurrentUser } from '../auth/current-user.decorator.js';
import { CreateReportDto } from './dto/create-report.dto.js';
import { BlockStateDto } from './dto/block-state.dto.js';
import { BlockedUserPageDto } from './dto/blocked-user-page.dto.js';
import { BlocksQueryDto } from './dto/blocks-query.dto.js';
import { ReportReceiptDto } from './dto/report-receipt.dto.js';
import { ModerationService } from './moderation.service.js';

@ApiTags('moderation')
@ApiBearerAuth()
@Controller()
export class ModerationController {
  constructor(private readonly moderationService: ModerationService) {}

  @Post('users/:masthead/block')
  @ApiOperation({ summary: '사람 차단' })
  @ApiCreatedResponse({ type: BlockStateDto })
  @ApiUnauthorizedResponse({ description: 'AUTH_REQUIRED 또는 TOKEN_EXPIRED' })
  @ApiNotFoundResponse({ description: 'NOT_FOUND' })
  block(
    @CurrentUser() user: AuthUser,
    @Param('masthead') masthead: string,
  ): Promise<BlockStateDto> {
    return this.moderationService.block(user.id, masthead);
  }

  @Delete('users/:masthead/block')
  @ApiOperation({ summary: '차단 풀기' })
  @ApiOkResponse({ type: BlockStateDto })
  @ApiUnauthorizedResponse({ description: 'AUTH_REQUIRED 또는 TOKEN_EXPIRED' })
  @ApiNotFoundResponse({ description: 'NOT_FOUND' })
  unblock(
    @CurrentUser() user: AuthUser,
    @Param('masthead') masthead: string,
  ): Promise<BlockStateDto> {
    return this.moderationService.unblock(user.id, masthead);
  }

  @Get('me/blocks')
  @ApiOperation({ summary: '내가 차단한 사람 목록' })
  @ApiOkResponse({ type: BlockedUserPageDto })
  @ApiUnauthorizedResponse({ description: 'AUTH_REQUIRED 또는 TOKEN_EXPIRED' })
  blocks(
    @CurrentUser() user: AuthUser,
    @Query() query: BlocksQueryDto,
  ): Promise<BlockedUserPageDto> {
    return this.moderationService.blocks(user.id, query.cursor);
  }

  @Delete('issues/:id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: '내 호 삭제' })
  @ApiNoContentResponse()
  @ApiForbiddenResponse({ description: 'FORBIDDEN' })
  @ApiUnauthorizedResponse({ description: 'AUTH_REQUIRED 또는 TOKEN_EXPIRED' })
  @ApiNotFoundResponse({ description: 'NOT_FOUND' })
  deleteIssue(
    @CurrentUser() user: AuthUser,
    @Param('id') issueId: string,
  ): Promise<void> {
    return this.moderationService.deleteIssue(user.id, issueId);
  }

  @Post('issues/:id/reports')
  @ApiOperation({ summary: '표지 신고 접수' })
  @ApiCreatedResponse({ type: ReportReceiptDto })
  @ApiBadRequestResponse({ description: 'VALIDATION' })
  @ApiUnauthorizedResponse({ description: 'AUTH_REQUIRED 또는 TOKEN_EXPIRED' })
  @ApiNotFoundResponse({ description: 'NOT_FOUND' })
  @ApiTooManyRequestsResponse({ description: 'RATE_LIMITED' })
  reportIssue(
    @CurrentUser() user: AuthUser,
    @Param('id') issueId: string,
    @Body() input: CreateReportDto,
  ): Promise<ReportReceiptDto> {
    return this.moderationService.reportIssue(user.id, issueId, input);
  }

  @Post('issues/:id/lines/:lineId/reports')
  @ApiOperation({ summary: '독자 한 줄 신고 접수' })
  @ApiCreatedResponse({ type: ReportReceiptDto })
  @ApiBadRequestResponse({ description: 'VALIDATION' })
  @ApiUnauthorizedResponse({ description: 'AUTH_REQUIRED 또는 TOKEN_EXPIRED' })
  @ApiNotFoundResponse({ description: 'NOT_FOUND' })
  @ApiTooManyRequestsResponse({ description: 'RATE_LIMITED' })
  reportLine(
    @CurrentUser() user: AuthUser,
    @Param('id') issueId: string,
    @Param('lineId') lineId: string,
    @Body() input: CreateReportDto,
  ): Promise<ReportReceiptDto> {
    return this.moderationService.reportLine(user.id, issueId, lineId, input);
  }
}

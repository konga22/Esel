import { Body, Controller, Param, Post } from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiCreatedResponse,
  ApiNotFoundResponse,
  ApiOperation,
  ApiTags,
  ApiTooManyRequestsResponse,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import type { AuthUser } from '../auth/auth-user.js';
import { CurrentUser } from '../auth/current-user.decorator.js';
import { CreateReportDto } from './dto/create-report.dto.js';
import { ReportReceiptDto } from './dto/report-receipt.dto.js';
import { ModerationService } from './moderation.service.js';

@ApiTags('moderation')
@ApiBearerAuth()
@Controller()
export class ModerationController {
  constructor(private readonly moderationService: ModerationService) {}

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

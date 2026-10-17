import { Body, Controller, Get, Param, Post, Query } from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiConflictResponse,
  ApiCreatedResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
  ApiUnauthorizedResponse,
  ApiUnprocessableEntityResponse,
} from '@nestjs/swagger';
import type { AuthUser } from '../auth/auth-user.js';
import { CurrentUser } from '../auth/current-user.decorator.js';
import { DayRecordDto } from './dto/day-record.dto.js';
import { MonthQueryDto } from './dto/month-query.dto.js';
import { MonthRecordDto } from './dto/month-record.dto.js';
import { RestoreColorDto } from './dto/restore-color.dto.js';
import { RestoreDateParamDto } from './dto/restore-date-param.dto.js';
import { RecordsService } from './records.service.js';

@ApiTags('records')
@ApiBearerAuth()
@Controller('me/records')
export class RecordsController {
  constructor(private readonly recordsService: RecordsService) {}

  @Get()
  @ApiOperation({ summary: '한 달 색 기록' })
  @ApiOkResponse({ type: MonthRecordDto })
  @ApiBadRequestResponse({ description: 'VALIDATION' })
  @ApiUnauthorizedResponse({ description: 'AUTH_REQUIRED 또는 TOKEN_EXPIRED' })
  month(
    @CurrentUser() user: AuthUser,
    @Query() query: MonthQueryDto,
  ): Promise<MonthRecordDto> {
    return this.recordsService.month(user.id, query.month);
  }

  @Post(':date/restore')
  @ApiOperation({ summary: '이번 달 지난 빈 날의 색 복원(월 2회)' })
  @ApiCreatedResponse({ type: DayRecordDto })
  @ApiBadRequestResponse({ description: 'VALIDATION' })
  @ApiUnauthorizedResponse({ description: 'AUTH_REQUIRED 또는 TOKEN_EXPIRED' })
  @ApiConflictResponse({ description: 'RESTORE_LIMIT' })
  @ApiUnprocessableEntityResponse({
    description: 'COLOR_NOT_CANDIDATE 또는 RESTORE_NOT_ALLOWED',
  })
  restore(
    @CurrentUser() user: AuthUser,
    @Param() params: RestoreDateParamDto,
    @Body() input: RestoreColorDto,
  ): Promise<DayRecordDto> {
    return this.recordsService.restore(user.id, params.date, input);
  }
}

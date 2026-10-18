import { Body, Controller, Get, Put } from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiConflictResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
  ApiUnauthorizedResponse,
  ApiUnprocessableEntityResponse,
} from '@nestjs/swagger';
import type { AuthUser } from '../auth/auth-user.js';
import { CurrentUser } from '../auth/current-user.decorator.js';
import { ChooseColorDto } from './dto/choose-color.dto.js';
import { TodayDto } from './dto/today.dto.js';
import { TodayCoverPublicDto } from './dto/today-cover-public.dto.js';
import { TodayService } from './today.service.js';
import { Public } from '../common/public.decorator.js';

@ApiTags('today')
@ApiBearerAuth()
@Controller('today')
export class TodayController {
  constructor(private readonly todayService: TodayService) {}

  @Public()
  @Get('cover')
  @ApiOperation({ summary: '비로그인용 오늘의 표지와 안쪽 2쪽' })
  @ApiOkResponse({ type: TodayCoverPublicDto })
  cover(): Promise<TodayCoverPublicDto> {
    return this.todayService.cover();
  }

  @Get()
  @ApiOperation({ summary: '오늘의 날짜, 후보 3색, 내 선택, 발행 여부' })
  @ApiOkResponse({ type: TodayDto })
  @ApiUnauthorizedResponse({ description: 'AUTH_REQUIRED 또는 TOKEN_EXPIRED' })
  get(@CurrentUser() user: AuthUser): Promise<TodayDto> {
    return this.todayService.get(user.id);
  }

  @Put('choice')
  @ApiOperation({ summary: '오늘의 색 고르기(발행 전까지 바꿀 수 있음)' })
  @ApiOkResponse({ type: TodayDto })
  @ApiBadRequestResponse({ description: 'VALIDATION' })
  @ApiUnauthorizedResponse({ description: 'AUTH_REQUIRED 또는 TOKEN_EXPIRED' })
  @ApiConflictResponse({ description: 'CHOICE_LOCKED' })
  @ApiUnprocessableEntityResponse({ description: 'COLOR_NOT_CANDIDATE' })
  choose(
    @CurrentUser() user: AuthUser,
    @Body() input: ChooseColorDto,
  ): Promise<TodayDto> {
    return this.todayService.choose(user.id, input);
  }
}

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
import { PaletteColorsDto } from './dto/palette-color.dto.js';
import { PalettePageDto } from './dto/palette-page.dto.js';
import { PaletteQueryDto } from './dto/palette-query.dto.js';
import { StandQueryDto } from './dto/stand-query.dto.js';
import { StandDto } from './dto/stand.dto.js';
import { StandService } from './stand.service.js';

@ApiTags('stand', 'palette')
@ApiBearerAuth()
@Controller()
export class StandController {
  constructor(private readonly standService: StandService) {}

  @Get('stand')
  @ApiOperation({ summary: '고른 색의 사진과 오늘 후보색 미리보기' })
  @ApiOkResponse({ type: StandDto })
  @ApiBadRequestResponse({ description: 'VALIDATION' })
  @ApiUnauthorizedResponse({ description: 'AUTH_REQUIRED 또는 TOKEN_EXPIRED' })
  get(
    @CurrentUser() user: AuthUser,
    @Query() query: StandQueryDto,
  ): Promise<StandDto> {
    return this.standService.get(
      user.id,
      query.colorId,
      query.date,
      query.cursor,
    );
  }

  @Get('palette/recommended')
  @ApiOperation({ summary: '팔레트 추천 탭: 사람마다 최신 공개 사진 한 장' })
  @ApiOkResponse({ type: PalettePageDto })
  @ApiBadRequestResponse({ description: 'VALIDATION' })
  @ApiUnauthorizedResponse({ description: 'AUTH_REQUIRED 또는 TOKEN_EXPIRED' })
  recommended(
    @CurrentUser() user: AuthUser,
    @Query() query: PaletteQueryDto,
  ): Promise<PalettePageDto> {
    return this.standService.recommended(user.id, query.cursor);
  }

  @Get('palette/colors')
  @ApiOperation({ summary: '팔레트 색상 목록 순서' })
  @ApiOkResponse({ type: PaletteColorsDto })
  @ApiUnauthorizedResponse({ description: 'AUTH_REQUIRED 또는 TOKEN_EXPIRED' })
  colors(@CurrentUser() user: AuthUser): Promise<PaletteColorsDto> {
    return this.standService.colors(user.id);
  }
}

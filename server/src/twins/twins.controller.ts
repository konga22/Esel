import { Body, Controller, Get, Param, Post, Put } from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiConflictResponse,
  ApiCreatedResponse,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
  ApiUnauthorizedResponse,
  ApiUnprocessableEntityResponse,
} from '@nestjs/swagger';
import type { AuthUser } from '../auth/auth-user.js';
import { CurrentUser } from '../auth/current-user.decorator.js';
import { ChooseColorDto } from '../today/dto/choose-color.dto.js';
import { TwinInviteDto } from './dto/twin-invite.dto.js';
import { TwinPostDto } from './dto/twin-post.dto.js';
import { TwinDto } from './dto/twin.dto.js';
import { TwinsService } from './twins.service.js';

@ApiTags('twins')
@ApiBearerAuth()
@Controller('twins')
export class TwinsController {
  constructor(private readonly twinsService: TwinsService) {}

  @Post()
  @ApiOperation({ summary: '친구를 오늘 트윈에 초대' })
  @ApiCreatedResponse({ type: TwinDto })
  @ApiBadRequestResponse({ description: 'VALIDATION' })
  @ApiUnauthorizedResponse({ description: 'AUTH_REQUIRED 또는 TOKEN_EXPIRED' })
  @ApiNotFoundResponse({ description: 'NOT_FOUND' })
  @ApiConflictResponse({ description: 'TWIN_STATE' })
  invite(
    @CurrentUser() user: AuthUser,
    @Body() input: TwinInviteDto,
  ): Promise<TwinDto> {
    return this.twinsService.invite(user.id, input);
  }

  @Get(':id')
  @ApiOperation({ summary: '트윈 현재 단계(상대 사진은 둘 다 게시 후에만)' })
  @ApiOkResponse({ type: TwinDto })
  @ApiUnauthorizedResponse({ description: 'AUTH_REQUIRED 또는 TOKEN_EXPIRED' })
  @ApiNotFoundResponse({ description: 'NOT_FOUND' })
  get(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
  ): Promise<TwinDto> {
    return this.twinsService.get(user.id, id);
  }

  @Post(':id/accept')
  @ApiOperation({ summary: '초대 수락' })
  @ApiCreatedResponse({ type: TwinDto })
  @ApiUnauthorizedResponse({ description: 'AUTH_REQUIRED 또는 TOKEN_EXPIRED' })
  @ApiNotFoundResponse({ description: 'NOT_FOUND' })
  @ApiConflictResponse({ description: 'TWIN_STATE' })
  accept(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
  ): Promise<TwinDto> {
    return this.twinsService.accept(user.id, id);
  }

  @Put(':id/choice')
  @ApiOperation({ summary: '내 트윈 색 고르기(내 후보 3개 중)' })
  @ApiOkResponse({ type: TwinDto })
  @ApiBadRequestResponse({ description: 'VALIDATION' })
  @ApiUnauthorizedResponse({ description: 'AUTH_REQUIRED 또는 TOKEN_EXPIRED' })
  @ApiNotFoundResponse({ description: 'NOT_FOUND' })
  @ApiConflictResponse({ description: 'TWIN_STATE' })
  @ApiUnprocessableEntityResponse({ description: 'COLOR_NOT_CANDIDATE' })
  choose(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
    @Body() input: ChooseColorDto,
  ): Promise<TwinDto> {
    return this.twinsService.choose(user.id, id, input);
  }

  @Post(':id/posts')
  @ApiOperation({ summary: '내 트윈 표지 올리기(명시적 업로드)' })
  @ApiCreatedResponse({ type: TwinDto })
  @ApiBadRequestResponse({ description: 'VALIDATION' })
  @ApiUnauthorizedResponse({ description: 'AUTH_REQUIRED 또는 TOKEN_EXPIRED' })
  @ApiNotFoundResponse({ description: 'NOT_FOUND' })
  @ApiConflictResponse({ description: 'MEDIA_NOT_READY 또는 TWIN_STATE' })
  post(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
    @Body() input: TwinPostDto,
  ): Promise<TwinDto> {
    return this.twinsService.post(user.id, id, input);
  }
}

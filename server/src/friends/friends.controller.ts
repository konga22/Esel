import {
  Body,
  Controller,
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
  ApiConflictResponse,
  ApiCreatedResponse,
  ApiForbiddenResponse,
  ApiNoContentResponse,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiOperation,
  ApiQuery,
  ApiTags,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import type { AuthUser } from '../auth/auth-user.js';
import { CurrentUser } from '../auth/current-user.decorator.js';
import { FriendPageDto } from './dto/friend-page.dto.js';
import { FriendDto } from './dto/friend.dto.js';
import { FriendRequestCreateDto } from './dto/friend-request-create.dto.js';
import { FriendRequestPageDto } from './dto/friend-request-page.dto.js';
import { FriendRequestDto } from './dto/friend-request.dto.js';
import { FriendsService } from './friends.service.js';

@ApiTags('friends')
@ApiBearerAuth()
@Controller('friends')
export class FriendsController {
  constructor(private readonly friendsService: FriendsService) {}

  @Get()
  @ApiOperation({ summary: '내 친구 목록' })
  @ApiQuery({ name: 'cursor', required: false })
  @ApiOkResponse({ type: FriendPageDto })
  @ApiUnauthorizedResponse({ description: 'AUTH_REQUIRED 또는 TOKEN_EXPIRED' })
  list(
    @CurrentUser() user: AuthUser,
    @Query('cursor') cursor?: string,
  ): Promise<FriendPageDto> {
    return this.friendsService.list(user.id, cursor);
  }

  @Get('requests')
  @ApiOperation({ summary: '받은 친구 요청' })
  @ApiQuery({ name: 'cursor', required: false })
  @ApiOkResponse({ type: FriendRequestPageDto })
  @ApiUnauthorizedResponse({ description: 'AUTH_REQUIRED 또는 TOKEN_EXPIRED' })
  requests(
    @CurrentUser() user: AuthUser,
    @Query('cursor') cursor?: string,
  ): Promise<FriendRequestPageDto> {
    return this.friendsService.requests(user.id, cursor);
  }

  @Post('requests')
  @ApiOperation({ summary: '친구 요청 보내기' })
  @ApiCreatedResponse({ type: FriendRequestDto })
  @ApiBadRequestResponse({ description: 'VALIDATION' })
  @ApiUnauthorizedResponse({ description: 'AUTH_REQUIRED 또는 TOKEN_EXPIRED' })
  @ApiNotFoundResponse({ description: 'NOT_FOUND' })
  @ApiConflictResponse({ description: 'ALREADY_FRIENDS 또는 REQUEST_EXISTS' })
  request(
    @CurrentUser() user: AuthUser,
    @Body() input: FriendRequestCreateDto,
  ): Promise<FriendRequestDto> {
    return this.friendsService.request(user.id, input);
  }

  @Post('requests/:id/accept')
  @ApiOperation({ summary: '받은 요청 수락' })
  @ApiCreatedResponse({ type: FriendDto })
  @ApiUnauthorizedResponse({ description: 'AUTH_REQUIRED 또는 TOKEN_EXPIRED' })
  @ApiForbiddenResponse({ description: 'FORBIDDEN' })
  @ApiNotFoundResponse({ description: 'NOT_FOUND' })
  accept(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
  ): Promise<FriendDto> {
    return this.friendsService.accept(user.id, id);
  }

  @Post('requests/:id/decline')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: '받은 요청 나중에(거절)' })
  @ApiNoContentResponse()
  @ApiUnauthorizedResponse({ description: 'AUTH_REQUIRED 또는 TOKEN_EXPIRED' })
  @ApiForbiddenResponse({ description: 'FORBIDDEN' })
  @ApiNotFoundResponse({ description: 'NOT_FOUND' })
  decline(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
  ): Promise<void> {
    return this.friendsService.decline(user.id, id);
  }
}

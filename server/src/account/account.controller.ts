import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Patch,
  Put,
} from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
  ApiUnauthorizedResponse,
  ApiConflictResponse,
  ApiNoContentResponse,
  ApiUnprocessableEntityResponse,
} from '@nestjs/swagger';
import type { AuthUser } from '../auth/auth-user.js';
import { CurrentUser } from '../auth/current-user.decorator.js';
import { AccountService } from './account.service.js';
import { NotificationSettingsDto } from './dto/notification-settings.dto.js';
import { DeleteAccountDto } from './dto/delete-account.dto.js';
import { UpdateProfileDto } from './dto/update-profile.dto.js';
import { ProfileOwnerDto } from '../profile/dto/profile-owner.dto.js';

@ApiTags('account')
@ApiBearerAuth()
@Controller('me')
export class AccountController {
  constructor(private readonly accountService: AccountService) {}

  @Patch('profile')
  @ApiOperation({ summary: '제호·소개 바꾸기' })
  @ApiOkResponse({ type: ProfileOwnerDto })
  @ApiBadRequestResponse({ description: 'VALIDATION' })
  @ApiUnauthorizedResponse({ description: 'AUTH_REQUIRED 또는 TOKEN_EXPIRED' })
  @ApiConflictResponse({ description: 'MASTHEAD_TAKEN' })
  @ApiUnprocessableEntityResponse({ description: 'MASTHEAD_INVALID' })
  updateProfile(
    @CurrentUser() user: AuthUser,
    @Body() input: UpdateProfileDto,
  ): Promise<ProfileOwnerDto> {
    return this.accountService.updateProfile(user.id, input);
  }

  @Get('notifications')
  @ApiOperation({ summary: '알림 설정 보기' })
  @ApiOkResponse({ type: NotificationSettingsDto })
  @ApiUnauthorizedResponse({ description: 'AUTH_REQUIRED 또는 TOKEN_EXPIRED' })
  notifications(
    @CurrentUser() user: AuthUser,
  ): Promise<NotificationSettingsDto> {
    return this.accountService.notifications(user.id);
  }

  @Put('notifications')
  @ApiOperation({ summary: '알림 설정 바꾸기' })
  @ApiOkResponse({ type: NotificationSettingsDto })
  @ApiBadRequestResponse({ description: 'VALIDATION' })
  @ApiUnauthorizedResponse({ description: 'AUTH_REQUIRED 또는 TOKEN_EXPIRED' })
  setNotifications(
    @CurrentUser() user: AuthUser,
    @Body() input: NotificationSettingsDto,
  ): Promise<NotificationSettingsDto> {
    return this.accountService.setNotifications(user.id, input);
  }

  @Delete()
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: '탈퇴(삭제 내용 확인 후)' })
  @ApiNoContentResponse()
  @ApiBadRequestResponse({ description: 'VALIDATION' })
  @ApiUnauthorizedResponse({ description: 'AUTH_REQUIRED 또는 TOKEN_EXPIRED' })
  async deleteAccount(
    @CurrentUser() user: AuthUser,
    @Body() input: DeleteAccountDto,
  ): Promise<void> {
    await this.accountService.deleteAccount(user.id, input);
  }
}

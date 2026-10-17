import { Body, Controller, Get, Put } from '@nestjs/common';
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
import { AccountService } from './account.service.js';
import { NotificationSettingsDto } from './dto/notification-settings.dto.js';

@ApiTags('account')
@ApiBearerAuth()
@Controller('me/notifications')
export class AccountController {
  constructor(private readonly accountService: AccountService) {}

  @Get()
  @ApiOperation({ summary: '알림 설정 보기' })
  @ApiOkResponse({ type: NotificationSettingsDto })
  @ApiUnauthorizedResponse({ description: 'AUTH_REQUIRED 또는 TOKEN_EXPIRED' })
  notifications(
    @CurrentUser() user: AuthUser,
  ): Promise<NotificationSettingsDto> {
    return this.accountService.notifications(user.id);
  }

  @Put()
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
}

import { Body, Controller, HttpCode, Post } from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiConflictResponse,
  ApiCreatedResponse,
  ApiNoContentResponse,
  ApiOperation,
  ApiTags,
  ApiTooManyRequestsResponse,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import { Public } from '../common/public.decorator.js';
import { AuthService } from './auth.service.js';
import type { AuthUser } from './auth-user.js';
import { CurrentUser } from './current-user.decorator.js';
import { IgnoreAccessToken } from './ignore-access-token.decorator.js';
import { EmailLoginDto } from './dto/email-login.dto.js';
import { EmailSignupDto } from './dto/email-signup.dto.js';
import { RefreshDto } from './dto/refresh.dto.js';
import { SessionDto } from './dto/session.dto.js';

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Public()
  @IgnoreAccessToken()
  @Post('email/signup')
  @ApiOperation({ summary: '이메일로 가입' })
  @ApiCreatedResponse({ type: SessionDto })
  @ApiBadRequestResponse({ description: 'VALIDATION' })
  @ApiConflictResponse({ description: 'EMAIL_TAKEN' })
  @ApiTooManyRequestsResponse({ description: 'RATE_LIMITED' })
  signup(@Body() input: EmailSignupDto): Promise<SessionDto> {
    return this.authService.signup(input);
  }

  @Public()
  @IgnoreAccessToken()
  @Post('email/login')
  @ApiOperation({ summary: '이메일로 로그인' })
  @ApiCreatedResponse({ type: SessionDto })
  @ApiBadRequestResponse({ description: 'VALIDATION' })
  @ApiUnauthorizedResponse({ description: 'WRONG_CREDENTIALS' })
  @ApiTooManyRequestsResponse({ description: 'RATE_LIMITED' })
  login(@Body() input: EmailLoginDto): Promise<SessionDto> {
    return this.authService.login(input);
  }

  @Public()
  @IgnoreAccessToken()
  @Post('refresh')
  @ApiOperation({ summary: 'refresh token을 회전해 새 토큰 받기' })
  @ApiCreatedResponse({ type: SessionDto })
  @ApiBadRequestResponse({ description: 'VALIDATION' })
  @ApiUnauthorizedResponse({
    description: 'AUTH_REQUIRED 또는 TOKEN_EXPIRED',
  })
  refresh(@Body() input: RefreshDto): Promise<SessionDto> {
    return this.authService.refresh(input);
  }

  @Post('logout')
  @HttpCode(204)
  @ApiBearerAuth()
  @ApiOperation({ summary: '이 기기의 로그인 끝내기' })
  @ApiNoContentResponse()
  @ApiUnauthorizedResponse({
    description: 'AUTH_REQUIRED 또는 TOKEN_EXPIRED',
  })
  logout(@CurrentUser() user: AuthUser): Promise<void> {
    return this.authService.logout(user.sessionId);
  }
}

import { Body, Controller, Post } from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiConflictResponse,
  ApiCreatedResponse,
  ApiOperation,
  ApiTags,
  ApiTooManyRequestsResponse,
} from '@nestjs/swagger';
import { Public } from '../common/public.decorator.js';
import { AuthService } from './auth.service.js';
import { EmailSignupDto } from './dto/email-signup.dto.js';
import { SessionDto } from './dto/session.dto.js';

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Public()
  @Post('email/signup')
  @ApiOperation({ summary: '이메일로 가입' })
  @ApiCreatedResponse({ type: SessionDto })
  @ApiBadRequestResponse({ description: 'VALIDATION' })
  @ApiConflictResponse({ description: 'EMAIL_TAKEN' })
  @ApiTooManyRequestsResponse({ description: 'RATE_LIMITED' })
  signup(@Body() input: EmailSignupDto): Promise<SessionDto> {
    return this.authService.signup(input);
  }
}

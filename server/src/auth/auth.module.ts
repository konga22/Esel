import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { AccessTokenGuard } from './access-token.guard.js';
import { AuthController } from './auth.controller.js';
import { AuthService } from './auth.service.js';
import { LoginRateLimiter } from './login-rate-limiter.js';
import { SignupRateLimiter } from './signup-rate-limiter.js';

@Module({
  controllers: [AuthController],
  providers: [
    AuthService,
    SignupRateLimiter,
    LoginRateLimiter,
    { provide: APP_GUARD, useClass: AccessTokenGuard },
  ],
})
export class AuthModule {}

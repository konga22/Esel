import { Module } from '@nestjs/common';
import { AuthController } from './auth.controller.js';
import { AuthService } from './auth.service.js';
import { SignupRateLimiter } from './signup-rate-limiter.js';

@Module({
  controllers: [AuthController],
  providers: [AuthService, SignupRateLimiter],
})
export class AuthModule {}

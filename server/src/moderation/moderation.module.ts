import { Module } from '@nestjs/common';
import { IssuesModule } from '../issues/issues.module.js';
import { MediaModule } from '../media/media.module.js';
import { ModerationController } from './moderation.controller.js';
import { ModerationService } from './moderation.service.js';
import { ReportRateLimiter } from './report-rate-limiter.js';

@Module({
  imports: [IssuesModule, MediaModule],
  controllers: [ModerationController],
  providers: [ModerationService, ReportRateLimiter],
})
export class ModerationModule {}

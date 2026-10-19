import { Module } from '@nestjs/common';
import { IssuesController } from './issues.controller.js';
import { IssuesService } from './issues.service.js';
import { ReaderLineRateLimiter } from './reader-line-rate-limiter.js';
import { TodayModule } from '../today/today.module.js';

@Module({
  imports: [TodayModule],
  controllers: [IssuesController],
  providers: [IssuesService, ReaderLineRateLimiter],
  exports: [IssuesService],
})
export class IssuesModule {}

import { Module } from '@nestjs/common';
import { IssuesModule } from '../issues/issues.module.js';
import { FeedController } from './feed.controller.js';
import { FeedService } from './feed.service.js';

@Module({
  imports: [IssuesModule],
  controllers: [FeedController],
  providers: [FeedService],
})
export class FeedModule {}

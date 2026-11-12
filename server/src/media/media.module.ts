import { Module } from '@nestjs/common';
import { IssuesModule } from '../issues/issues.module.js';
import { MediaCleanupScheduler } from './media-cleanup.scheduler.js';
import { MediaController } from './media.controller.js';
import { MediaService } from './media.service.js';

@Module({
  imports: [IssuesModule],
  controllers: [MediaController],
  providers: [MediaService, MediaCleanupScheduler],
  exports: [MediaService],
})
export class MediaModule {}

import { Module } from '@nestjs/common';
import { IssuesModule } from '../issues/issues.module.js';
import { ShareController } from './share.controller.js';
import { ShareService } from './share.service.js';

@Module({
  imports: [IssuesModule],
  controllers: [ShareController],
  providers: [ShareService],
})
export class ShareModule {}

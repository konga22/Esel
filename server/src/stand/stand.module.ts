import { Module } from '@nestjs/common';
import { IssuesModule } from '../issues/issues.module.js';
import { StandController } from './stand.controller.js';
import { StandService } from './stand.service.js';

@Module({
  imports: [IssuesModule],
  controllers: [StandController],
  providers: [StandService],
})
export class StandModule {}

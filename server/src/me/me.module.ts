import { Module } from '@nestjs/common';
import { IssuesModule } from '../issues/issues.module.js';
import { MeController } from './me.controller.js';
import { MeService } from './me.service.js';

@Module({
  imports: [IssuesModule],
  controllers: [MeController],
  providers: [MeService],
})
export class MeModule {}

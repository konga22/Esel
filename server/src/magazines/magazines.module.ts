import { Module } from '@nestjs/common';
import { IssuesModule } from '../issues/issues.module.js';
import { MagazinesController } from './magazines.controller.js';
import { MagazinesService } from './magazines.service.js';

@Module({
  imports: [IssuesModule],
  controllers: [MagazinesController],
  providers: [MagazinesService],
})
export class MagazinesModule {}

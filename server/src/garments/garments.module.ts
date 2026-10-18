import { Module } from '@nestjs/common';
import { GarmentsController } from './garments.controller.js';
import { GarmentsService } from './garments.service.js';

@Module({
  controllers: [GarmentsController],
  providers: [GarmentsService],
})
export class GarmentsModule {}

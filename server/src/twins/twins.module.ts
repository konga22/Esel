import { Module } from '@nestjs/common';
import { TwinsController } from './twins.controller.js';
import { TwinsService } from './twins.service.js';

@Module({
  controllers: [TwinsController],
  providers: [TwinsService],
})
export class TwinsModule {}

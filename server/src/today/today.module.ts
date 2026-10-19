import { Module } from '@nestjs/common';
import { TodayController } from './today.controller.js';
import { TodayService } from './today.service.js';
import { TodayCoverSelector } from './today-cover.selector.js';

@Module({
  controllers: [TodayController],
  providers: [TodayService, TodayCoverSelector],
  exports: [TodayCoverSelector],
})
export class TodayModule {}

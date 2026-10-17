import { Module } from '@nestjs/common';
import { ProfileController } from './profile.controller.js';
import { ProfileCreationController } from './profile-creation.controller.js';
import { ProfileService } from './profile.service.js';

@Module({
  controllers: [ProfileController, ProfileCreationController],
  providers: [ProfileService],
})
export class ProfileModule {}

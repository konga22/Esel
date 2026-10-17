import { Body, Controller, Post } from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiConflictResponse,
  ApiCreatedResponse,
  ApiOperation,
  ApiTags,
  ApiUnauthorizedResponse,
  ApiUnprocessableEntityResponse,
} from '@nestjs/swagger';
import type { AuthUser } from '../auth/auth-user.js';
import { CurrentUser } from '../auth/current-user.decorator.js';
import { CreateProfileDto } from './dto/create-profile.dto.js';
import { ProfileOwnerDto } from './dto/profile-owner.dto.js';
import { ProfileService } from './profile.service.js';

@ApiTags('profile')
@ApiBearerAuth()
@Controller('profile')
export class ProfileCreationController {
  constructor(private readonly profileService: ProfileService) {}

  @Post()
  @ApiOperation({ summary: '제호를 정해 내 잡지 만들기(창간)' })
  @ApiCreatedResponse({ type: ProfileOwnerDto })
  @ApiBadRequestResponse({ description: 'VALIDATION' })
  @ApiUnauthorizedResponse({ description: 'AUTH_REQUIRED 또는 TOKEN_EXPIRED' })
  @ApiConflictResponse({ description: 'MASTHEAD_TAKEN 또는 PROFILE_EXISTS' })
  @ApiUnprocessableEntityResponse({ description: 'MASTHEAD_INVALID' })
  create(
    @CurrentUser() user: AuthUser,
    @Body() input: CreateProfileDto,
  ): Promise<ProfileOwnerDto> {
    return this.profileService.create(user.id, input);
  }
}

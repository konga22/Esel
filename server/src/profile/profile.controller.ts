import { Controller, Get, Param } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOkResponse,
  ApiOperation,
  ApiParam,
  ApiTags,
  ApiUnauthorizedResponse,
  ApiUnprocessableEntityResponse,
} from '@nestjs/swagger';
import { MastheadAvailabilityDto } from './dto/masthead-availability.dto.js';
import { ProfileService } from './profile.service.js';

@ApiTags('profile')
@ApiBearerAuth()
@Controller('mastheads')
export class ProfileController {
  constructor(private readonly profileService: ProfileService) {}

  @Get(':name/availability')
  @ApiOperation({ summary: '제호(영문 닉네임)를 쓸 수 있는지 확인' })
  @ApiParam({
    name: 'name',
    example: 'selin',
    schema: { type: 'string', pattern: '^[a-z]{2,10}$' },
  })
  @ApiOkResponse({ type: MastheadAvailabilityDto })
  @ApiUnauthorizedResponse({ description: 'AUTH_REQUIRED 또는 TOKEN_EXPIRED' })
  @ApiUnprocessableEntityResponse({ description: 'MASTHEAD_INVALID' })
  availability(@Param('name') name: string): Promise<MastheadAvailabilityDto> {
    return this.profileService.mastheadAvailability(name);
  }
}

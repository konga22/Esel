import { Controller, Get, Query } from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import type { AuthUser } from '../auth/auth-user.js';
import { CurrentUser } from '../auth/current-user.decorator.js';
import { GarmentPageDto } from './dto/garment-page.dto.js';
import { GarmentQueryDto } from './dto/garment-query.dto.js';
import { GarmentsService } from './garments.service.js';

@ApiTags('garments')
@ApiBearerAuth()
@Controller('me/garments')
export class GarmentsController {
  constructor(private readonly garmentsService: GarmentsService) {}

  @Get()
  @ApiOperation({ summary: '내 옷 목록' })
  @ApiOkResponse({ type: GarmentPageDto })
  @ApiBadRequestResponse({ description: 'VALIDATION' })
  @ApiUnauthorizedResponse({ description: 'AUTH_REQUIRED 또는 TOKEN_EXPIRED' })
  mine(
    @CurrentUser() user: AuthUser,
    @Query() query: GarmentQueryDto,
  ): Promise<GarmentPageDto> {
    return this.garmentsService.mine(user.id, query.cursor);
  }
}

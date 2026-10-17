import { Controller, Get, Param } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import { UserPublicDto } from './dto/user-public.dto.js';
import { UsersService } from './users.service.js';

@ApiTags('users')
@ApiBearerAuth()
@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get(':masthead')
  @ApiOperation({ summary: '제호로 사용자 찾기' })
  @ApiOkResponse({ type: UserPublicDto })
  @ApiUnauthorizedResponse({ description: 'AUTH_REQUIRED 또는 TOKEN_EXPIRED' })
  @ApiNotFoundResponse({ description: 'NOT_FOUND' })
  get(@Param('masthead') masthead: string): Promise<UserPublicDto> {
    return this.usersService.get(masthead);
  }
}

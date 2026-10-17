import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Query,
} from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiCreatedResponse,
  ApiExtraModels,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiOperation,
  ApiQuery,
  ApiTags,
  ApiTooManyRequestsResponse,
  ApiUnauthorizedResponse,
  getSchemaPath,
} from '@nestjs/swagger';
import type { AuthUser } from '../auth/auth-user.js';
import { CurrentUser } from '../auth/current-user.decorator.js';
import { IssueOwnerDto } from './dto/issue-owner.dto.js';
import { IssuePublicDto } from './dto/issue-public.dto.js';
import { AddLineDto } from './dto/add-line.dto.js';
import { ReaderLinePageDto } from './dto/reader-line-page.dto.js';
import { ReaderLinePublicDto } from './dto/reader-line-public.dto.js';
import { ReactionStateDto } from './dto/reaction-state.dto.js';
import { IssuesService } from './issues.service.js';

@ApiTags('issues')
@ApiBearerAuth()
@ApiExtraModels(IssuePublicDto, IssueOwnerDto)
@Controller('issues')
export class IssuesController {
  constructor(private readonly issuesService: IssuesService) {}

  @Get(':id')
  @ApiOperation({ summary: '표지 펼쳐 보기(주인이면 숫자 포함)' })
  @ApiOkResponse({
    schema: {
      oneOf: [
        { $ref: getSchemaPath(IssuePublicDto) },
        { $ref: getSchemaPath(IssueOwnerDto) },
      ],
    },
  })
  @ApiUnauthorizedResponse({ description: 'AUTH_REQUIRED 또는 TOKEN_EXPIRED' })
  @ApiNotFoundResponse({ description: 'NOT_FOUND' })
  get(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
  ): Promise<IssuePublicDto | IssueOwnerDto> {
    return this.issuesService.get(user.id, id);
  }

  @Post(':id/like')
  @ApiOperation({ summary: '좋아요(두 번 보내도 한 번)' })
  @ApiCreatedResponse({ type: ReactionStateDto })
  @ApiUnauthorizedResponse({ description: 'AUTH_REQUIRED 또는 TOKEN_EXPIRED' })
  @ApiNotFoundResponse({ description: 'NOT_FOUND' })
  like(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
  ): Promise<ReactionStateDto> {
    return this.issuesService.like(user.id, id);
  }

  @Delete(':id/like')
  @ApiOperation({ summary: '좋아요 취소' })
  @ApiOkResponse({ type: ReactionStateDto })
  @ApiUnauthorizedResponse({ description: 'AUTH_REQUIRED 또는 TOKEN_EXPIRED' })
  @ApiNotFoundResponse({ description: 'NOT_FOUND' })
  unlike(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
  ): Promise<ReactionStateDto> {
    return this.issuesService.unlike(user.id, id);
  }

  @Post(':id/scrap')
  @ApiOperation({ summary: '스크랩' })
  @ApiCreatedResponse({ type: ReactionStateDto })
  @ApiUnauthorizedResponse({ description: 'AUTH_REQUIRED 또는 TOKEN_EXPIRED' })
  @ApiNotFoundResponse({ description: 'NOT_FOUND' })
  scrap(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
  ): Promise<ReactionStateDto> {
    return this.issuesService.scrap(user.id, id);
  }

  @Delete(':id/scrap')
  @ApiOperation({ summary: '스크랩 취소' })
  @ApiOkResponse({ type: ReactionStateDto })
  @ApiUnauthorizedResponse({ description: 'AUTH_REQUIRED 또는 TOKEN_EXPIRED' })
  @ApiNotFoundResponse({ description: 'NOT_FOUND' })
  unscrap(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
  ): Promise<ReactionStateDto> {
    return this.issuesService.unscrap(user.id, id);
  }

  @Get(':id/lines')
  @ApiOperation({ summary: '독자 한 줄 목록(개수 없이 cursor로)' })
  @ApiQuery({ name: 'cursor', required: false })
  @ApiOkResponse({ type: ReaderLinePageDto })
  @ApiUnauthorizedResponse({ description: 'AUTH_REQUIRED 또는 TOKEN_EXPIRED' })
  @ApiNotFoundResponse({ description: 'NOT_FOUND' })
  lines(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
    @Query('cursor') cursor?: string,
  ): Promise<ReaderLinePageDto> {
    return this.issuesService.lines(user.id, id, cursor);
  }

  @Post(':id/lines')
  @ApiOperation({ summary: '독자 한 줄 남기기(60자 이내)' })
  @ApiCreatedResponse({ type: ReaderLinePublicDto })
  @ApiBadRequestResponse({ description: 'VALIDATION' })
  @ApiUnauthorizedResponse({ description: 'AUTH_REQUIRED 또는 TOKEN_EXPIRED' })
  @ApiNotFoundResponse({ description: 'NOT_FOUND' })
  @ApiTooManyRequestsResponse({ description: 'RATE_LIMITED' })
  addLine(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
    @Body() input: AddLineDto,
  ): Promise<ReaderLinePublicDto> {
    return this.issuesService.addLine(user.id, id, input);
  }
}

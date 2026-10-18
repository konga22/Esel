import { ApiProperty } from '@nestjs/swagger';
import { PageDto } from '../../common/page.dto.js';
import { FeedItemDto } from './feed-item.dto.js';

export class FeedPageDto extends PageDto<FeedItemDto> {
  @ApiProperty({ type: FeedItemDto, isArray: true })
  declare items: FeedItemDto[];
}

import { ApiProperty } from '@nestjs/swagger';
import { PageDto } from '../../common/page.dto.js';
import { FriendDto } from './friend.dto.js';

export class FriendPageDto extends PageDto<FriendDto> {
  @ApiProperty({ type: FriendDto, isArray: true })
  declare items: FriendDto[];
}

import { ApiProperty } from '@nestjs/swagger';
import { PageDto } from '../../common/page.dto.js';
import { FriendRequestDto } from './friend-request.dto.js';

export class FriendRequestPageDto extends PageDto<FriendRequestDto> {
  @ApiProperty({ type: FriendRequestDto, isArray: true })
  declare items: FriendRequestDto[];
}

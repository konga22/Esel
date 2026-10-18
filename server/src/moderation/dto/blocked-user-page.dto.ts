import { ApiProperty } from '@nestjs/swagger';
import { PageDto } from '../../common/page.dto.js';
import { BlockedUserDto } from './blocked-user.dto.js';

export class BlockedUserPageDto extends PageDto<BlockedUserDto> {
  @ApiProperty({ type: BlockedUserDto, isArray: true })
  declare items: BlockedUserDto[];
}

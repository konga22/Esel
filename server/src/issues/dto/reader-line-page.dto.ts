import { ApiProperty } from '@nestjs/swagger';
import { PageDto } from '../../common/page.dto.js';
import { ReaderLinePublicDto } from './reader-line-public.dto.js';

export class ReaderLinePageDto extends PageDto<ReaderLinePublicDto> {
  @ApiProperty({ type: ReaderLinePublicDto, isArray: true })
  declare items: ReaderLinePublicDto[];
}

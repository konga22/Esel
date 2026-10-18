import { ApiProperty } from '@nestjs/swagger';
import { PageDto } from '../../common/page.dto.js';
import { IssuePublicDto } from '../../issues/dto/issue-public.dto.js';

export class ScrapPageDto extends PageDto<IssuePublicDto> {
  @ApiProperty({ type: IssuePublicDto, isArray: true })
  declare items: IssuePublicDto[];
}

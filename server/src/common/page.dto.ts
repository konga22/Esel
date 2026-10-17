import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class PageDto<T> {
  @ApiProperty({ isArray: true })
  items: T[];

  @ApiPropertyOptional({ nullable: true, type: String })
  nextCursor: string | null;
}

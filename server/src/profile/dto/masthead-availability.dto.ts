import { ApiProperty } from '@nestjs/swagger';

export class MastheadAvailabilityDto {
  @ApiProperty({ example: 'selin', pattern: '^[a-z]{2,10}$' })
  masthead: string;

  @ApiProperty()
  available: boolean;
}

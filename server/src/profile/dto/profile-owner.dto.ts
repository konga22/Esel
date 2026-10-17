import { ApiProperty } from '@nestjs/swagger';

export class ProfileOwnerDto {
  @ApiProperty({ format: 'uuid' })
  id: string;

  @ApiProperty({ example: 'selin', pattern: '^[a-z]{2,10}$' })
  masthead: string;

  @ApiProperty({ minimum: 0 })
  issueCount: number;
}

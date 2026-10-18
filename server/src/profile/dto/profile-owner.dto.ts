import { ApiProperty } from '@nestjs/swagger';

export class ProfileOwnerDto {
  @ApiProperty({ format: 'uuid' })
  id: string;

  @ApiProperty({ example: 'selin', pattern: '^[a-z]{2,10}$' })
  masthead: string;

  @ApiProperty({ example: '옷으로 남기는 나의 계절.', maxLength: 80 })
  bio: string;

  @ApiProperty({ minimum: 0 })
  issueCount: number;
}

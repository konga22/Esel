import { ApiProperty } from '@nestjs/swagger';

export class UserPublicDto {
  @ApiProperty({ example: 'selin' })
  masthead: string;

  @ApiProperty({ minimum: 0, description: '발행한 공개 호수' })
  issueCount: number;
}

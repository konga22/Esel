import { ApiProperty } from '@nestjs/swagger';
import { Equals } from 'class-validator';

export class DeleteAccountDto {
  @ApiProperty({ example: true, description: '삭제 내용을 확인했을 때만 true' })
  @Equals(true)
  confirmed: boolean;
}

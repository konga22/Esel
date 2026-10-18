import { ApiProperty } from '@nestjs/swagger';
import { IsEnum } from 'class-validator';

export enum TwinVisibilityInput {
  PRIVATE = 'private',
  SOLO = 'solo',
  JOINT = 'joint',
}

export class TwinVisibilityDto {
  @ApiProperty({
    enum: TwinVisibilityInput,
    example: TwinVisibilityInput.JOINT,
  })
  @IsEnum(TwinVisibilityInput)
  visibility: TwinVisibilityInput;
}

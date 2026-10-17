import { ApiProperty } from '@nestjs/swagger';

export class SubscriptionStateDto {
  @ApiProperty()
  subscribed: boolean;
}

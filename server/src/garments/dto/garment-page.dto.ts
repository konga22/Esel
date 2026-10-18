import { ApiProperty } from '@nestjs/swagger';
import { PageDto } from '../../common/page.dto.js';
import { GarmentOwnerDto } from './garment-owner.dto.js';

export class GarmentPageDto extends PageDto<GarmentOwnerDto> {
  @ApiProperty({ type: GarmentOwnerDto, isArray: true })
  declare items: GarmentOwnerDto[];
}

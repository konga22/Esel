import { ApiProperty } from '@nestjs/swagger';
import { PageDto } from '../../common/page.dto.js';
import { PaletteTileDto } from './palette-tile.dto.js';

export class PalettePageDto extends PageDto<PaletteTileDto> {
  @ApiProperty({ type: PaletteTileDto, isArray: true })
  declare items: PaletteTileDto[];
}

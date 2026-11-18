import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  Put,
  Req,
  UseGuards,
} from '@nestjs/common';
import {
  JwtAuthGuard,
  type AuthenticatedRequest,
} from '../auth/jwt-auth.guard.js';
import { CatsService } from './cats.service.js';
import {
  addCatPhotoSchema,
  createCatSchema,
  updateCatSchema,
  type AddCatPhotoDto,
  type CreateCatDto,
  type UpdateCatDto,
} from './cats.schemas.js';

@Controller('cats')
@UseGuards(JwtAuthGuard)
export class CatsController {
  constructor(private readonly cats: CatsService) {}

  @Get()
  listMyCats(@Req() req: AuthenticatedRequest) {
    return this.cats.listMyCats(req.user.id);
  }

  @Post()
  createCat(
    @Req() req: AuthenticatedRequest,
    @Body({ schema: createCatSchema }) body: CreateCatDto,
  ) {
    return this.cats.createCat(req.user.id, body);
  }

  @Put(':id')
  updateCat(
    @Req() req: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) catId: string,
    @Body({ schema: updateCatSchema }) body: UpdateCatDto,
  ) {
    return this.cats.updateCat(req.user.id, catId, body);
  }

  @Delete(':id')
  deleteCat(
    @Req() req: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) catId: string,
  ) {
    return this.cats.deleteCat(req.user.id, catId);
  }

  @Post(':id/photos')
  addPhoto(
    @Req() req: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) catId: string,
    @Body({ schema: addCatPhotoSchema }) body: AddCatPhotoDto,
  ) {
    return this.cats.addPhoto(req.user.id, catId, body);
  }
}

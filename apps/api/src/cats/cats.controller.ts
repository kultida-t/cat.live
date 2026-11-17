import { Controller, Get, Req, UseGuards } from '@nestjs/common';
import {
  JwtAuthGuard,
  type AuthenticatedRequest,
} from '../auth/jwt-auth.guard.js';
import { CatsService } from './cats.service.js';

@Controller('cats')
@UseGuards(JwtAuthGuard)
export class CatsController {
  constructor(private readonly cats: CatsService) {}

  @Get()
  listMyCats(@Req() req: AuthenticatedRequest) {
    return this.cats.listMyCats(req.user.id);
  }
}

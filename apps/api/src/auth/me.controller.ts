import { Body, Controller, Put, Req, UseGuards } from '@nestjs/common';
import { AuthService } from './auth.service.js';
import {
  updateProfileSchema,
  type UpdateProfileDto,
} from './auth.schemas.js';
import { JwtAuthGuard, type AuthenticatedRequest } from './jwt-auth.guard.js';

/** route กลุ่ม /me — ข้อมูลเจ้าของบัญชีที่ล็อกอินอยู่เท่านั้น */
@Controller('me')
export class MeController {
  constructor(private readonly auth: AuthService) {}

  @Put('profile')
  @UseGuards(JwtAuthGuard)
  updateProfile(
    @Req() req: AuthenticatedRequest,
    @Body({ schema: updateProfileSchema }) body: UpdateProfileDto,
  ) {
    return this.auth.updateProfile(req.user.id, body);
  }
}

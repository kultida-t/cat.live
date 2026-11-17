import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import { AuthService } from './auth.service.js';
import {
  otpRequestSchema,
  otpVerifySchema,
  pinChangeSchema,
  pinLoginSchema,
  pinSetSchema,
  refreshSchema,
  type OtpRequestDto,
  type OtpVerifyDto,
  type PinChangeDto,
  type PinLoginDto,
  type PinSetDto,
  type RefreshDto,
} from './auth.schemas.js';
import { JwtAuthGuard, type AuthenticatedRequest } from './jwt-auth.guard.js';

@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Post('otp/request')
  requestOtp(@Body({ schema: otpRequestSchema }) body: OtpRequestDto) {
    return this.auth.requestOtp(body);
  }

  @Post('otp/verify')
  verifyOtp(@Body({ schema: otpVerifySchema }) body: OtpVerifyDto) {
    return this.auth.verifyOtp(body);
  }

  @Post('pin/login')
  @HttpCode(HttpStatus.OK)
  pinLogin(@Body({ schema: pinLoginSchema }) body: PinLoginDto) {
    return this.auth.pinLogin(body);
  }

  @Post('pin')
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.NO_CONTENT)
  async setPin(
    @Req() req: AuthenticatedRequest,
    @Body({ schema: pinSetSchema }) body: PinSetDto,
  ) {
    await this.auth.setPin(req.user.id, body.pin);
  }

  @Post('pin/change')
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.NO_CONTENT)
  async changePin(
    @Req() req: AuthenticatedRequest,
    @Body({ schema: pinChangeSchema }) body: PinChangeDto,
  ) {
    await this.auth.changePin(req.user.id, body);
  }

  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  refresh(@Body({ schema: refreshSchema }) body: RefreshDto) {
    return this.auth.refresh(body.refreshToken);
  }

  @Post('logout')
  @HttpCode(HttpStatus.NO_CONTENT)
  async logout(@Body({ schema: refreshSchema }) body: RefreshDto) {
    await this.auth.logout(body.refreshToken);
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  me(@Req() req: AuthenticatedRequest) {
    return this.auth.me(req.user.id);
  }
}

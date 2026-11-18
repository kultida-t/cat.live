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
import { Throttle } from '@nestjs/throttler';
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

  // ขอ OTP มีค่าส่ง SMS — จำกัดต่อ IP แยกจาก cooldown ต่อเบอร์ที่อยู่ใน service
  @Post('otp/request')
  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  requestOtp(@Body({ schema: otpRequestSchema }) body: OtpRequestDto) {
    return this.auth.requestOtp(body);
  }

  @Post('otp/verify')
  @Throttle({ default: { limit: 30, ttl: 60_000 } })
  verifyOtp(@Body({ schema: otpVerifySchema }) body: OtpVerifyDto) {
    return this.auth.verifyOtp(body);
  }

  @Post('pin/login')
  @HttpCode(HttpStatus.OK)
  @Throttle({ default: { limit: 15, ttl: 60_000 } })
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

  @Get('pin/status')
  @UseGuards(JwtAuthGuard)
  async pinStatus(@Req() req: AuthenticatedRequest) {
    return { hasPin: await this.auth.hasPin(req.user.id) };
  }

  @Post('pin/verify')
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.NO_CONTENT)
  async verifyPin(
    @Req() req: AuthenticatedRequest,
    @Body({ schema: pinSetSchema }) body: PinSetDto,
  ) {
    await this.auth.verifyPin(req.user.id, body.pin);
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
  @Throttle({ default: { limit: 60, ttl: 60_000 } })
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

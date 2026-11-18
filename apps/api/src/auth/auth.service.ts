import { HttpStatus, Inject, Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../prisma/prisma.service.js';
import { CLOCK, type Clock } from '../common/clock.js';
import { SMS_SENDER, type SmsSender } from '../sms/sms.js';
import {
  ACCESS_TOKEN_TTL_SECONDS,
  LOCK_DURATION_MS,
  OTP_MAX_ATTEMPTS,
  OTP_RESEND_COOLDOWN_MS,
  OTP_TTL_MS,
  PIN_LOCK_DURATION_MS,
  PIN_MAX_ATTEMPTS,
  REFRESH_TOKEN_TTL_MS,
  evaluateAge,
  maskThaiPhone,
  normalizeThaiPhone,
} from './auth-rules.js';
import { authError } from './auth.errors.js';
import type {
  OtpRequestDto,
  OtpVerifyDto,
  PinChangeDto,
  PinLoginDto,
  UpdateProfileDto,
} from './auth.schemas.js';
import {
  hashSecret,
  newOpaqueToken,
  newOtpCode,
  newRefCode,
  newSalt,
  sha256,
  verifySecret,
} from './secrets.js';

const DEFAULT_DISPLAY_NAME = 'ผู้ใช้แมว.live';

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
  user: {
    id: string;
    displayName: string;
    phoneMasked: string | null;
    birthYear: number | null;
  };
}

type PinResult = 'ok' | 'wrong' | 'locked';

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
    @Inject(CLOCK) private readonly now: Clock,
    @Inject(SMS_SENDER) private readonly sms: SmsSender,
  ) {}

  // ---------- OTP ----------

  async requestOtp({ phone: rawPhone }: OtpRequestDto) {
    const phone = normalizeThaiPhone(rawPhone);
    const now = this.now();
    const latest = await this.prisma.otpChallenge.findFirst({
      where: { phone },
      orderBy: { createdAt: 'desc' },
    });
    if (latest && latest.resendAvailableAt > now) {
      const waitSeconds = Math.ceil(
        (latest.resendAvailableAt.getTime() - now.getTime()) / 1000,
      );
      throw authError(HttpStatus.TOO_MANY_REQUESTS, 'otp_resend_wait', {
        waitSeconds,
      });
    }

    const code = newOtpCode();
    const refCode = newRefCode();
    const salt = newSalt();
    const challenge = await this.prisma.otpChallenge.create({
      data: {
        refCode,
        phone,
        salt,
        codeHash: await hashSecret(code, salt),
        expiresAt: new Date(now.getTime() + OTP_TTL_MS),
        resendAvailableAt: new Date(now.getTime() + OTP_RESEND_COOLDOWN_MS),
      },
    });
    await this.sms.sendOtp(phone, code, refCode);

    return {
      refCode,
      expiresAt: challenge.expiresAt,
      resendAvailableAt: challenge.resendAvailableAt,
      maskedPhone: maskThaiPhone(phone),
    };
  }

  async verifyOtp(dto: OtpVerifyDto): Promise<AuthTokens> {
    const now = this.now();
    const challenge = await this.prisma.otpChallenge.findUnique({
      where: { refCode: dto.refCode },
    });
    if (!challenge || challenge.consumedAt) {
      throw authError(HttpStatus.UNAUTHORIZED, 'otp_invalid', {
        remainingAttempts: 0,
      });
    }
    if (challenge.lockedUntil && now < challenge.lockedUntil) {
      throw this.lockedError('otp_locked', challenge.lockedUntil, now);
    }
    if (now >= challenge.expiresAt) {
      throw authError(HttpStatus.GONE, 'otp_expired');
    }

    const matched = await verifySecret(
      dto.code,
      challenge.salt,
      challenge.codeHash,
    );
    if (!matched) {
      const attemptsUsed = challenge.attemptsUsed + 1;
      const lockedUntil =
        attemptsUsed >= OTP_MAX_ATTEMPTS
          ? new Date(now.getTime() + LOCK_DURATION_MS)
          : null;
      await this.prisma.otpChallenge.update({
        where: { id: challenge.id },
        data: { attemptsUsed, lockedUntil },
      });
      if (lockedUntil) throw this.lockedError('otp_locked', lockedUntil, now);
      throw authError(HttpStatus.UNAUTHORIZED, 'otp_invalid', {
        remainingAttempts: OTP_MAX_ATTEMPTS - attemptsUsed,
      });
    }

    // ใช้รหัสได้ครั้งเดียว — updateMany กันการยิงซ้ำพร้อมกันให้ผ่านได้แค่ครั้งเดียว
    const consumed = await this.prisma.otpChallenge.updateMany({
      where: { id: challenge.id, consumedAt: null },
      data: { consumedAt: now },
    });
    if (consumed.count === 0) {
      throw authError(HttpStatus.UNAUTHORIZED, 'otp_invalid', {
        remainingAttempts: 0,
      });
    }

    const userId = await this.findOrCreateUser(challenge.phone, dto, now);
    // OTP ผ่านคือหลักฐานว่าเป็นเจ้าของเบอร์ → ปลดล็อก PIN ที่ค้างอยู่ (ตรงกับกติกาในแอป)
    await this.prisma.pinCredential.updateMany({
      where: { userId },
      data: { failedAttempts: 0, lockedUntil: null },
    });
    return this.issueTokens(userId);
  }

  private async findOrCreateUser(
    phone: string,
    dto: OtpVerifyDto,
    now: Date,
  ): Promise<string> {
    const existing = await this.prisma.userPrivate.findUnique({
      where: { phone },
    });
    if (existing) return existing.userId;

    const eligibility = evaluateAge(dto.birthYear, now.getFullYear());
    if (eligibility === 'under13Blocked') {
      throw authError(HttpStatus.FORBIDDEN, 'age_under_13');
    }
    if (
      eligibility === 'minorNeedsGuardianConsent' &&
      !dto.guardianConsentGranted
    ) {
      throw authError(HttpStatus.FORBIDDEN, 'guardian_consent_required');
    }

    const user = await this.prisma.user.create({
      data: {
        displayName: dto.displayName || DEFAULT_DISPLAY_NAME,
        method: 'phoneOtp',
        birthYear: dto.birthYear,
        guardianConsent: dto.guardianConsentGranted,
        private: { create: { phone } },
      },
    });
    return user.id;
  }

  // ---------- PIN ----------

  async pinLogin({ phone: rawPhone, pin }: PinLoginDto): Promise<AuthTokens> {
    const phone = normalizeThaiPhone(rawPhone);
    const owner = await this.prisma.userPrivate.findUnique({
      where: { phone },
    });
    const credential =
      owner &&
      (await this.prisma.pinCredential.findUnique({
        where: { userId: owner.userId },
      }));
    if (!owner || !credential) {
      throw authError(HttpStatus.NOT_FOUND, 'no_pin_for_phone');
    }

    const result = await this.checkPin(owner.userId, pin);
    if (result === 'locked') {
      const credNow = await this.prisma.pinCredential.findUniqueOrThrow({
        where: { userId: owner.userId },
      });
      throw this.lockedError('pin_locked', credNow.lockedUntil!, this.now());
    }
    if (result === 'wrong') {
      const after = await this.prisma.pinCredential.findUniqueOrThrow({
        where: { userId: owner.userId },
      });
      if (after.lockedUntil)
        throw this.lockedError('pin_locked', after.lockedUntil, this.now());
      throw authError(HttpStatus.UNAUTHORIZED, 'pin_invalid', {
        remainingAttempts: PIN_MAX_ATTEMPTS - after.failedAttempts,
      });
    }
    return this.issueTokens(owner.userId);
  }

  async hasPin(userId: string): Promise<boolean> {
    const cred = await this.prisma.pinCredential.findUnique({
      where: { userId },
    });
    return cred !== null;
  }

  /** ตรวจ PIN ของบัญชีที่ล็อกอินอยู่ (ใช้ก่อนเข้าขั้นเปลี่ยน PIN) — นับครั้งผิดและล็อกเหมือนหน้าเข้าสู่ระบบ */
  async verifyPin(userId: string, pin: string): Promise<void> {
    const result = await this.checkPin(userId, pin);
    const cred = await this.prisma.pinCredential.findUnique({
      where: { userId },
    });
    if (result === 'ok') return;
    if (result === 'locked' || cred?.lockedUntil) {
      throw this.lockedError('pin_locked', cred!.lockedUntil!, this.now());
    }
    throw authError(HttpStatus.UNAUTHORIZED, 'pin_invalid', {
      remainingAttempts: PIN_MAX_ATTEMPTS - (cred?.failedAttempts ?? 0),
    });
  }

  /** ตั้ง PIN ใหม่ให้บัญชีที่ล็อกอินอยู่ — ต้องผูกเบอร์ก่อน */
  async setPin(userId: string, pin: string): Promise<void> {
    const owner = await this.prisma.userPrivate.findUnique({
      where: { userId },
    });
    if (!owner)
      throw authError(HttpStatus.UNPROCESSABLE_ENTITY, 'pin_requires_phone');
    await this.writePin(userId, pin);
  }

  async changePin(
    userId: string,
    { currentPin, newPin }: PinChangeDto,
  ): Promise<void> {
    const result = await this.checkPin(userId, currentPin);
    if (result === 'locked') {
      const cred = await this.prisma.pinCredential.findUniqueOrThrow({
        where: { userId },
      });
      throw this.lockedError('pin_locked', cred.lockedUntil!, this.now());
    }
    if (result === 'wrong') {
      const cred = await this.prisma.pinCredential.findUniqueOrThrow({
        where: { userId },
      });
      if (cred.lockedUntil)
        throw this.lockedError('pin_locked', cred.lockedUntil, this.now());
      throw authError(HttpStatus.UNAUTHORIZED, 'pin_invalid', {
        remainingAttempts: PIN_MAX_ATTEMPTS - cred.failedAttempts,
      });
    }
    await this.writePin(userId, newPin);
  }

  /** ตรวจ PIN พร้อมนับครั้งที่ผิด — ระหว่างล็อกไม่ตรวจเลย */
  private async checkPin(userId: string, pin: string): Promise<PinResult> {
    const now = this.now();
    const cred = await this.prisma.pinCredential.findUnique({
      where: { userId },
    });
    if (!cred) return 'wrong';
    if (cred.lockedUntil && now < cred.lockedUntil) return 'locked';

    if (await verifySecret(pin, cred.salt, cred.pinHash)) {
      if (cred.failedAttempts > 0 || cred.lockedUntil) {
        await this.prisma.pinCredential.update({
          where: { userId },
          data: { failedAttempts: 0, lockedUntil: null },
        });
      }
      return 'ok';
    }

    const failedAttempts = cred.failedAttempts + 1;
    const lockNow = failedAttempts >= PIN_MAX_ATTEMPTS;
    await this.prisma.pinCredential.update({
      where: { userId },
      data: {
        failedAttempts: lockNow ? 0 : failedAttempts,
        lockedUntil: lockNow
          ? new Date(now.getTime() + PIN_LOCK_DURATION_MS)
          : null,
      },
    });
    return lockNow ? 'locked' : 'wrong';
  }

  private async writePin(userId: string, pin: string): Promise<void> {
    const salt = newSalt();
    const pinHash = await hashSecret(pin, salt);
    await this.prisma.pinCredential.upsert({
      where: { userId },
      create: { userId, salt, pinHash },
      update: { salt, pinHash, failedAttempts: 0, lockedUntil: null },
    });
  }

  // ---------- Session ----------

  async refresh(refreshToken: string): Promise<AuthTokens> {
    const now = this.now();
    const row = await this.prisma.refreshToken.findUnique({
      where: { tokenHash: sha256(refreshToken) },
    });
    if (!row) throw authError(HttpStatus.UNAUTHORIZED, 'refresh_invalid');
    if (row.revokedAt) {
      // ใช้ token ที่ถูกหมุนไปแล้ว = อาจถูกขโมย → ยกเลิกทุก session ของบัญชีนี้
      await this.prisma.refreshToken.updateMany({
        where: { userId: row.userId, revokedAt: null },
        data: { revokedAt: now },
      });
      throw authError(HttpStatus.UNAUTHORIZED, 'refresh_invalid');
    }
    if (row.expiresAt <= now)
      throw authError(HttpStatus.UNAUTHORIZED, 'refresh_invalid');

    await this.prisma.refreshToken.update({
      where: { id: row.id },
      data: { revokedAt: now },
    });
    return this.issueTokens(row.userId);
  }

  async logout(refreshToken: string): Promise<void> {
    await this.prisma.refreshToken.updateMany({
      where: { tokenHash: sha256(refreshToken), revokedAt: null },
      data: { revokedAt: this.now() },
    });
  }

  async me(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { private: true },
    });
    if (!user || user.deletedAt)
      throw authError(HttpStatus.UNAUTHORIZED, 'session_invalid');
    return {
      id: user.id,
      displayName: user.displayName,
      phoneMasked: user.private ? maskThaiPhone(user.private.phone) : null,
      birthYear: user.birthYear,
      avatarUrl: user.avatarUrl,
    };
  }

  async updateProfile(userId: string, data: UpdateProfileDto) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { deletedAt: true },
    });
    if (!user || user.deletedAt)
      throw authError(HttpStatus.UNAUTHORIZED, 'session_invalid');
    await this.prisma.user.update({
      where: { id: userId },
      data: {
        ...(data.displayName !== undefined
          ? { displayName: data.displayName }
          : {}),
        ...(data.birthYear !== undefined ? { birthYear: data.birthYear } : {}),
      },
    });
    return this.me(userId);
  }

  private async issueTokens(userId: string): Promise<AuthTokens> {
    const now = this.now();
    const refreshToken = newOpaqueToken();
    await this.prisma.refreshToken.create({
      data: {
        userId,
        tokenHash: sha256(refreshToken),
        expiresAt: new Date(now.getTime() + REFRESH_TOKEN_TTL_MS),
      },
    });
    const accessToken = await this.jwt.signAsync({ sub: userId });
    return {
      accessToken,
      refreshToken,
      expiresIn: ACCESS_TOKEN_TTL_SECONDS,
      user: await this.me(userId),
    };
  }

  private lockedError(code: string, lockedUntil: Date, now: Date) {
    const unlockSeconds = Math.max(
      0,
      Math.ceil((lockedUntil.getTime() - now.getTime()) / 1000),
    );
    return authError(HttpStatus.LOCKED, code, { unlockSeconds });
  }
}

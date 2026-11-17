import { z } from 'zod';
import { isValidThaiPhone } from './auth-rules.js';

const phone = z
  .string()
  .refine(isValidThaiPhone, { message: 'เบอร์มือถือไทยไม่ถูกต้อง' });

const pin = z.string().regex(/^\d{6}$/, { message: 'PIN ต้องเป็นตัวเลข 6 หลัก' });

export const otpRequestSchema = z.object({ phone });

export const otpVerifySchema = z.object({
  refCode: z.string().regex(/^[A-Z2-9]{6}$/),
  code: z.string().regex(/^\d{6}$/, { message: 'รหัส OTP ต้องเป็นตัวเลข 6 หลัก' }),
  birthYear: z.number().int().min(1900).max(2100),
  guardianConsentGranted: z.boolean(),
  displayName: z.string().trim().max(60).optional(),
});

export const pinLoginSchema = z.object({ phone, pin });

export const pinSetSchema = z.object({ pin });

export const pinChangeSchema = z.object({
  currentPin: pin,
  newPin: pin,
});

export const refreshSchema = z.object({ refreshToken: z.string().min(1) });

export type OtpRequestDto = z.infer<typeof otpRequestSchema>;
export type OtpVerifyDto = z.infer<typeof otpVerifySchema>;
export type PinLoginDto = z.infer<typeof pinLoginSchema>;
export type PinSetDto = z.infer<typeof pinSetSchema>;
export type PinChangeDto = z.infer<typeof pinChangeSchema>;
export type RefreshDto = z.infer<typeof refreshSchema>;

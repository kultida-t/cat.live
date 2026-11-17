// กติกา Auth ฝั่ง server — ค่าเดียวกับแอป Flutter (app/lib/features/auth/domain/usecases/auth_rules.dart)

export const OTP_TTL_MS = 5 * 60 * 1000;
export const OTP_RESEND_COOLDOWN_MS = 60 * 1000;
export const OTP_MAX_ATTEMPTS = 5;
export const LOCK_DURATION_MS = 15 * 60 * 1000;

export const PIN_MAX_ATTEMPTS = OTP_MAX_ATTEMPTS;
export const PIN_LOCK_DURATION_MS = LOCK_DURATION_MS;

export const ACCESS_TOKEN_TTL_SECONDS = 15 * 60;
export const REFRESH_TOKEN_TTL_MS = 30 * 24 * 60 * 60 * 1000;

/** แปลงเบอร์ให้เหลือเฉพาะตัวเลข (รองรับ +66 → 0) */
export function normalizeThaiPhone(raw: string): string {
  let digits = raw.replace(/[^0-9]/g, '');
  if (digits.startsWith('66') && digits.length >= 11) {
    digits = `0${digits.substring(2)}`;
  }
  return digits;
}

/** เบอร์มือถือไทย 10 หลัก ขึ้นต้น 06 / 08 / 09 */
export function isValidThaiPhone(raw: string): boolean {
  return /^0[689]\d{8}$/.test(normalizeThaiPhone(raw));
}

export function maskThaiPhone(raw: string): string {
  const digits = normalizeThaiPhone(raw);
  return `${digits.substring(0, 3)}-xxx-${digits.substring(6)}`;
}

export type AgeEligibility =
  'under13Blocked' | 'minorNeedsGuardianConsent' | 'adult';

/** เกณฑ์อายุตาม PDPA-03: ต่ำกว่า 13 สมัครไม่ได้, 13–19 ต้องมีผู้ปกครองยินยอม */
export function evaluateAge(
  birthYear: number,
  currentYear: number,
): AgeEligibility {
  const age = currentYear - birthYear;
  if (age < 13) return 'under13Blocked';
  if (age < 20) return 'minorNeedsGuardianConsent';
  return 'adult';
}

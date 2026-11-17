import {
  randomBytes,
  randomInt,
  scrypt,
  timingSafeEqual,
  createHash,
} from 'node:crypto';
import { promisify } from 'node:util';

const scryptAsync = promisify(scrypt) as (
  password: string,
  salt: string,
  keylen: number,
) => Promise<Buffer>;

/** สุ่ม salt ต่อหนึ่งรายการ (PIN / OTP) */
export function newSalt(): string {
  return randomBytes(16).toString('base64url');
}

/** hash ความลับที่เดาได้ง่าย (PIN 6 หลัก / OTP 6 หลัก) ด้วย scrypt + salt */
export async function hashSecret(
  secret: string,
  salt: string,
): Promise<string> {
  return (await scryptAsync(secret, salt, 32)).toString('base64url');
}

export async function verifySecret(
  secret: string,
  salt: string,
  expectedHash: string,
): Promise<boolean> {
  const actual = Buffer.from(await hashSecret(secret, salt), 'base64url');
  const expected = Buffer.from(expectedHash, 'base64url');
  return actual.length === expected.length && timingSafeEqual(actual, expected);
}

/** token สุ่มยาว (refresh token) — เก็บเป็น sha256 เพราะ entropy สูงพอ ไม่ต้องใช้ scrypt */
export function newOpaqueToken(): string {
  return randomBytes(32).toString('base64url');
}

export function sha256(value: string): string {
  return createHash('sha256').update(value).digest('base64url');
}

/** OTP 6 หลักที่สุ่มแบบเข้ารหัส */
export function newOtpCode(): string {
  return randomInt(0, 1_000_000).toString().padStart(6, '0');
}

const REF_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

/** รหัสอ้างอิง OTP 6 ตัวอักษร (ไม่มี 0/O/1/I เพื่ออ่านง่าย) */
export function newRefCode(): string {
  let out = '';
  for (let i = 0; i < 6; i++)
    out += REF_ALPHABET[randomInt(REF_ALPHABET.length)];
  return out;
}

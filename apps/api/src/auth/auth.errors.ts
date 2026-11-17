import { HttpException, HttpStatus } from '@nestjs/common';

/**
 * ข้อผิดพลาดของ Auth ในรูปแบบเดียวกันทุกเคส — `code` คือรหัสที่แอปใช้แปลข้อความ
 * (ตรงกับ otp_invalid / otp_locked / otp_expired / pin_locked ฝั่ง Flutter)
 */
export function authError(
  status: HttpStatus,
  code: string,
  extra: Record<string, unknown> = {},
): HttpException {
  return new HttpException({ code, ...extra }, status);
}

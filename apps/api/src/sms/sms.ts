import { Logger, Provider } from '@nestjs/common';

/** ตัวส่ง SMS — เปลี่ยนผู้ให้บริการได้โดยไม่แตะ logic ของ Auth */
export const SMS_SENDER = Symbol('SMS_SENDER');

export interface SmsSender {
  sendOtp(phone: string, code: string, refCode: string): Promise<void>;
}

/**
 * ตัวส่งสำหรับพัฒนา: แสดงรหัสใน console ของ server (ไม่ส่งออกไปที่แอป)
 * ห้ามใช้ใน production — ผู้ให้บริการ SMS จริงยังไม่ได้เลือก
 */
export class ConsoleSmsSender implements SmsSender {
  private readonly logger = new Logger('DevSms');

  async sendOtp(phone: string, code: string, refCode: string): Promise<void> {
    this.logger.log(`OTP ${code} ref=${refCode} phone=${phone}`);
  }
}

export const smsSenderProvider: Provider = {
  provide: SMS_SENDER,
  useFactory: (): SmsSender => {
    if (process.env.NODE_ENV === 'production') {
      throw new Error('ยังไม่ได้ตั้งค่าผู้ให้บริการ SMS สำหรับ production');
    }
    return new ConsoleSmsSender();
  },
};

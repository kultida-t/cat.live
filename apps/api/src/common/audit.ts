import { Global, Injectable, Logger, Module } from '@nestjs/common';
import type { Prisma } from '../generated/prisma/client.js';
import { PrismaService } from '../prisma/prisma.service.js';

export interface AuditDetail {
  actorId?: string;
  entityType?: string;
  entityId?: string;
  meta?: Prisma.InputJsonValue;
}

/**
 * เขียนเหตุการณ์ด้านความปลอดภัยลงตาราง audit_logs —
 * ห้ามใส่ค่าลับ (token, PIN, OTP) หรือ PII ดิบใน meta ให้ใช้ค่าที่ mask แล้วหรือชื่อฟิลด์เท่านั้น
 */
@Injectable()
export class AuditService {
  private readonly logger = new Logger(AuditService.name);

  constructor(private readonly prisma: PrismaService) {}

  async record(action: string, detail: AuditDetail = {}): Promise<void> {
    try {
      await this.prisma.auditLog.create({
        data: {
          action,
          actorId: detail.actorId ?? null,
          entityType: detail.entityType ?? null,
          entityId: detail.entityId ?? null,
          meta: detail.meta,
        },
      });
    } catch (error) {
      // audit เขียนไม่สำเร็จไม่ควรทำให้ flow หลักล้ม — แจ้งใน log แล้วไปต่อ
      this.logger.warn(`audit write failed for ${action}: ${String(error)}`);
    }
  }
}

@Global()
@Module({ providers: [AuditService], exports: [AuditService] })
export class AuditModule {}

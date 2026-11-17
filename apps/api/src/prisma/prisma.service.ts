import { readFileSync } from 'node:fs';
import { Injectable, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '../generated/prisma/client.js';

/**
 * ถ้ามี DB_SSL_CA_FILE (เช่น RDS CA bundle) จะตรวจใบรับรองของฐานข้อมูลด้วย CA นั้น
 * ตัด sslmode ออกจาก URL เพราะค่านั้นจะทับการตั้งค่า CA ที่ส่งเข้าไป
 */
function buildPoolConfig(): { connectionString: string; ssl?: { ca: string; rejectUnauthorized: true } } {
  const url = new URL(process.env.DATABASE_URL ?? '');
  const caFile = process.env.DB_SSL_CA_FILE;
  if (!caFile) return { connectionString: url.toString() };
  url.searchParams.delete('sslmode');
  return {
    connectionString: url.toString(),
    ssl: { ca: readFileSync(caFile, 'utf8'), rejectUnauthorized: true },
  };
}

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy {
  constructor() {
    super({ adapter: new PrismaPg(buildPoolConfig()) });
  }

  async onModuleInit(): Promise<void> {
    await this.$connect();
  }

  async onModuleDestroy(): Promise<void> {
    await this.$disconnect();
  }
}

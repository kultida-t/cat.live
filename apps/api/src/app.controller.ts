import { Controller, Get } from '@nestjs/common';
import { SkipThrottle } from '@nestjs/throttler';
import { AppService } from './app.service.js';

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get()
  getHello(): string {
    return this.appService.getHello();
  }

  // LB ยิง health check ถี่ ๆ — ข้าม rate limit ไม่งั้นเช็กพังทั้งที่แอปปกติ
  @Get('health')
  @SkipThrottle()
  getHealth(): { status: string } {
    return { status: 'ok' };
  }
}

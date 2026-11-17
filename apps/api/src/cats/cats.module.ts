import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module.js';
import { CatsController } from './cats.controller.js';
import { CatsService } from './cats.service.js';

@Module({
  imports: [AuthModule],
  controllers: [CatsController],
  providers: [CatsService],
})
export class CatsModule {}

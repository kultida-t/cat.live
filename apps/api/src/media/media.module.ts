import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module.js';
import { CloudImageLabClient } from './cloudimagelab.client.js';
import { MediaController, WebhookController } from './media.controller.js';
import { MediaService } from './media.service.js';
import { s3PresignerProvider } from './s3-presigner.js';

@Module({
  imports: [AuthModule],
  controllers: [MediaController, WebhookController],
  providers: [MediaService, CloudImageLabClient, s3PresignerProvider],
})
export class MediaModule {}

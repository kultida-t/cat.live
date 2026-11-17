import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Headers,
  HttpCode,
  HttpStatus,
  Param,
  Post,
  Req,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { z } from 'zod';
import { JwtAuthGuard, type AuthenticatedRequest } from '../auth/jwt-auth.guard.js';
import { MediaService, type CallbackBody } from './media.service.js';

const MAX_AVATAR_BYTES = 10 * 1024 * 1024;

const callbackSchema = z.object({
  fileId: z.string().min(1),
  status: z.string().min(1),
  variants: z
    .array(z.object({ presetName: z.string(), url: z.string() }))
    .nullish(),
  error: z.string().nullish(),
});

@Controller('media')
@UseGuards(JwtAuthGuard)
export class MediaController {
  constructor(private readonly media: MediaService) {}

  @Post('avatar')
  @HttpCode(HttpStatus.ACCEPTED)
  @UseInterceptors(FileInterceptor('file', { limits: { fileSize: MAX_AVATAR_BYTES } }))
  uploadAvatar(
    @Req() req: AuthenticatedRequest,
    @UploadedFile() file: { buffer: Buffer; mimetype: string } | undefined,
  ) {
    if (!file) throw new BadRequestException('ไม่พบไฟล์รูป');
    return this.media.uploadAvatar(req.user.id, file);
  }

  @Get('avatars')
  listAvatars(@Req() req: AuthenticatedRequest) {
    return this.media.listAvatars(req.user.id);
  }

  @Post('avatars/:id/select')
  @HttpCode(HttpStatus.NO_CONTENT)
  async selectAvatar(@Req() req: AuthenticatedRequest, @Param('id') id: string) {
    await this.media.selectAvatar(req.user.id, id);
  }
}

/** รับผลประมวลผลจาก CloudImageLab — ไม่ใช้ JWT เพราะเป็น server ส่งเข้ามา ใช้ X-Callback-Key แทน */
@Controller('webhooks')
export class WebhookController {
  constructor(private readonly media: MediaService) {}

  @Post('cloudimagelab')
  @HttpCode(HttpStatus.OK)
  async cloudImageLab(
    @Headers('x-callback-key') callbackKey: string | undefined,
    @Body() body: unknown,
  ) {
    const parsed = callbackSchema.safeParse(body);
    if (!parsed.success) throw new BadRequestException('รูปแบบ callback ไม่ถูกต้อง');
    await this.media.handleCallback(callbackKey, parsed.data as CallbackBody);
  }
}

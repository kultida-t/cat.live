import {
  BadRequestException,
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Post,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import { z } from 'zod';
import { JwtAuthGuard, type AuthenticatedRequest } from '../auth/jwt-auth.guard.js';
import { AVATAR_EXTENSIONS, MAX_AVATAR_BYTES, MediaService, type CallbackBody } from './media.service.js';

const idSchema = z.uuid();

const avatarUploadSchema = z.object({
  contentType: z.enum(Object.keys(AVATAR_EXTENSIONS) as [string, ...string[]]),
  fileSize: z.number().int().min(1).max(MAX_AVATAR_BYTES),
});
type AvatarUploadDto = z.infer<typeof avatarUploadSchema>;

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

  /** ขั้นที่ 1: ขอ presigned URL เพื่ออัปโหลดรูปโปรไฟล์ตรงไปที่ S3 */
  @Post('avatar/upload-url')
  createAvatarUpload(
    @Req() req: AuthenticatedRequest,
    @Body({ schema: avatarUploadSchema }) body: AvatarUploadDto,
  ) {
    return this.media.createAvatarUpload(req.user.id, body);
  }

  /** ขั้นที่ 3: อัปโหลดเสร็จแล้ว ให้ระบบสั่งประมวลผล */
  @Post('avatar/:id/complete')
  @HttpCode(HttpStatus.ACCEPTED)
  completeAvatarUpload(
    @Req() req: AuthenticatedRequest,
    @Param('id', { schema: idSchema }) id: string,
  ) {
    return this.media.completeAvatarUpload(req.user.id, id);
  }

  @Get('avatars')
  listAvatars(@Req() req: AuthenticatedRequest) {
    return this.media.listAvatars(req.user.id);
  }

  @Post('avatars/:id/select')
  @HttpCode(HttpStatus.NO_CONTENT)
  async selectAvatar(
    @Req() req: AuthenticatedRequest,
    @Param('id', { schema: idSchema }) id: string,
  ) {
    await this.media.selectAvatar(req.user.id, id);
  }
}

/** รับผลประมวลผลจาก CloudImageLab — ไม่ใช้ JWT เพราะเป็น server ส่งเข้ามา ใช้ secret ใน query string แทน */
@Controller('api/webhooks')
export class WebhookController {
  constructor(private readonly media: MediaService) {}

  @Post('cloudimagelab')
  @HttpCode(HttpStatus.OK)
  async cloudImageLab(@Query('secret') secret: string | undefined, @Body() body: unknown) {
    const parsed = callbackSchema.safeParse(body);
    if (!parsed.success) throw new BadRequestException('รูปแบบ callback ไม่ถูกต้อง');
    await this.media.handleCallback(secret, parsed.data as CallbackBody);
  }
}

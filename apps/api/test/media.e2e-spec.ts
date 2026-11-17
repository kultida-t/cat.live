import { type INestApplication } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Test } from '@nestjs/testing';
import { createServer, type IncomingHttpHeaders, type Server } from 'node:http';
import type { AddressInfo } from 'node:net';
import request from 'supertest';
import { AppModule } from '../src/app.module.js';
import { configureApp } from '../src/app.setup.js';
import { PrismaService } from '../src/prisma/prisma.service.js';
import { OBJECT_UPLOADER } from '../src/media/s3-uploader.js';

const CIL_KEY = 'test-cil-key';
const PRESET = 'avatar_400';
const CALLBACK_URL = 'https://callback.test/webhooks/cloudimagelab';

describe('Media API — รูปโปรไฟล์ (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let jwt: JwtService;
  let cil: Server;
  let cilCalls: { body: { s3Key: string; outputPath: string; presetNames: string[]; callbackUrl: string }; headers: IncomingHttpHeaders }[] = [];
  let cilFileSeq = 0;
  const s3Puts: { key: string; contentType: string }[] = [];

  beforeAll(async () => {
    cil = createServer((req, res) => {
      let raw = '';
      req.on('data', (c: Buffer) => (raw += c));
      req.on('end', () => {
        cilFileSeq += 1;
        cilCalls.push({ body: JSON.parse(raw), headers: req.headers });
        res.writeHead(202, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ fileId: `cil-file-${cilFileSeq}`, status: 'Processing' }));
      });
    });
    await new Promise<void>((resolve) => cil.listen(0, '127.0.0.1', resolve));
    const port = (cil.address() as AddressInfo).port;
    process.env.CLOUDIMAGELAB_BASE_URL = `http://127.0.0.1:${port}`;
    process.env.CLOUDIMAGELAB_API_KEY = CIL_KEY;
    process.env.CLOUDIMAGELAB_CALLBACK_URL = CALLBACK_URL;
    process.env.CLOUDIMAGELAB_AVATAR_PRESET = PRESET;
    process.env.AVATAR_SOURCE_BUCKET = 'test-bucket';

    const moduleRef = await Test.createTestingModule({ imports: [AppModule] })
      .overrideProvider(OBJECT_UPLOADER)
      .useValue({
        put: async (key: string, _body: Buffer, contentType: string) => {
          s3Puts.push({ key, contentType });
        },
      })
      .compile();
    app = configureApp(moduleRef.createNestApplication());
    await app.init();
    prisma = app.get(PrismaService);
    jwt = app.get(JwtService);
  });

  beforeEach(async () => {
    cilCalls = [];
    cilFileSeq = 0;
    s3Puts.length = 0;
    await prisma.$executeRawUnsafe(
      'TRUNCATE users, user_private, cats, cat_caretakers, refresh_tokens, user_avatars, media_uploads RESTART IDENTITY CASCADE',
    );
  });

  afterAll(async () => {
    await app.close();
    cil.close();
  });

  const http = () => request(app.getHttpServer());
  let phoneSeq = 0;

  async function createUser(name: string) {
    phoneSeq += 1;
    const user = await prisma.user.create({
      data: {
        displayName: name,
        method: 'phoneOtp',
        private: { create: { phone: `089888${String(phoneSeq).padStart(4, '0')}` } },
      },
    });
    return { id: user.id, token: await jwt.signAsync({ sub: user.id }) };
  }

  const jpeg = () => Buffer.from([0xff, 0xd8, 0xff, 0xe0, 0x00]);

  function uploadAvatar(token: string) {
    return http()
      .post('/media/avatar')
      .set('Authorization', `Bearer ${token}`)
      .attach('file', jpeg(), { filename: 'me.jpg', contentType: 'image/jpeg' });
  }

  function callback(fileId: string, url: string, key: string | null = CIL_KEY) {
    const req = http().post('/webhooks/cloudimagelab');
    if (key !== null) req.set('X-Callback-Key', key);
    return req.send({
      fileId,
      status: 'Completed',
      variants: [{ presetName: PRESET, url }],
      error: null,
    });
  }

  it('อัปโหลดรูป → เก็บไฟล์ที่ S3 แล้วส่งงานให้ CloudImageLab ด้วยค่าที่ถูกต้อง', async () => {
    const me = await createUser('ผู้ใช้');
    const res = await uploadAvatar(me.token).expect(202);

    expect(res.body).toEqual({ fileId: 'cil-file-1', status: 'processing' });
    expect(s3Puts).toHaveLength(1);
    expect(s3Puts[0]!.key).toMatch(new RegExp(`^avatars/${me.id}/[0-9a-f-]+\\.jpg$`));
    expect(s3Puts[0]!.contentType).toBe('image/jpeg');
    expect(cilCalls).toHaveLength(1);
    expect(cilCalls[0]!.headers['x-api-key']).toBe(CIL_KEY);
    expect(cilCalls[0]!.body).toEqual({
      s3Key: s3Puts[0]!.key,
      outputPath: `avatars/${me.id}`,
      presetNames: [PRESET],
      callbackUrl: CALLBACK_URL,
    });
  });

  it('ไฟล์ที่ไม่ใช่รูปที่รองรับ → 415 และไม่ส่งงานไป CloudImageLab', async () => {
    const me = await createUser('ผู้ใช้');
    await http()
      .post('/media/avatar')
      .set('Authorization', `Bearer ${me.token}`)
      .attach('file', Buffer.from('hello'), { filename: 'a.txt', contentType: 'text/plain' })
      .expect(415);
    expect(cilCalls).toHaveLength(0);
    expect(s3Puts).toHaveLength(0);
  });

  it('ไม่แนบไฟล์ → 400', async () => {
    const me = await createUser('ผู้ใช้');
    await http().post('/media/avatar').set('Authorization', `Bearer ${me.token}`).expect(400);
  });

  it('callback ที่ key ไม่ถูกต้องหรือไม่มี key → 401 และไม่เปลี่ยนข้อมูล', async () => {
    const me = await createUser('ผู้ใช้');
    await uploadAvatar(me.token).expect(202);
    await callback('cil-file-1', 'https://cdn.test/a.webp', 'wrong-key').expect(401);
    await callback('cil-file-1', 'https://cdn.test/a.webp', null).expect(401);
    const upload = await prisma.mediaUpload.findUniqueOrThrow({ where: { fileId: 'cil-file-1' } });
    expect(upload.status).toBe('processing');
    expect(await prisma.userAvatar.count()).toBe(0);
  });

  it('callback สำเร็จ → บันทึกรูปปัจจุบัน ประวัติรูป และแสดงใน /auth/me', async () => {
    const me = await createUser('ผู้ใช้');
    await uploadAvatar(me.token).expect(202);
    await callback('cil-file-1', 'https://cdn.test/a.webp').expect(200);

    const list = await http().get('/media/avatars').set('Authorization', `Bearer ${me.token}`).expect(200);
    expect(list.body).toEqual([{ id: expect.any(String), url: 'https://cdn.test/a.webp', isCurrent: true }]);
    const profile = await http().get('/auth/me').set('Authorization', `Bearer ${me.token}`).expect(200);
    expect(profile.body.avatarUrl).toBe('https://cdn.test/a.webp');
  });

  it('callback ซ้ำ fileId เดิม → ไม่เพิ่มรูปซ้ำ', async () => {
    const me = await createUser('ผู้ใช้');
    await uploadAvatar(me.token).expect(202);
    await callback('cil-file-1', 'https://cdn.test/a.webp').expect(200);
    await callback('cil-file-1', 'https://cdn.test/a.webp').expect(200);
    expect(await prisma.userAvatar.count({ where: { userId: me.id } })).toBe(1);
  });

  it('ประมวลผลไม่สำเร็จ → ไม่เปลี่ยนรูปปัจจุบัน และบันทึกสถานะล้มเหลว', async () => {
    const me = await createUser('ผู้ใช้');
    await uploadAvatar(me.token).expect(202);
    await callback('cil-file-1', 'https://cdn.test/a.webp').expect(200);
    await uploadAvatar(me.token).expect(202);
    await http()
      .post('/webhooks/cloudimagelab')
      .set('X-Callback-Key', CIL_KEY)
      .send({ fileId: 'cil-file-2', status: 'Failed', variants: [], error: 'unsupported image' })
      .expect(200);

    const upload = await prisma.mediaUpload.findUniqueOrThrow({ where: { fileId: 'cil-file-2' } });
    expect(upload).toMatchObject({ status: 'failed', error: 'unsupported image' });
    const profile = await http().get('/auth/me').set('Authorization', `Bearer ${me.token}`).expect(200);
    expect(profile.body.avatarUrl).toBe('https://cdn.test/a.webp');
  });

  it('เลือกรูปที่เคยใช้กลับมาเป็นรูปปัจจุบันได้ และรูปของคนอื่นเลือกไม่ได้', async () => {
    const me = await createUser('ผู้ใช้');
    const other = await createUser('คนอื่น');
    await uploadAvatar(me.token).expect(202);
    await callback('cil-file-1', 'https://cdn.test/first.webp').expect(200);
    await uploadAvatar(me.token).expect(202);
    await callback('cil-file-2', 'https://cdn.test/second.webp').expect(200);

    const list = await http().get('/media/avatars').set('Authorization', `Bearer ${me.token}`).expect(200);
    const first = list.body.find((a: { url: string }) => a.url.endsWith('first.webp'));
    await http()
      .post(`/media/avatars/${first.id}/select`)
      .set('Authorization', `Bearer ${me.token}`)
      .expect(204);
    const profile = await http().get('/auth/me').set('Authorization', `Bearer ${me.token}`).expect(200);
    expect(profile.body.avatarUrl).toBe('https://cdn.test/first.webp');

    await http()
      .post(`/media/avatars/${first.id}/select`)
      .set('Authorization', `Bearer ${other.token}`)
      .expect(404);
  });
});

import { INestApplication } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module.js';
import { configureApp } from '../src/app.setup.js';
import { PrismaService } from '../src/prisma/prisma.service.js';

describe('Cats API (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let jwt: JwtService;
  let phoneSeq = 0;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({ imports: [AppModule] }).compile();
    app = configureApp(moduleRef.createNestApplication());
    await app.init();
    prisma = app.get(PrismaService);
    jwt = app.get(JwtService);
  });

  beforeEach(async () => {
    await prisma.$executeRawUnsafe(
      'TRUNCATE users, user_private, cats, cat_caretakers, refresh_tokens RESTART IDENTITY CASCADE',
    );
  });

  afterAll(async () => {
    await app.close();
  });

  const http = () => request(app.getHttpServer());

  async function createUser(name: string) {
    phoneSeq += 1;
    const phone = `089999${String(phoneSeq).padStart(4, '0')}`;
    const user = await prisma.user.create({
      data: { displayName: name, method: 'phoneOtp', private: { create: { phone } } },
    });
    const token = await jwt.signAsync({ sub: user.id });
    return { id: user.id, token };
  }

  function createCat(ownerId: string, name: string, extra: Partial<{ deletedAt: Date }> = {}) {
    return prisma.cat.create({
      data: { ownerId, name, breed: 'ไทยพื้นบ้าน', sex: 'เมีย', neutered: true, ...extra },
    });
  }

  it('ไม่มี token → 401', async () => {
    await http().get('/api/v1/cats').expect(401);
  });

  it('ผู้ใช้ใหม่ที่ยังไม่มีแมว → ได้รายการว่าง', async () => {
    const me = await createUser('ผู้ใช้ใหม่');
    const res = await http().get('/api/v1/cats').set('Authorization', `Bearer ${me.token}`).expect(200);
    expect(res.body).toEqual([]);
  });

  it('เจ้าของเห็นแมวของตัวเองพร้อมสิทธิ์ owner และรหัส Cat ID รูปแบบ MAW000000', async () => {
    const me = await createUser('เจ้าของ');
    await createCat(me.id, 'มะลิ');
    const res = await http().get('/api/v1/cats').set('Authorization', `Bearer ${me.token}`).expect(200);

    expect(res.body).toHaveLength(1);
    expect(res.body[0]).toMatchObject({ name: 'มะลิ', breed: 'ไทยพื้นบ้าน', sex: 'เมีย', neutered: true, role: 'owner' });
    expect(res.body[0].publicId).toMatch(/^MAW\d{6}$/);
  });

  it('ผู้ดูแลร่วมเห็นแมวพร้อมสิทธิ์ตามที่ได้รับ', async () => {
    const owner = await createUser('เจ้าของ');
    const helper = await createUser('ผู้ดูแล');
    const cat = await createCat(owner.id, 'ส้มจี๊ด');
    await prisma.catCaretaker.create({ data: { catId: cat.id, userId: helper.id, role: 'caretaker' } });

    const res = await http().get('/api/v1/cats').set('Authorization', `Bearer ${helper.token}`).expect(200);
    expect(res.body).toHaveLength(1);
    expect(res.body[0]).toMatchObject({ name: 'ส้มจี๊ด', role: 'caretaker' });
  });

  it('ไม่เห็นแมวของคนอื่นและแมวที่ถูกลบแล้ว', async () => {
    const me = await createUser('ผู้ใช้ A');
    const other = await createUser('ผู้ใช้ B');
    await createCat(other.id, 'ถั่วดำ');
    await createCat(me.id, 'แมวที่ถูกลบ', { deletedAt: new Date() });

    const res = await http().get('/api/v1/cats').set('Authorization', `Bearer ${me.token}`).expect(200);
    expect(res.body).toEqual([]);
  });

  it('ไม่ส่งข้อมูลภายในออกไป (qrPayload, ownerId)', async () => {
    const me = await createUser('เจ้าของ');
    await prisma.cat.create({ data: { ownerId: me.id, name: 'มะลิ', qrPayload: 'secret-qr' } });

    const res = await http().get('/api/v1/cats').set('Authorization', `Bearer ${me.token}`).expect(200);
    expect(res.body[0]).not.toHaveProperty('qrPayload');
    expect(res.body[0]).not.toHaveProperty('ownerId');
  });
});

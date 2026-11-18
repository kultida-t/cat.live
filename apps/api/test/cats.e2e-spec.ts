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
      'TRUNCATE users, user_private, cats, cat_caretakers, cat_health, refresh_tokens RESTART IDENTITY CASCADE',
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

  describe('POST /api/v1/cats', () => {
    it('สร้างแมวใหม่สำเร็จ พร้อม role owner และแปลง age_label เป็นวันเกิดโดยประมาณ', async () => {
      const me = await createUser('เจ้าของ');
      const res = await http()
        .post('/api/v1/cats')
        .set('Authorization', `Bearer ${me.token}`)
        .send({ name: 'มะลิ', breed: 'เปอร์เซีย', sex: 'female', neutered: true, age_label: '3 ปี', weight_kg: 4.2 })
        .expect(201);

      expect(res.body).toMatchObject({ name: 'มะลิ', breed: 'เปอร์เซีย', sex: 'female', neutered: true, role: 'owner', weightKg: 4.2 });
      expect(res.body.publicId).toMatch(/^MAW\d{6}$/);
      expect(res.body.birthDate).toMatch(/^\d{4}-\d{2}-\d{2}T/);
      const health = await prisma.catHealth.findFirst({ where: { catId: res.body.id, type: 'weight' } });
      expect(health?.detail).toMatchObject({ kg: 4.2 });
    });

    it('ไม่ระบุชื่อ → 400', async () => {
      const me = await createUser('เจ้าของ');
      await http().post('/api/v1/cats').set('Authorization', `Bearer ${me.token}`).send({ breed: 'ไทย' }).expect(400);
    });

    it('ส่ง photo_url แล้วรูปไปอยู่ใน photoUrls', async () => {
      const me = await createUser('เจ้าของ');
      const res = await http()
        .post('/api/v1/cats')
        .set('Authorization', `Bearer ${me.token}`)
        .send({ name: 'ส้มจี๊ด', photo_url: 'https://cdn.example.com/cat1.jpg' })
        .expect(201);
      expect(res.body.photoUrls).toEqual(['https://cdn.example.com/cat1.jpg']);
    });
  });

  describe('PUT /api/v1/cats/:id', () => {
    it('เจ้าของแก้ข้อมูลได้ และน้ำหนักใหม่สร้างประวัติเพิ่ม', async () => {
      const me = await createUser('เจ้าของ');
      const cat = await createCat(me.id, 'มะลิ');
      const res = await http()
        .put(`/api/v1/cats/${cat.id}`)
        .set('Authorization', `Bearer ${me.token}`)
        .send({ name: 'มะลิจ๋า', weight_kg: 3.9 })
        .expect(200);
      expect(res.body).toMatchObject({ name: 'มะลิจ๋า', weightKg: 3.9 });
      expect(await prisma.catHealth.count({ where: { catId: cat.id, type: 'weight' } })).toBe(1);
    });

    it('น้ำหนักค่าเดิมไม่สร้างประวัติซ้ำ', async () => {
      const me = await createUser('เจ้าของ');
      const cat = await createCat(me.id, 'มะลิ');
      const auth = { Authorization: `Bearer ${me.token}` };
      await http().put(`/api/v1/cats/${cat.id}`).set(auth).send({ weight_kg: 3.9 }).expect(200);
      await http().put(`/api/v1/cats/${cat.id}`).set(auth).send({ weight_kg: 3.9 }).expect(200);
      expect(await prisma.catHealth.count({ where: { catId: cat.id, type: 'weight' } })).toBe(1);
    });

    it('caretaker/viewer แก้ไม่ได้ (403), คนนอกเห็นเป็น 404', async () => {
      const owner = await createUser('เจ้าของ');
      const helper = await createUser('ผู้ดูแล');
      const stranger = await createUser('คนนอก');
      const cat = await createCat(owner.id, 'ถั่วดำ');
      await prisma.catCaretaker.create({ data: { catId: cat.id, userId: helper.id, role: 'caretaker' } });

      await http()
        .put(`/api/v1/cats/${cat.id}`)
        .set('Authorization', `Bearer ${helper.token}`)
        .send({ name: 'แก้โดยผู้ดูแล' })
        .expect(403);
      await http()
        .put(`/api/v1/cats/${cat.id}`)
        .set('Authorization', `Bearer ${stranger.token}`)
        .send({ name: 'แก้โดยคนนอก' })
        .expect(404);
    });

    it('ไม่ส่งฟิลด์เลย → 400', async () => {
      const me = await createUser('เจ้าของ');
      const cat = await createCat(me.id, 'มะลิ');
      await http()
        .put(`/api/v1/cats/${cat.id}`)
        .set('Authorization', `Bearer ${me.token}`)
        .send({})
        .expect(400);
    });
  });

  describe('DELETE /api/v1/cats/:id', () => {
    it('เจ้าของลบได้ (soft delete) แล้วไม่โผล่ในลิสต์', async () => {
      const me = await createUser('เจ้าของ');
      const cat = await createCat(me.id, 'มะลิ');
      await http().delete(`/api/v1/cats/${cat.id}`).set('Authorization', `Bearer ${me.token}`).expect(200);

      const res = await http().get('/api/v1/cats').set('Authorization', `Bearer ${me.token}`).expect(200);
      expect(res.body).toEqual([]);
      expect((await prisma.cat.findUnique({ where: { id: cat.id } }))?.deletedAt).not.toBeNull();
    });

    it('co_owner ลบไม่ได้ — เฉพาะเจ้าของ', async () => {
      const owner = await createUser('เจ้าของ');
      const co = await createUser('co-owner');
      const cat = await createCat(owner.id, 'ส้มจี๊ด');
      await prisma.catCaretaker.create({ data: { catId: cat.id, userId: co.id, role: 'co_owner' } });
      await http().delete(`/api/v1/cats/${cat.id}`).set('Authorization', `Bearer ${co.token}`).expect(403);
    });
  });

  describe('POST /api/v1/cats/:id/photos', () => {
    it('เพิ่มรูปแล้ว URL อยู่หน้าสุดของ photoUrls', async () => {
      const me = await createUser('เจ้าของ');
      const cat = await prisma.cat.create({
        data: { ownerId: me.id, name: 'มะลิ', photoUrls: ['https://cdn.example.com/old.jpg'] },
      });
      const res = await http()
        .post(`/api/v1/cats/${cat.id}/photos`)
        .set('Authorization', `Bearer ${me.token}`)
        .send({ image_url: 'https://cdn.example.com/new.jpg', caption: 'รูปใหม่' })
        .expect(201);
      expect(res.body).toMatchObject({ image_url: 'https://cdn.example.com/new.jpg', caption: 'รูปใหม่' });
      const saved = await prisma.cat.findUnique({ where: { id: cat.id } });
      expect(saved?.photoUrls[0]).toBe('https://cdn.example.com/new.jpg');
    });

    it('ผู้ดูแลระดับ caretaker เพิ่มรูปไม่ได้', async () => {
      const owner = await createUser('เจ้าของ');
      const helper = await createUser('ผู้ดูแล');
      const cat = await createCat(owner.id, 'ถั่วดำ');
      await prisma.catCaretaker.create({ data: { catId: cat.id, userId: helper.id, role: 'caretaker' } });
      await http()
        .post(`/api/v1/cats/${cat.id}/photos`)
        .set('Authorization', `Bearer ${helper.token}`)
        .send({ image_url: 'https://cdn.example.com/x.jpg' })
        .expect(403);
    });
  });
});

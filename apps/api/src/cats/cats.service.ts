import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '../generated/prisma/client.js';
import { PrismaService } from '../prisma/prisma.service.js';
import type { AddCatPhotoDto, CreateCatDto, UpdateCatDto } from './cats.schemas.js';

const MAX_CAT_PHOTOS = 30;
/** role ที่แก้ไขข้อมูลแมวได้ — owner เต็มสิทธิ์, co_owner แก้ได้, caretaker/viewer อ่านอย่างเดียว */
const EDIT_ROLES = new Set(['owner', 'co_owner']);

const catSelect = {
  id: true,
  publicId: true,
  name: true,
  breed: true,
  sex: true,
  neutered: true,
  birthDate: true,
  photoUrls: true,
  status: true,
  ownerId: true,
} satisfies Prisma.CatSelect;

type CatRow = Prisma.CatGetPayload<{ select: typeof catSelect }>;

@Injectable()
export class CatsService {
  constructor(private readonly prisma: PrismaService) {}

  /** แมวทั้งหมดที่ผู้ใช้เป็นเจ้าของหรือเป็นผู้ดูแล (ไม่รวมแมวที่ถูกลบแล้ว) พร้อมสิทธิ์ของผู้ใช้ต่อแมวตัวนั้น */
  async listMyCats(userId: string) {
    const cats = await this.prisma.cat.findMany({
      where: {
        deletedAt: null,
        OR: [{ ownerId: userId }, { caretakers: { some: { userId } } }],
      },
      select: {
        ...catSelect,
        caretakers: { where: { userId }, select: { role: true } },
        health: {
          where: { type: 'weight' },
          orderBy: [{ recordDate: 'desc' }, { createdAt: 'desc' }],
          take: 1,
          select: { detail: true },
        },
      },
      orderBy: { createdAt: 'asc' },
    });
    return cats.map(({ health, ...cat }) =>
      this.toJson(cat, this.roleOf(cat, userId), this.weightOf(health)),
    );
  }

  /** สร้างแมวใหม่ — ผู้สร้างเป็นเจ้าของ; weight_kg บันทึกเป็นประวัติน้ำหนักใน cat_health */
  async createCat(userId: string, dto: CreateCatDto) {
    const cat = await this.prisma.cat.create({
      data: {
        ownerId: userId,
        name: dto.name,
        breed: dto.breed ?? null,
        sex: dto.sex ?? null,
        neutered: dto.neutered ?? null,
        birthDate: this.birthDateOf(dto),
        photoUrls: dto.photo_url ? [dto.photo_url] : [],
      },
      select: catSelect,
    });
    if (dto.weight_kg != null) await this.recordWeight(cat.id, dto.weight_kg);
    return this.toJson(cat, 'owner', dto.weight_kg ?? null);
  }

  /** แก้ไขข้อมูลแมว — เฉพาะ owner/co_owner; weight_kg สร้างประวัติใหม่เฉพาะเมื่อเปลี่ยนจากค่าล่าสุด */
  async updateCat(userId: string, catId: string, dto: UpdateCatDto) {
    const { cat, role } = await this.catForUser(catId, userId);
    if (!EDIT_ROLES.has(role)) {
      throw new ForbiddenException('ไม่มีสิทธิ์แก้ไขข้อมูลแมวตัวนี้');
    }
    const photoUrls = dto.photo_url
      ? [dto.photo_url, ...cat.photoUrls.filter((u) => u !== dto.photo_url)].slice(0, MAX_CAT_PHOTOS)
      : undefined;
    const birthDate = this.birthDateOf(dto);
    const updated = await this.prisma.cat.update({
      where: { id: cat.id },
      data: {
        ...(dto.name !== undefined && { name: dto.name }),
        ...(dto.breed !== undefined && { breed: dto.breed }),
        ...(dto.sex !== undefined && { sex: dto.sex }),
        ...(dto.neutered !== undefined && { neutered: dto.neutered }),
        ...(birthDate !== undefined && { birthDate }),
        ...(photoUrls !== undefined && { photoUrls }),
      },
      select: catSelect,
    });

    let weightKg: number | null = null;
    if (dto.weight_kg != null) {
      const latest = await this.latestWeight(cat.id);
      if (latest !== dto.weight_kg) {
        await this.recordWeight(cat.id, dto.weight_kg);
      }
      weightKg = dto.weight_kg;
    } else {
      weightKg = await this.latestWeight(cat.id);
    }
    return this.toJson(updated, role, weightKg);
  }

  /** ลบแมว (soft delete) — เฉพาะเจ้าของ */
  async deleteCat(userId: string, catId: string) {
    const { cat, role } = await this.catForUser(catId, userId);
    if (role !== 'owner') {
      throw new ForbiddenException('เฉพาะเจ้าของแมวเท่านั้นที่ลบได้');
    }
    await this.prisma.cat.update({
      where: { id: cat.id },
      data: { deletedAt: new Date() },
    });
    return { deleted: true };
  }

  /** เพิ่มรูปแมว — เฉพาะ owner/co_owner; เก็บ URL ใน photo_urls (คำบรรยายจะมาในเฟส cat_photos) */
  async addPhoto(userId: string, catId: string, dto: AddCatPhotoDto) {
    const { cat, role } = await this.catForUser(catId, userId);
    if (!EDIT_ROLES.has(role)) {
      throw new ForbiddenException('ไม่มีสิทธิ์เพิ่มรูปให้แมวตัวนี้');
    }
    const urls = cat.photoUrls.includes(dto.image_url)
      ? cat.photoUrls
      : [dto.image_url, ...cat.photoUrls].slice(0, MAX_CAT_PHOTOS);
    if (urls !== cat.photoUrls) {
      await this.prisma.cat.update({ where: { id: cat.id }, data: { photoUrls: urls } });
    }
    return { id: dto.image_url, image_url: dto.image_url, caption: dto.caption ?? '' };
  }

  /** หาแมวที่ยังไม่ถูกลบ + สิทธิ์ของผู้ใช้ — คนที่ไม่เกี่ยวข้องได้ 404 เหมือนไม่มีแมวตัวนี้ */
  private async catForUser(catId: string, userId: string) {
    const cat = await this.prisma.cat.findFirst({
      where: { id: catId, deletedAt: null },
      select: { ...catSelect, caretakers: { where: { userId }, select: { role: true } } },
    });
    if (!cat) throw new NotFoundException('ไม่พบแมวตัวนี้');
    const role = this.roleOf(cat, userId);
    if (role === null) throw new NotFoundException('ไม่พบแมวตัวนี้');
    return { cat, role };
  }

  private roleOf(cat: { ownerId: string; caretakers?: { role: string }[] }, userId: string) {
    if (cat.ownerId === userId) return 'owner' as const;
    return cat.caretakers?.[0]?.role ?? null;
  }

  /** วันเกิดจาก birth_date โดยตรง หรือแปลงจาก age_label ของแอปโดยประมาณ */
  private birthDateOf(dto: { birth_date?: string | null; age_label?: string | null }) {
    if (dto.birth_date) return new Date(`${dto.birth_date}T00:00:00Z`);
    if (dto.birth_date === null) return null;
    if (!dto.age_label) return undefined;
    const now = new Date();
    const back = (years: number, months = 0) =>
      new Date(Date.UTC(now.getUTCFullYear() - years, now.getUTCMonth() - months, now.getUTCDate()));
    if (dto.age_label === 'น้อยกว่า 3 เดือน') return back(0, 1);
    const months = dto.age_label.match(/^(\d+)\s*เดือน$/);
    if (months) return back(0, Number(months[1]));
    const years = dto.age_label.match(/^(\d+)\+?\s*ปี$/);
    if (years) return back(Number(years[1]));
    return undefined;
  }

  private recordWeight(catId: string, kg: number) {
    return this.prisma.catHealth.create({
      data: { catId, type: 'weight', detail: { kg }, recordDate: new Date() },
    });
  }

  private async latestWeight(catId: string): Promise<number | null> {
    const row = await this.prisma.catHealth.findFirst({
      where: { catId, type: 'weight' },
      orderBy: [{ recordDate: 'desc' }, { createdAt: 'desc' }],
      select: { detail: true },
    });
    return this.weightOf(row ? [row] : []);
  }

  private weightOf(rows: { detail: Prisma.JsonValue }[]): number | null {
    const detail = rows[0]?.detail;
    if (detail && typeof detail === 'object' && !Array.isArray(detail)) {
      const kg = (detail as Record<string, unknown>).kg;
      return typeof kg === 'number' ? kg : null;
    }
    return null;
  }

  private toJson(
    cat: CatRow & { caretakers?: { role: string }[] },
    role: string | null,
    weightKg: number | null,
  ) {
    const { ownerId: _ownerId, caretakers: _caretakers, ...rest } = cat;
    return { ...rest, role, weightKg };
  }
}

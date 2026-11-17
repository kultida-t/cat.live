import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';

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
        caretakers: { where: { userId }, select: { role: true } },
      },
      orderBy: { createdAt: 'asc' },
    });
    return cats.map(({ ownerId, caretakers, ...cat }) => ({
      ...cat,
      role: ownerId === userId ? 'owner' : caretakers[0]!.role,
    }));
  }
}

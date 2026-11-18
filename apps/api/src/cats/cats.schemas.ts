import { z } from 'zod';

const isoDate = z
  .string()
  .regex(/^\d{4}-\d{2}-\d{2}$/, { message: 'รูปแบบวันที่ต้องเป็น YYYY-MM-DD' });
const imageUrl = z.string().url().max(2048);

const catFields = {
  breed: z.string().trim().max(60).nullable().optional(),
  sex: z.enum(['male', 'female']).nullable().optional(),
  neutered: z.boolean().nullable().optional(),
  birth_date: isoDate.nullable().optional(),
  // label อายุจาก dropdown ของแอป (เช่น '3 ปี', '6 เดือน') — แปลงเป็นวันเกิดโดยประมาณฝั่งเซิร์ฟเวอร์
  age_label: z.string().trim().max(20).nullable().optional(),
  weight_kg: z.number().min(0.1).max(50).nullable().optional(),
  photo_url: imageUrl.nullable().optional(),
};

export const createCatSchema = z.object({
  name: z.string().trim().min(1, { message: 'กรุณาระบุชื่อแมว' }).max(60),
  ...catFields,
});

export const updateCatSchema = z
  .object({
    name: z.string().trim().min(1).max(60).optional(),
    ...catFields,
  })
  .refine((data) => Object.values(data).some((v) => v !== undefined), {
    message: 'ต้องระบุอย่างน้อยหนึ่งฟิลด์',
  });

export const addCatPhotoSchema = z.object({
  image_url: imageUrl,
  caption: z.string().trim().max(200).optional(),
});

export const catPhotoUploadSchema = z.object({
  contentType: z.string(),
  fileSize: z.number().int().positive().max(10 * 1024 * 1024, {
    message: 'ไฟล์ใหญ่เกิน 10MB',
  }),
});

export type CreateCatDto = z.infer<typeof createCatSchema>;
export type UpdateCatDto = z.infer<typeof updateCatSchema>;
export type AddCatPhotoDto = z.infer<typeof addCatPhotoSchema>;
export type CatPhotoUploadDto = z.infer<typeof catPhotoUploadSchema>;

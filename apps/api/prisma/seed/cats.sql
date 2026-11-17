-- ข้อมูลตัวอย่างแมว 3 ตัวให้บัญชีทดสอบ (เบอร์ 0899990002) — รันซ้ำได้ ไม่ซ้ำข้อมูลเดิม
-- ถ้าไม่มีบัญชีเบอร์นี้ในฐานข้อมูล จะไม่เพิ่มแมวเลย
-- วิธีรัน: psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f prisma/seed/cats.sql

INSERT INTO cats (id, owner_id, public_id, name, breed, sex, neutered, birth_date, status, created_at, updated_at)
SELECT v.id, p.user_id, v.public_id, v.name, v.breed, v.sex, v.neutered, v.birth_date, 'normal', now(), now()
FROM user_private p
CROSS JOIN (VALUES
  ('8f1c2a10-0000-4000-8000-000000000123'::uuid, 'MAW000123', 'มะลิ',     'วิเชียรมาศ', 'female', true,  DATE '2023-08-14'),
  ('8f1c2a10-0000-4000-8000-000000000124'::uuid, 'MAW000124', 'ส้มจี๊ด',  'ไทยสีส้ม',   'male',   true,  DATE '2025-05-03'),
  ('8f1c2a10-0000-4000-8000-000000000188'::uuid, 'MAW000188', 'ถั่วดำ',   'ดำปลอด',     'male',   false, DATE '2020-02-09')
) AS v(id, public_id, name, breed, sex, neutered, birth_date)
WHERE p.phone = '0899990002'
ON CONFLICT (public_id) DO NOTHING;

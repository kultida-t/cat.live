-- อัปโหลดแบบ presigned: สร้างรายการก่อนอัปโหลด จึงยังไม่มี file_id จนกว่าจะสั่ง CloudImageLab ประมวลผล
ALTER TABLE "media_uploads" ALTER COLUMN "file_id" DROP NOT NULL,
ALTER COLUMN "status" SET DEFAULT 'awaiting_upload';

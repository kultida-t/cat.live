# เชื่อม CloudImageLab (รูปโปรไฟล์ — Flow B)

สรุปจากคู่มือ `https://stg-cloudimagelab-api.mrfox.store/docs/api-usage-guide` สำหรับให้ทีมและ AI อ่าน
**ห้ามใส่ key จริงในไฟล์นี้หรือใน git** — ค่าลับตั้งเป็น CI/CD variable (staging / production แยกกัน)

## ภาพรวมการทำงาน (Flow B: ไฟล์อยู่บน S3 แล้วค่อยสั่งประมวลผล)

1. แอปลบข้อมูลแฝง (GPS) ในรูปในเครื่อง แล้วส่งรูปไป `POST /media/avatar` ของ backend เรา (ต้องล็อกอิน)
2. backend เขียนรูปต้นฉบับลง S3 ที่ `avatars/<userId>/<uuid>.<ext>`
3. backend เรียก CloudImageLab `POST /api/files/process` พร้อม `s3Key`, `outputPath`, `presetNames`, `callbackUrl` (header `X-Api-Key`)
4. CloudImageLab ประมวลผลเบื้องหลัง แล้ว **ส่งผลกลับ** มาที่ `POST /webhooks/cloudimagelab` ของเรา (header `X-Callback-Key` = key ของแอป)
5. backend ตรวจ key, บันทึกรูปที่ได้เป็นรูปปัจจุบันและเก็บประวัติ แอปอ่านรูปจาก `/auth/me` และ `/media/avatars`

ผลประมวลผลต้องใช้ `url` จาก callback เสมอ ห้ามประกอบ path เอง

## Endpoint ฝั่งเรา

| Endpoint | หน้าที่ |
|---|---|
| `POST /media/avatar` | รับรูป (multipart ฟิลด์ `file`, JPEG/PNG/WebP, ไม่เกิน 10 MB) ตอบ 202 |
| `GET /media/avatars` | รูปที่เคยใช้ เรียงใหม่ไปเก่า |
| `POST /media/avatars/:id/select` | เลือกรูปเก่ากลับมาเป็นรูปปัจจุบัน |
| `POST /webhooks/cloudimagelab` | รับผลจาก CloudImageLab (ตรวจ `X-Callback-Key`) |

## ตัวแปรที่ต้องตั้ง

| ตัวแปร | ความลับ | คำอธิบาย |
|---|---|---|
| `CLOUDIMAGELAB_BASE_URL` | ไม่ | staging: `https://stg-cloudimagelab-api.mrfox.store` · production: `https://cloudimagelab-api.univerza.co` |
| `CLOUDIMAGELAB_API_KEY` | **ใช่** | key ของแอป (staging กับ production คนละตัว) |
| `CLOUDIMAGELAB_CALLBACK_URL` | ไม่ | URL สาธารณะของ backend + `/webhooks/cloudimagelab` |
| `CLOUDIMAGELAB_AVATAR_PRESET` | ไม่ | ชื่อ preset ของรูปโปรไฟล์ (ค่าเริ่มต้น `thumb_sq` 150×150 crop) |
| `AVATAR_SOURCE_BUCKET` | ไม่ | bucket ที่ backend เขียนรูปต้นฉบับ |
| `AWS_REGION` | ไม่ | region ของ bucket |
| `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` | **ใช่** | สิทธิ์เขียน bucket นี้เท่านั้น (จำกัดที่ prefix `avatars/`) |

ถ้าตัวแปรที่จำเป็นขาด `POST /media/avatar` จะตอบ 503 และไม่เขียนไฟล์

## ความปลอดภัย

- key ทั้งหมดอยู่ฝั่ง server เท่านั้น ห้ามใส่ในแอป
- ตรวจ `X-Callback-Key` ด้วยการเทียบแบบ constant-time ก่อนทำอะไร callback ซ้ำ fileId เดิมไม่เปลี่ยนผลเดิม
- แอปลบ GPS/EXIF ก่อนส่ง แต่ฝั่ง server ต้องไม่เชื่อฝั่งแอปอย่างเดียว
- CloudImageLab ตัดสินชนิดไฟล์จากไบต์จริง ไฟล์ที่ไม่ใช่รูปจะล้มเหลวโดยไม่ลองซ้ำ (ได้ callback สถานะ Failed)

## สิ่งที่ต้องมีก่อนใช้งานบน staging

1. ค่าตัวแปรตามตารางด้านบนตั้งใน CI/CD
2. migration `20261117150000_avatar_media` รันบนฐาน staging แล้ว
3. backend ที่ deploy แล้วและเข้าถึงจากอินเทอร์เน็ตได้ (CloudImageLab ต้องเรียก callback ได้)
4. preset `thumb_sq` มีอยู่ในการตั้งค่าแอปของเราที่ CloudImageLab

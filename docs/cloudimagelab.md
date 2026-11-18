# เชื่อม CloudImageLab (รูปโปรไฟล์ — Flow B)

สรุปจากคู่มือ `https://stg-cloudimagelab-api.mrfox.store/docs/api-usage-guide` สำหรับให้ทีมและ AI อ่าน
**ห้ามใส่ key จริงในไฟล์นี้หรือใน git** — ค่าลับตั้งเป็น CI/CD variable (staging / production แยกกัน)

## ภาพรวมการทำงาน (Flow B: ไฟล์อยู่บน S3 แล้วค่อยสั่งประมวลผล)

ทีมกำหนดให้ **อัปโหลดด้วย presigned URL เท่านั้น** และไฟล์ต้องอยู่ใต้โฟลเดอร์ชื่อโปรเจกต์ (`catlive/`)

1. แอปขอ `POST /media/avatar/upload-url` (ต้องล็อกอิน) ส่ง `contentType` และ `fileSize` — backend ตอบ `uploadUrl` (อายุ 5 นาที), `uploadId`, `headers`
2. แอปลบข้อมูลแฝง (GPS) ในรูปในเครื่อง แล้ว `PUT` ไฟล์ไปที่ `uploadUrl` ตรง ๆ โดยส่ง `Content-Type` ตรงกับที่ขอ และ **ห้ามแนบ Authorization** (จะทำให้ลายเซ็นผิด) ไฟล์ไปอยู่ที่ `catlive/avatars/<userId>/<uuid>.<ext>` ใน bucket
3. แอปแจ้ง `POST /media/avatar/:uploadId/complete` — backend เรียก CloudImageLab `POST /api/files/process` พร้อม `s3Key`, `outputPath`, `presetNames`, `callbackUrl` (header `X-Api-Key`)
4. CloudImageLab ประมวลผลเบื้องหลัง แล้ว **ส่งผลกลับ** มาที่ `POST /api/v1/webhooks/cloudimagelab?type=...&secret=...` ของเรา (ค่า `type` และ `secret` อยู่ใน callback URL ที่เราส่งให้ตอนขอประมวลผล)
5. backend ตรวจ key บันทึกรูปที่ได้เป็นรูปปัจจุบันและเก็บประวัติ แอปอ่านรูปจาก `/api/v1/auth/me` และ `/api/v1/media/avatars`

ผลประมวลผลต้องใช้ `url` จาก callback เสมอ ห้ามประกอบ path เอง รูปอ่านผ่าน CloudFront `https://d2kz9pl8iwzvcz.cloudfront.net/` (ไม่ต้องระบุ bucket ใน URL)

## Endpoint ฝั่งเรา

| Endpoint | หน้าที่ |
|---|---|
| `POST /api/v1/media/avatar/upload-url` | ขอ presigned URL (JPEG/PNG/WebP, ไม่เกิน 10 MB) ตอบ 201 |
| `POST /api/v1/media/avatar/:id/complete` | แจ้งอัปโหลดเสร็จ สั่งประมวลผล ตอบ 202 (เรียกซ้ำได้) |
| `GET /api/v1/media/avatars` | รูปที่เคยใช้ เรียงใหม่ไปเก่า |
| `POST /api/v1/media/avatars/:id/select` | เลือกรูปเก่ากลับมาเป็นรูปปัจจุบัน |
| `POST /api/v1/webhooks/cloudimagelab` | รับผลจาก CloudImageLab (ตรวจ query `secret`) |

## ตัวแปรที่ต้องตั้ง

| ตัวแปร | ความลับ | คำอธิบาย |
|---|---|---|
| `CLOUDIMAGELAB_BASE_URL` | ไม่ | staging: `https://stg-cloudimagelab-api.mrfox.store` · production: `https://cloudimagelab-api.univerza.co` |
| `CLOUDIMAGELAB_API_KEY` | **ใช่** | key ของแอป (staging กับ production คนละตัว) |
| `CLOUDIMAGELAB_CALLBACK_BASE_URL` | ไม่ | URL สาธารณะของ backend (ไม่มี `/` ท้าย) เช่น `https://stg-chatcore-api.mrfox.store` ระบบจะต่อ `/api/webhooks/cloudimagelab?type=...&secret=...` ให้เอง |
| `CLOUDIMAGELAB_CALLBACK_TYPE` | ไม่ | ค่า `type` ใน callback (ยังไม่มีคำยืนยันจากทีม ค่าเริ่มต้นที่ใช้: `avatar`) |
| `CLOUDIMAGELAB_CALLBACK_SECRET` | **ใช่** | ค่า `secret` ใน callback ใช้ค่าสุ่มของเราเอง ไม่ใช่ API key (ค่าที่ทีมกำหนดต้องตรงกัน) |
| `CLOUDIMAGELAB_AVATAR_PRESET` | ไม่ | ชื่อ preset ของรูปโปรไฟล์ (ค่าเริ่มต้น `thumb_sq` 150×150 crop) |
| `AVATAR_SOURCE_BUCKET` | ไม่ | bucket รูปต้นฉบับ: `mf-share` |
| `AWS_REGION` | ไม่ | `ap-southeast-7` |
| `MEDIA_KEY_PREFIX` | ไม่ | โฟลเดอร์โปรเจกต์ใน bucket (ค่าเริ่มต้น `catlive`) |
| `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` | **ใช่** | IAM user `share-s3-b-mf-share` ใช้ออก presigned URL เท่านั้น |

ถ้าตัวแปรที่จำเป็นขาด `POST /media/avatar` จะตอบ 503 และไม่เขียนไฟล์

## ความปลอดภัย

- key ทั้งหมดอยู่ฝั่ง server เท่านั้น ห้ามใส่ในแอป
- ตรวจ `secret` ใน query ด้วยการเทียบแบบ constant-time ก่อนทำอะไร callback ซ้ำ fileId เดิมไม่เปลี่ยนผลเดิม
- `secret` อยู่ใน URL จึงอาจโผล่ใน access log ของ proxy/เซิร์ฟเวอร์ ควรปิด/ตัด query ออกจาก log และหมุนค่าหากสงสัยว่าหลุด
- แอปลบ GPS/EXIF ก่อนส่ง แต่ฝั่ง server ต้องไม่เชื่อฝั่งแอปอย่างเดียว
- CloudImageLab ตัดสินชนิดไฟล์จากไบต์จริง ไฟล์ที่ไม่ใช่รูปจะล้มเหลวโดยไม่ลองซ้ำ (ได้ callback สถานะ Failed)

## สิ่งที่ต้องมีก่อนใช้งานบน staging

1. ค่าตัวแปรตามตารางด้านบนตั้งใน CI/CD (รวม AWS key ของ IAM user)
2. migration `20261117150000_avatar_media` รันบนฐาน staging แล้ว
3. backend ที่ deploy แล้วและเข้าถึงจากอินเทอร์เน็ตได้ (CloudImageLab ต้องเรียก callback ได้)
4. preset `thumb_sq` มีอยู่ในการตั้งค่าแอปของเราที่ CloudImageLab
5. ผู้ดูแล CloudImageLab ตั้ง storage profile ของแอปเรา (bucket `mf-share`, prefix `catlive/`, `cdnBaseUrl` เป็น CloudFront ข้างบน) เพื่อให้อ่านรูปต้นฉบับและเขียนรูปที่ประมวลผลแล้วได้

# แอปแมว.live (Flutter)

แอปมือถือหลักของแมว.live — Flutter 3.47 / Dart 3.13, Clean Architecture, เรียก API ด้วย `dio`, state ด้วย `flutter_riverpod`, นำทางด้วย `go_router`
หมายเหตุ: โฟลเดอร์ `../mobile/` คือต้นแบบ Expo เดิม (ยังเก็บไว้อ้างอิง ไม่ได้พัฒนาต่อ)

## คำสั่งที่ใช้

```bash
flutter pub get
flutter analyze            # ต้อง "No issues found"
flutter test               # ต้องผ่านทุกเคส
dart format lib test
flutter run -d <device> --route=/community       # เปิดแอปที่หน้าฟีดตรง ๆ
flutter run --dart-define=USE_MOCK_DATA=false --dart-define=API_BASE_URL=https://...   # ต่อ API จริง
```

ก่อนบอกว่างานเสร็จ ให้รัน `flutter analyze` และ `flutter test` ทุกครั้ง

## โครงสร้าง (feature-first + clean 3 ชั้น)

```
lib/
  core/            theme, network (dio + interceptors), error (Failure), router, widgets กลาง
  features/<ชื่อ>/
    domain/        entities, repositories (interface), usecases   ← ห้ามพึ่ง Flutter/dio
    data/          models (JSON→entity), datasources (mock + dio), repositories (impl)
    presentation/  providers (Riverpod), pages, widgets
```

- ชั้น `domain` ห้าม import `flutter` หรือ `dio`; ชั้น `presentation` เรียกข้อมูลผ่าน use case เท่านั้น
- `DioException` ต้องถูกแปลงเป็น `Failure` (ข้อความไทย) ที่ชั้น `data` — หน้าจอไม่รู้จัก dio
- ข้อมูล mock อยู่หลัง `FeedRemoteDataSource` สลับเป็น `DioFeedDataSource` ด้วย `--dart-define=USE_MOCK_DATA=false` โดยไม่แก้หน้าจอ
- รูปแบบ JSON ที่ API ต้องส่งดูได้จาก `data/models/*_models.dart` (อิง `../docs/data-schema.md`)

## มาตรฐานหน้าจอ

- ตรงกับเว็บ prototype จริงที่ `www.แมว.live` (`https://www.xn--y3cm0f.live`) เป็นหลัก ทั้งสี, ฟอนต์, ขนาด, สถานะปุ่ม, ข้อความ และแอนิเมชัน (เทียบหน้าเว็บจริงก่อน `../docs/design-spec.md` เสมอ) — ค่าสีอยู่ใน `core/theme/app_colors.dart` ห้าม hardcode สีในหน้าจอ
- ปุ่มกดทุกปุ่ม ≥ 44pt และมี `Semantics` label ภาษาไทย
- ทุกจอที่มีข้อมูลต้องครบ 4 สถานะ: loading (skeleton ไม่ใช้ spinner), empty, error (มีปุ่มลองใหม่), content
- ลิสต์ยาวใช้ `ListView.builder` + แบ่งหน้า 15-20 รายการ (mock ใช้ 5)
- ปุ่มที่เปลี่ยนสถานะ (ไลก์/เซฟ/ติดตาม/ซ่อน) ต้อง optimistic และย้อนกลับพร้อมแจ้งผู้ใช้เมื่อ API ล้มเหลว
- ข้อความบนหน้าจอเป็นภาษาไทยเป็นหลัก

## ความปลอดภัย

- token ห้ามเก็บใน `shared_preferences`/ไฟล์ธรรมดา — ใช้ `flutter_secure_storage` (Keychain/Keystore) ตอนทำล็อกอิน (ที่ต่อไว้แล้ว: `TokenProvider`)
- รูปที่อัปโหลดต้องลบ GPS ใน EXIF ก่อนส่ง; ฟิลด์ลับ (ที่อยู่ เลขบัญชี พิกัดละเอียด) ห้ามแสดงบนหน้าสาธารณะ
- `RetryInterceptor` ส่งซ้ำเฉพาะ GET/HEAD/PUT/DELETE — ห้ามส่งซ้ำ POST เพราะอาจทำรายการซ้ำ

## ยังไม่ทำ (ใส่เมื่อถึงเฟส)

Backend จริง (NestJS), ล็อกอิน, Biometric, SSL Pinning, integration test (E2E) — ใส่ตอนใกล้ขึ้น Store

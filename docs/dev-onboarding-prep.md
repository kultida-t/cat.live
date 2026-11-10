# เตรียมตัวเป็น Dev — เตรียมคุยกับพี่คิง

> **สถานะ:** เตรียมประชุม — พี่มาเต็มย้ายจากบทบาท BA มาเป็น Dev
> **จัดทำเมื่อ:** 2026-11-10
> **อิงจาก:** คำแนะนำเพื่อน Dev + เอกสาร `dev-roadmap.md` / `backend-architecture.md` / `env-setup.md`

---

## 1. Stack มาตรฐานทีม (เพื่อน Dev แนะนำ — รอยืนยันพี่คิง)

| ส่วน | เทค | หมายเหตุ |
|---|---|---|
| Git | GitLab บริษัท (`git.mrfox.store`) | เราใช้อยู่แล้ว ✅ |
| AI/Dev tool | แล้วแต่คน — พี่มาเต็ม: Devin (+ Antigravity) | ไม่กระทบโค้ดที่ส่งให้ทีม เลือกตามถนัดได้ |
| หน้าเว็บ | **Next.js เวอร์ชันล่าสุด** | โครงแบบ component, เน้น **SSR** (render ฝั่ง server) เพื่อความปลอดภัย — ข้อมูลสำคัญไม่โป๊ะฝั่ง client |
| API / Service | **.NET 10** | สถาปัตยกรรม **Clean Architecture** (แยกชั้น Domain→Application→Infrastructure→API) |
| Auth | **OAuth ผ่าน Keycloak ของบริษัท** | SSO ตัวเดียวกับ UGC — ตรงมาตรฐาน U-05 Unified Identity เลย |
| CSS | **Tailwind** | ตรงกับ prototype ที่ใช้ Tailwind v4 อยู่แล้ว ✅ |

## 2. เครื่องมือช่วงต้น — อะไรควรเหมือนกันทุกคน อะไรแล้วแต่คน

**ควรเหมือนกันทุกคน (standard kit):**
- Git + GitLab บริษัท + กฎ branch เดียวกัน
- **SDK/Runtime เวอร์ชันเดียวกัน** — .NET 10 SDK, Node.js LTS (สำหรับ Next.js tooling)
- ฐานข้อมูล + โปรแกรมจัดการตัวเดียวกัน (PostgreSQL + pgAdmin — ใน `env-setup.md` แล้ว)
- Lint/format rules เดียวกัน (โค้ดหน้าตาเหมือนกัน รีวิวง่าย)
- API client ตัวเดียวกัน (Postman หรือ Bruno)
- สิทธิ์เข้าบริการกลาง: UGC, CloudImageLab, Today
- การเขียนเอกสาร/อัปโหลดขึ้น UGC ตามกติกาประเมินคะแนนใหม่ (3 หมวดบังคับ)

**แล้วแต่คนได้:** AI tool (Devin/Antigravity/Cursor), ธีมจอ, plugin IDE, เครื่องมือเสริมส่วนตัว — ขอแค่ส่งออกมาเป็นโค้ด+เอกสารมาตรฐานเดียวกัน

## 3. ขั้นตอนเตรียมตัวเป็น Dev (เรียงลำดับ)

| ลำดับ | ทำอะไร | สถานะ |
|---|---|---|
| 1 | ยืนยัน stack มาตรฐานกับพี่คิงในที่ประชุม | ⏳ รอประชุม |
| 2 | เช็กเครื่องมือใน `env-setup.md` — มีครบเกือบหมดแล้ว เหลือ **.NET 10 SDK** (ถ้าล็อก .NET) + Node LTS | 🟡 บางส่วนแล้ว |
| 3 | ลงทะเบียนแอป `cat-live` ใน UGC BackOffice | ⏳ ค้างอยู่ — ค่าที่จะกรอกเตรียมไว้แล้ว |
| 4 | อัปโหลดเอกสารครบ 3 หมวดใน UGC เพื่อประเมินคะแนน (PRD=PDF ของ BA, Feature Spec=design-spec, Architecture=backend-architecture, เสริม data-schema→Database & ERD) | ⏳ รอข้อ 3 |
| 5 | ปรับเอกสาร stack ตามที่ล็อก (roadmap+architecture ยังเขียนเป็น NestJS/Expo — แก้เมื่อได้คำตอบ) | ⏳ รอข้อ 1 |
| 6 | ตั้งโครง repo: `apps/web` (Next.js) + `apps/api` (.NET Clean Arch) + `packages/shared` | ⏳ รอข้อ 1 |
| 7 | งานชิ้นแรกแบบ vertical slice เล็ก ๆ + พี่เลี้ยงช่วยรีวิว | ⏳ ถามในประชุม |

## 4. คำถามเอาไปถามพี่คิงในที่ประชุม

1. **ล็อก stack ตามเพื่อนแนะนำเลยไหม?** (Next.js SSR + .NET 10 Clean Architecture + Keycloak + Tailwind) — หนูเห็นว่าเหมาะมาก: prototype เราเป็น Next.js+Tailwind อยู่แล้ว ต่อยอดได้เลย และ Keycloak ก็คือ Unified Identity ตามมาตรฐาน U-05
2. **แมว.live เป็น web app (Next.js) หรือ native mobile (Expo)?** — หนูเสนอ web-first ไปก่อนเพราะ prototype เดิมเป็น mobile-first web อยู่แล้ว ทำ PWA ให้ทำหน้าที่เหมือนแอปได้ ถ้าวันหน้าจำเป็นค่อยทำ native
3. **ต่อ Keycloak บริษัทตั้งแต่แรกเลยไหม?** — ถ้าใช่ เรื่องข้อ 1 ที่ค้างถามใน dev-roadmap (self-contained vs Gateway) ก็ตอบตัวเองเลย = ต่อเลย
4. **พี่เลี้ยงคือใคร?** — เสนอขอคนถนัด .NET + Clean Architecture หรือทีมระบบกลาง UNIVERZA จะได้ถามมาตรฐาน U-xx ได้ด้วย และขอให้ช่วยรีวิว PR ช่วงแรก
5. **งานชิ้นแรกที่เหมาะคืออะไร?** — เสนอ vertical slice เล็ก: "โปรไฟล์แมว" (หน้าเว็บ → API → DB ครบวงจรชิ้นเดียว) เพราะเป็นศูนย์กลางที่ทุกฟีเจอร์อ้างถึง และไม่เสี่ยง privacy เท่าฟีเจอร์อื่น

## 5. หมายเหตุ

- คำตอบข้อ 1-3 จะทำให้ต้องแก้ `dev-roadmap.md` (ตาราง stack) และ `backend-architecture.md` (ชื่อเทค NestJS→.NET, Expo→Next.js) — โครงสร้างโมดูล/ตาราง/หลักการ privacy ใช้ได้เหมือนเดิม แค่เปลี่ยนชื่อเทคโนโลยี
- เอกสาร `env-setup.md` ต้องเพิ่มรายการ .NET 10 SDK + เครื่องมือฝั่ง Next.js หลังล็อก stack

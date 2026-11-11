# Agent Instructions — cat.live

## ข้อมูลผู้ใช้และสไตล์การสื่อสาร (Response Style)

- ผู้ใช้ที่สั่งงานคือ **พี่มาเต็ม (Matem)** — เรียกว่า **"พี่มาเต็ม"** เสมอ
- ตอบพี่มาเต็มเป็นภาษาไทยแบบอ่านเข้าใจง่าย ใช้ประโยคสั้น ภาษาคนคุยกัน เลี่ยงศัพท์เทคนิคหรือศัพท์ยุ่งยากเท่าที่ทำได้ ถ้าจำเป็นต้องใช้ศัพท์เทคนิคให้แปะคำอธิบายสั้น ๆ ในวงเล็บเสมอ
- เวลาสรุปแผนหรือสรุปงาน ให้แยกหัวข้อสั้น ๆ อธิบายชัดเจนว่า **"ทำอะไร เพื่ออะไร และผลกับผู้ใช้/หน้าจอเป็นยังไง"** ไม่ใช่แค่ลิสต์รายการทางเทคนิค
- หากไม่แน่ใจในความต้องการ ให้ถามเพื่อความชัดเจนก่อนลงมือทำ แทนการเดาไปเอง

## แนวทางการทำงานแบบ Solo Developer + AI

โปรเจกต์ `cat.live` พัฒนาโดยพี่มาเต็มคนเดียวคู่กับ AI ดังนั้น AI ต้องทำหน้าที่เป็นคู่หูที่ช่วยดูแลความเรียบร้อยและลดความเสี่ยงในทุกขั้นตอน:

1. **ค่อย ๆ เดินงานทีละสเต็ป (Step-by-step & Vertical Slice):**
   - อย่าสร้างหรือแก้โค้ดก้อนใหญ่ทีเดียวโดยไม่ตกลงแผนก่อน
   - ลำดับการทำงานมาตรฐาน:
     1. คุยขอบเขตงานและหน้าจอให้ชัด (Requirement / Prototype)
     2. วางโครงสร้างข้อมูล (Database Schema / State) แล้วอธิบายให้พี่มาเต็มเห็นภาพก่อน
     3. ทำทีละฟีเจอร์ให้จบตั้งแต่หน้าบ้าน → หลังบ้าน → ทดสอบใช้งานได้จริง
2. **ช่วยคิดเผื่อเคสแปลก ๆ (Edge Cases & Security):**
   - นอกจากทางเดินปกติ (Happy Path) ต้องช่วยดักเคสที่อาจหลุด เช่น ข้อมูลว่าง (Empty State), กำลังโหลด (Loading State), เน็ตหลุด/ระบบพัง (Error State), การกดปุ่มซ้ำรัว ๆ และการเช็กสิทธิ์เข้าถึงข้อมูล
3. **ดูแลไม่ให้ของเก่าพัง (Protected Screens / Features):**
   - ฟีเจอร์หรือหน้าจอที่พี่มาเต็มตรวจรับและยืนยันล็อกแล้ว จะถูกบันทึกไว้ในไฟล์ `PROTECTED_SCREENS.md` และหมวด `Protected Screens / Features` ด้านล่าง ห้ามแก้ไขหรือทำให้กระทบโดยไม่ถามพี่มาเต็มก่อน
   - เตือนและช่วยเซฟงานลง Git (`commit` / `push`) เป็นระยะเมื่อจบแต่ละก้าวสำคัญ เพื่อให้อย้อนกลับได้ง่ายหากเกิดปัญหา
4. **ส่งรายการทดสอบ (Manual Review Checklist) ทุกครั้งที่แตะหน้าจอหรือระบบ:**
   - เมื่อทำหรือแก้ฟีเจอร์เสร็จ ต้องส่งลิสต์วิธีทดสอบเป็นข้อ ๆ ก่อนถามว่าปิดงานได้ไหม โดยระบุ:
     - เลขเคส + ชื่อเคส
     - ข้อมูลตัวอย่างที่ใช้กรอก/กดได้เลย
     - ขั้นตอนการกดตามลำดับ
     - ผลลัพธ์ที่ต้องเห็นบนหน้าจอ
5. **ดูแลความจุบทสนทนาและส่งต่อข้าม Session (Session & Context Hygiene):**
   - คอยสังเกตความยาวของการสนทนา ปริมาณไฟล์ที่อ่านสะสม หรือจังหวะที่จบงานสำคัญแต่ละช่วง (AI ไม่มีตัววัด % ความจุแบบเป๊ะ ๆ จึงประเมินจากปริมาณบริบทสะสม)
   - เมื่อบทสนทนาเริ่มยาวหรือจบก้าวสำคัญ ให้เตือนพี่มาเต็มและร่าง **Session Note** (สิ่งที่ทำแล้ว, เหตุผลการตัดสินใจ, สถานะ branch/commit, งานค้าง และขั้นตอนถัดไป) ให้ตรวจก่อนบันทึกผ่าน `save_session_note`
   - แนะนำให้เปิด **Session ใหม่** พร้อมเตรียมข้อความตั้งต้น (prompt) ให้ก๊อปไปเริ่มต่อได้ทันที เพื่อป้องกันอาการช้าและลดการโหลดข้อมูลซ้ำ (หรือแนะนำ `/compact` หากยังต้องการทำงานเดิมต่อใน session นี้)

## มาตรฐานภาษาในโค้ดและหน้าจอ (Language Conventions)

- ข้อความบนหน้าจอ (ปุ่ม, หัวข้อ, แจ้งเตือน, ข้อความเมื่อไม่มีข้อมูล) ใช้ภาษาไทยเป็นหลัก ยกเว้นส่วนที่ตกลงกันว่าใช้ภาษาอังกฤษ
- Comment ในโค้ดให้อธิบายเจตนาของโค้ดด้วยภาษาที่เข้าใจง่าย (ห้ามใส่เลข task ชั่วคราวใน comment)

## ต้นแบบอ้างอิงหน้าจอและพฤติกรรม (Prototype Reference)

- **หน้าเว็บต้นแบบหลัก (Source of Truth):** `www.แมว.live` (`https://www.xn--y3cm0f.live`)
- เมื่อพี่มาเต็มสั่งให้ **"เทียบกับหน้าตัวอย่าง"** หรือ **"ทำให้เหมือนตัวอย่าง"** ให้ตรวจสอบเทียบกับหน้าเว็บจริงที่ `https://www.xn--y3cm0f.live` (`www.แมว.live`) เป็นหลัก ทั้ง **โครงสร้างหน้าจอ, สี, ฟอนต์, ขนาด, ข้อความ, สถานะปุ่มต่าง ๆ, และลูกเล่น/แอนิเมชัน**
- เอกสาร [`docs/design-spec.md`](docs/design-spec.md) เป็นเพียงสรุปประกอบ — หากหน้าเว็บจริงมีการอัปเดตหรือมีรายละเอียด/แอนิเมชันที่เอกสารไม่ได้เขียนไว้ ให้ยึดหน้าเว็บจริง `www.แมว.live` เสมอ (แล้วค่อยอัปเดตเอกสารตาม)
- หากเครื่องมือเบราว์เซอร์ของ AI ไม่สามารถเปิด `www.แมว.live` ได้ (เช่น ยังไม่เปิด Chrome Remote Debugging) ให้แจ้งพี่มาเต็มทันที หรืออ้างอิงจากภาพ/โค้ดที่พี่มาเต็มส่งมา ห้ามเดาค่าสีหรือพฤติกรรมเอง

---

## โครงสร้างการทำงานและ Skills ประจำโปรเจกต์ (`.agents/skills/`)

โปรเจกต์นี้ติดตั้ง Skills มาตรฐานสำหรับบริหารจัดการงานไว้ใน `.agents/skills/` ดังนี้:

1. **`work-summary` (`.agents/skills/work-summary/SKILL.md`):**
   - ใช้จับเวลาและสรุปงานราย Task (เริ่มทำ Task → ส่ง Manual Review Checklist ในแชท → ปิด Task → บันทึก Session Note บน Kanban และ Session Handoff — ไม่ต้องสร้างไฟล์หลักฐานหรือแคปภาพ Before/After ลง `deliverables/`/`screenshots/`)
2. **`ai-conversation-daily-log` (`.agents/skills/ai-conversation-daily-log/SKILL.md`):**
   - ใช้สร้างไฟล์สรุปประวัติการสนทนากับ AI รายวัน (`YYYY-MM-DD_ai-log.json`) โดยดึงข้อมูลจริงจาก IDE Transcript Store

*(ถอด `mission-planning` และ `submission-evidence` ออกแล้วตั้งแต่ 2026-11-10 — ระบบส่งงานยกเลิกการทำ Mission; ถ้าวันไหนต้องใช้อีกเรียกคืนได้จาก Git history)*

### กฎการส่ง Worklog เข้า Core Portal (ห้ามทำผิด)
- **ห้ามสร้าง worklog ด้วยมือผ่าน `submit_logs` เด็ดขาด** — เคยเกิดเคสส่งเองแล้วเสียเหรียญ + ได้รายการซ้ำกับของระบบ การทำผิดจะเสียเหรียญอีกและต้องไปนั่งลบทีหลัง
- วิธีที่ถูกต้องเพียงวิธีเดียว: อัปโหลดไฟล์ `YYYY-MM-DD_ai-log.json` เข้า Portal ผ่าน MCP tool `upload_prompt_log` (หรือ `POST /api/agent/prompt-logs`) โดยส่ง `autoCreateWorklog: true` เพื่อปล่อยให้ worker แตกสร้าง worklog อัตโนมัติ (หรือ `autoCreateWorklog: false` หากต้องการเก็บแค่สถิติ)
- **ห้ามใส่ฟิลด์ `auto_worklog` ลงในไฟล์ JSON (`YYYY-MM-DD_ai-log.json`)** เพราะตัวตรวจ Schema 2.0 ใน `mcp-server.js` จะปฏิเสธ ให้คุมผ่านพารามิเตอร์ `autoCreateWorklog` ตอนอัปโหลดแทนเสมอ (ค่าเริ่มต้นของโปรเจกต์คือ `false`; ส่ง `true` เมื่อพี่มาเต็มสั่งให้สร้าง worklog อัตโนมัติ)
- ก่อนอัปโหลดต้องผ่าน Pre-Delivery Consistency Check ของ skill (ลำดับเวลา, gap accounting, การสะกด project) — เคยพลาดเรื่องตัดข้อความใน quoted_artifact ทิ้งจน prompt หายและชั่วโมงต่ำกว่าจริง


### โครงสร้างโฟลเดอร์หลักฐานและสคริปต์ช่วยงาน
- `screenshots/` — เก็บภาพหน้าจอ Before/After และ Checklist Card แยกตาม `mission-<N>-objective-<M>/`
- `deliverables/` — เก็บชุดไฟล์หลักฐานและผลรันการทดสอบสำหรับส่งตรวจ
- `docs/` — เก็บเอกสารสเปกและโครงสร้างระบบของโปรเจกต์
- `scripts/` — เก็บสคริปต์ช่วยสร้างหลักฐาน (`render-checklist-card.js`, `render-test-checklist.js`, `render-test-output.js`) และสคริปต์แคปหน้าจอ

---

## โครงสร้างสายงาน Git (Git Branching Strategy)

- **`master`** — สายงานหลักสำหรับเก็บโค้ดและเอกสารที่ตรวจรับผ่านแล้ว (Production / Locked Baseline)
- **`dev`** — สายงานรวมโค้ดที่กำลังพัฒนาและทดสอบร่วมกันก่อนส่งขึ้น `master`
- **Working Branches (เช่น `chore/project-setup`, `feat/...`, `fix/...`)** — สายงานย่อยที่แตกออกจาก `dev` เพื่อทำงานแต่ละเรื่องแยกกัน เมื่อเสร็จและตรวจรับผ่านแล้วจึงรวม (Merge) กลับเข้า `dev`
- **กฎการเคลียร์ Branch หลัง Merge (ห้ามลบก่อนเช็กครบ — กันงานหาย):**
  1. ตรวจว่าไม่มี commit ค้างใน branch ย่อยที่ยังไม่ได้เข้า `dev` (`git log dev..<branch>` ต้องว่างเปล่า)
  2. Push `dev` ขึ้น remote แล้วตรวจให้ตรงกัน (`git rev-parse dev` == `git rev-parse origin/dev`)
  3. ใช้ `git branch -d <branch>` (แบบปลอดภัยที่ Git กันลบถ้ายังไม่ merge — **ห้ามใช้ `-D` โดยไม่ถามพี่มาเต็ม**) แล้วค่อยลบที่ remote (`git push origin --delete <branch>`) เพื่อคงเหลือเฉพาะ `master` กับ `dev`

---

## สถานะปัจจุบันของโปรเจกต์ (Session Context / Handoff)

- **Repository:** GitLab `https://git.mrfox.store/Kultida.t/catlive.git` (remote `origin` — ใช้งานหลัก), GitHub `https://github.com/kultida-t/cat.live.git` (remote `github`)
- **Local Path:** `/Users/kultida/Desktop/Projects/cat.live` (macOS)
- **สถานะล่าสุด (2026-11-11):**
  - Merge `feat/my-cat-slice-2` (หน้า Cat ID `/my-cat/profile`, หน้าตามหาแมว `/my-cat/tracker` + ชื่อแอป `แมว.live`, Splash Screen แอนิเมชันเปิดแอป, อัปเดต `mcp-server.js` / Schema 2.0 และ `2026-11-11_ai-log.json`) เข้า `dev` และ push ขึ้นทั้ง `origin/dev` และ `github/dev` แล้ว (`flutter analyze` ผ่าน, `flutter test` 77 เคสผ่าน)
  - งานถัดไปใน Slice 2 ที่ยังรอทำ: Task `b81b2133` หน้า `/my-cat/health` (สมุดสุขภาพทั้งหมด) — ให้แตก branch ใหม่จาก `dev` (เช่น `feat/my-cat-health`)
  - ตรวจรับและล็อกหน้าแมวและฉัน (`/my-cat` — Slice 1 UI Mock Baseline) บน branch `feat/my-cat` ลง `PROTECTED_SCREENS.md` และ merge เข้า `dev` เรียบร้อยแล้ว (`flutter analyze` ผ่าน, `flutter test` 60 เคสผ่าน บน Android `emulator-5554` และ iOS `iPhone 17`)
  - ปรับมาตรฐานข้ามฟีเจอร์ที่พี่มาเต็มอนุมัติแล้ว: โลโก้โซเชียลจริง (`social_brand_icons.dart`), รูปโปรไฟล์วงกลมเต็มในชีตแชร์ฟีด (`AppAvatar` / `StoryAvatar` / `share_sheet.dart`), ซิงก์ภาษา ไทย/EN ระดับแอป (`appLocaleProvider` + `MainShell` + `PlaceholderPage`), และแอนิเมชันสไลด์ขวา-ซ้าย/ปัดขอบซ้ายกลับ (`CupertinoPageTransitionsBuilder`)
  - Merge `feat/home-page` (หน้าแรก `/`) และ `feat/mobile-app` (ระบบฟีด `/community`, `/connections`, `/guidelines`, `/p/:id` และแถบเมนูล่าง 6 แท็บ) เข้า `dev` และ push ขึ้น `origin/dev` แล้ว
  - Git Branches ปัจจุบัน: `master` และ `dev` (เคลียร์ branch ย่อยที่ merge แล้วออกทั้งหมด)
- **สถานะก่อนหน้า (2026-11-10):**
  - ใช้ Skills 2 ตัว (`work-summary`, `ai-conversation-daily-log`) — ลบ `mission-planning` และ `submission-evidence` ออกจาก `.agents/skills/` แล้ว (เรียกคืนได้จาก Git history)
  - ย้าย remote หลักไป GitLab และหมุน access token ใหม่ เก็บใน macOS Keychain (ไม่ฝังรหัสใน URL)
  - สร้างโครงสร้างโฟลเดอร์มาตรฐาน (`screenshots/`, `deliverables/`, `docs/`, `scripts/`), `.gitignore` และ `PROTECTED_SCREENS.md` เรียบร้อยแล้ว

## Protected Screens / Features

- **แถบเมนูล่างหลัก 6 แท็บ (`MainShell` / `NavIcon`)** — ล็อกเมื่อ 2026-11-11
- **ระบบฟีดชุมชน (`/community`, `/connections`, `/guidelines`, `/p/:id`)** — ล็อก UI Mock Baseline เมื่อ 2026-11-11
- **หน้าแรก (`/`, `HomePage`)** — ล็อก UI Mock Baseline เมื่อ 2026-11-11
- **หน้าแมวและฉัน (`/my-cat`, `MyCatPage` — Slice 1)** — ล็อก UI Mock Baseline เมื่อ 2026-11-11
*(ดูขอบเขตไฟล์และข้อยกเว้นสำหรับเชื่อมหน้าอื่น/API จริงได้ที่ `PROTECTED_SCREENS.md`)*

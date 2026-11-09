# Environment Setup — cat.live Mobile App (macOS)

> **สถานะ:** พร้อมใช้งาน — เขียนขึ้น 2026-11-09 เพื่อย้ายไปติดตั้งบนเครื่อง Mac ที่พัฒนา iOS + Android ได้ทั้งคู่
> **Stack เป้าหมาย:** React Native (Expo) + TypeScript — ยังไม่ล็อกสุดท้าย รอสรุป requirement อย่างเป็นทางการ (ดู `docs/questions-for-ba.md`)
> **วิธีใช้:** สั่ง AI agent บนเครื่องใหม่ว่า "อ่าน `docs/env-setup.md` แล้วติดตั้ง environment ตามนั้นให้ครบ มีอะไรมีอยู่แล้วข้ามได้ อันไหนต้องใช้รหัสผ่าน/ล็อกอินบอกฉันทำเอง"

---

## 0. กฎสำหรับผู้ติดตั้ง (สำคัญ)

- **เช็กก่อนลงเสมอ** — รันคำสั่ง verify ของแต่ละตัวก่อน ถ้ามีอยู่แล้วให้ข้าม ห้ามลงซ้ำ
- **ห้ามพิมพ์รหัสผ่าน** — คำสั่งที่ต้อง `sudo` หรือล็อกอินบัญชี (Apple ID, Expo, GitHub) ให้หยุดและให้เจ้าของเครื่องทำเอง แล้วค่อยทำต่อ
- **ลงตามลำดับ** — กลุ่มที่ 1 ต้องเสร็จก่อนกลุ่มถัดไป เพราะเป็น dependency ของกันและกัน

---

## 1. ลำดับติดตั้ง

### กลุ่ม 1 — เครื่องมือพื้นฐานของ Mac (ลงก่อนสุด)

| # | เครื่องมือ | ไว้ทำอะไร | คำสั่ง/วิธีลง | คำสั่งเช็ก |
|---|---|---|---|---|
| 1 | **Xcode** | บังคับสำหรับ iOS — compiler, iOS Simulator, sign แอป (~10GB โหลดนาน เริ่มก่อนเลย) | App Store หรือ developer.apple.com — **ต้องล็อกอิน Apple ID เอง** | `xcodebuild -version` |
| 2 | **Xcode Command Line Tools** | เครื่องมือพื้นฐาน (git, compiler) ที่ตัวอื่นอาศัย | `xcode-select --install` | `xcode-select -p` |
| 3 | **Homebrew** | ตัวติดตั้งโปรแกรมหลัก — ใช้ลงข้อ 4-8 ทั้งหมด | `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"` — อาจขอรหัสเครื่อง ให้เจ้าของพิมพ์ | `brew --version` |

> หลังลง Xcode เสร็จ ให้เปิดโปรแกรมครั้งหนึ่งเพื่อกดยอมรับ license + ให้มันติดตั้ง component เพิ่ม (ขั้นนี้บ่อยครั้งที่คนลืมแล้ว build พัง)

### กลุ่ม 2 — ผ่าน Homebrew

| # | เครื่องมือ | ไว้ทำอะไร | คำสั่ง | คำสั่งเช็ก |
|---|---|---|---|---|
| 4 | **Node.js LTS** | รัน JavaScript — หัวใจของ Expo/RN | `brew install node@22` | `node --version` (ควรได้ v22.x) |
| 5 | **Watchman** | เฝ้าไฟล์เปลี่ยน ทำ hot reload เร็ว | `brew install watchman` | `watchman --version` |
| 6 | **JDK 17** | จำเป็นตอน build Android | `brew install --cask zulu@17` | `java -version` (17.x) |
| 7 | **Android Studio** | Android SDK + Emulator + จัดการ SDK | `brew install --cask android-studio` | เปิดโปรแกรมผ่าน setup wizard |
| 8 | **CocoaPods** | จัดการ library ฝั่ง iOS (จำเป็นตอน dev build) | `brew install cocoapods` | `pod --version` |

> หลังลง Android Studio ให้เปิดโปรแกรมผ่าน setup wizard ครั้งแรก — มันจะดึง Android SDK, platform-tools, system image ให้อัตโนมัติ

### กลุ่ม 3 — ผ่าน npm + ตั้งค่าระบบ

| # | เครื่องมือ | ไว้ทำอะไร | คำสั่ง | คำสั่งเช็ก |
|---|---|---|---|---|
| 9 | **EAS CLI** | build แอปบนคลาวด์ Expo | `npm install -g eas-cli` | `eas --version` |
| 10 | **Environment variables** | ให้ terminal หา adb/emulator เจอ | เติมใน `~/.zshrc` ดูด้านล่าง | `adb --version`, `emulator -list-avds` |

เติมบรรทัดนี้ท้ายไฟล์ `~/.zshrc`:

```bash
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator
```

แล้ว `source ~/.zshrc` หรือเปิด terminal ใหม่

> หมายเหตุ: **ไม่ต้องลง Expo CLI แยก** — สมัยนี้ใช้ `npx expo` ที่มากับโปรเจกต์

### กลุ่ม 4 — Editor + เครื่องมือจำลอง + มือถือจริง

| # | ของ | วิธี | เช็ก |
|---|---|---|---|
| 11 | **Devin Desktop** (editor หลักของทีม) | โหลดและล็อกอินบัญชีเดียวกับเครื่องเดิม — extensions แนะนำ: ESLint, Prettier | เปิด workspace ได้ |
| 12 | **Android Emulator (AVD)** | Android Studio → Device Manager → Create Device (แนะนำ API 34+) | `emulator -list-avds` เห็นชื่อ |
| 13 | **iOS Simulator** | มากับ Xcode (Xcode → Settings → Platforms ถ้าขาด) | `xcrun simctl list devices` |
| 14 | **Expo Go บนมือถือจริง** | โหลดจาก App Store (iPhone) / Play Store (Android) — **เจ้าของทำเอง** | เปิดแอปขึ้นมาได้ |

### กลุ่ม 5 — เช็กรวมทีเดียว (ขั้นยืนยันสุดท้าย)

```bash
npx expo-doctor
```

ถ้าผ่านเกือบหมด/หมด = environment พร้อม

---

## 2. สิ่งที่ต้องใช้มือเจ้าของเครื่องทำเอง (AI ทำให้ไม่ได้)

1. **ล็อกอิน Apple ID** — โหลด Xcode จาก App Store, ใช้งาน iOS Simulator/signing
2. **พิมพ์รหัสผ่านเครื่อง** — ตอน Homebrew install และคำสั่งที่ขอ sudo
3. **สมัคร/ล็อกอินบัญชี Expo** — expo.dev (ฟรี) แล้ว `eas login` + `npx expo login`
4. **โหลด Expo Go ลงมือถือ** — App Store / Play Store
5. **Git credentials** — ตั้ง SSH key หรือ HTTPS token สำหรับ clone/push repo

---

## 3. บัญชี / บริการภายนอก (สมัครล่วงหน้า)

| บริการ | ค่าใช้จ่าย | สมัครได้เลย? | ผูกคำถาม BA |
|---|---|---|---|
| **Expo / EAS** | ฟรี (มีแพลนเสียเงินสำหรับ build เยอะ) | ✅ ได้เลย | — |
| **Apple Developer Program** | ~$99/ปี | ⏸ รอ | ข้อ 26 — จดนามใคร ใครจ่าย |
| **Google Play Console** | $25 ครั้งเดียว | ⏸ รอ | ข้อ 26 — เหมือนกัน |
| **Google Maps API key + billing** | มี free tier ต่อเดือน เกินแล้วจ่ายตามใช้ | ⏸ รอเจ้าของ (dev ใช้ key ชั่วคราวได้) | ข้อ 22 — ใครเปิด key/ผูก billing |
| **Firebase / FCM** (push notification) | ฟรี | ⏸ รอตัดสินใจ infra | ข้อ 27 + ข้อ 33 (นโยบาย push) |
| **Payment gateway** | ตาม provider | ⏸ รอ | ข้อ 14 |
| **AI provider** (Cat AI) | ตาม usage | ⏸ รอ | ข้อ 9 |
| **Apple Sign-In** | มากับ Apple Developer | ⏸ รอ | ข้อ 4 — login ด้วยอะไร |

---

## 4. Hello World — ยืนยันว่าระบบใช้ได้จริง

ทำหลังกลุ่ม 1-5 ครบ:

```bash
npx create-expo-app@latest cat-live-app
cd cat-live-app
npx expo start
```

แล้วตรวจ 3 จุด:

- [ ] **Expo Go บนมือถือจริง** — สแกน QR ใน terminal → เห็นหน้าแอปตัวอย่าง (ต้องอยู่ Wi-Fi เดียวกับเครื่อง)
- [ ] **Android Emulator** — กด `a` ใน terminal → แอปเปิดบน emulator
- [ ] **iOS Simulator** — กด `i` ใน terminal → แอปเปิดบน simulator

> ตำแหน่งโปรเจกต์: ยังไม่ล็อก — แนะนำคุยก่อนว่าจะเป็น subfolder `app/` ใน repo `cat.live` เดิม หรือ repo ใหม่แยก (เอกสาร/spec อยู่ repo นี้)

---

## 5. ทำได้เลย vs ต้องรอ requirement นิ่ง

**ทำได้เลย (ไม่ขึ้นกับ BA):**
- ติดตั้งเครื่องมือทุกตัวในส่วนที่ 1
- สมัครบัญชี Expo/EAS ฟรี
- สร้างโปรเจกต์ Expo + รัน Hello World บน Expo Go/emulator ทั้งสองระบบ
- วางโครง theme object จาก design tokens ใน `docs/design-spec.md`

**รอ requirement/เจ้าของบัญชีก่อน:**
- สมัคร Apple Developer / Play Console (มีค่าใช้จ่าย + ต้องรู้จดนามใคร — ข้อ 26)
- สร้าง Google Cloud project + Maps key ที่ผูก billing จริง (ข้อ 22)
- ตั้ง Firebase project (ข้อ 27)
- เลือก payment gateway / AI provider (ข้อ 14, 9)
- ตัดสินใจ Expo Go vs Development Build — push notification (SDK 53+) และ BLE สำหรับ Tag ต้องออกจาก Expo Go อยู่แล้ว แต่รอ spec Tag จริงก่อน (ข้อ 11-12)

---

## 6. ปัญหาที่เจอบ่อย (กันไว้ก่อน)

| อาการ | สาเหตุที่เจอบ่อย | แก้ |
|---|---|---|
| `adb: command not found` | ยังไม่ได้ตั้ง PATH หรือยังไม่ source ~/.zshrc | เช็กข้อ 10 |
| iOS build พังทั้งที่ Xcode ลงแล้ว | ไม่ได้เปิด Xcode ยอมรับ license / ลง component เพิ่ม | เปิด Xcode 1 ครั้ง |
| สแกน QR แล้ว Expo Go ไม่เจอ | มือถือกับเครื่องคนละ Wi-Fi | ใช้ `npx expo start --tunnel` |
| `pod install` พัง | CocoaPods ยังไม่ลงหรือเก่า | ข้อ 8 / `pod repo update` |
| มือถือ Android เชื่อม adb ไม่ได้ | ยังไม่เปิด USB debugging | เปิด Developer options ในมือถือ |

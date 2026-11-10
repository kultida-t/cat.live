This is an Expo/React Native mobile application. Prioritize mobile-first patterns, performance, and cross-platform compatibility.

## Expo has changed — do not trust your training data

Expo ships breaking changes every SDK release. APIs you remember are likely renamed, moved, or removed. Before writing any code that touches an Expo, EAS, or React Native API:

1. Read the major version of the `expo` package in `package.json`.
2. Fetch the matching versioned docs: `https://docs.expo.dev/versions/v<major>.0.0/`
3. For anything else, fetch https://docs.expo.dev/llms.txt — an index of all Expo docs with corrections to common LLM misconceptions. Follow its links to the specific page you need; never answer from memory.

## Commands

Use `bunx` instead of `npx` if the project uses bun (`bun.lock` present).

```bash
npx expo install <package>  # ALWAYS use instead of npm/yarn/pnpm/bun add — resolves SDK-compatible versions
npx expo start              # start the dev server
npx expo lint               # lint
npx tsc --noEmit            # typecheck
npx expo-doctor             # diagnose dependency and config issues
npx expo install --fix      # fix incompatible package versions
```

Run lint and typecheck before declaring any task done.

## Navigation & Routing

- Use **Expo Router** for all navigation. Routes live in `src/app/` — every file there is a screen, `_layout.tsx` files define navigators. Keep non-route code (components, hooks, utils) outside `src/app/`.
- Import `Link`, `router`, and `useLocalSearchParams` from `expo-router`.
- Docs: https://docs.expo.dev/router/introduction.md

## Building with EAS

Use EAS to build, sign, and submit the app in the cloud (`eas build`, `eas submit`) and to ship over-the-air updates (`eas update`) — no local Xcode or Android Studio required. Run EAS CLI as `bunx eas-cli <command>` in Bun projects, or `npx eas-cli@latest <command>` otherwise; substitute that for bare `eas` in docs examples.
Docs: https://docs.expo.dev/eas/index.md

## Rules

- If `ios/` and `android/` directories do not exist, they are generated (Continuous Native Generation). Never create or edit them by hand — configure native behavior in `app.json` and config plugins.
- Expo Go only includes its bundled native modules. After adding a library with native code, the app needs a development build: `npx expo run:ios|android` locally, or `eas build --profile development`.
- Prefer recommended Expo modules over third-party libraries, and check your available skills before adding dependencies. Docs: https://docs.expo.dev/versions/latest/index.md

---

# มาตรฐานคุณภาพประจำแอปแมว.live

กฎชุดนี้เป็นข้อตกลงการทำงานของแอปนี้ — ทำให้ดีตั้งแต่ชั้นโค้ด แต่ไส้ในระดับ infra ใส่เมื่อถึงเฟส (ตามแนวทาง "หน้าจอให้เห็นก่อน หลังบ้านตามทีหลัง" จากที่ประชุม 2026-11-10)

## โครงสร้างและข้อมูล

- แยกชั้นชัดเจน: `src/app/` = route เท่านั้น, `src/components/` = UI, `src/data/` หรือ `src/services/` = ข้อมูล+ตรรกะ, `src/types/` = TypeScript models
- Model หลักยึด `../docs/data-schema.md`; ทุก entity ต้องมี interface ไม่ใช้ `any`
- ข้อมูล mock ต้องอยู่หลัง interface/service ชัดเจน — หน้าจอเรียกผ่าน service เท่านั้น วันที่เปลี่ยนเป็น API จริงต้องแก้แค่ implementation เดียว

## หน้าจอและ UX

- ปุ่มกดทุกปุ่ม touch target ≥ 44pt, เว้น Safe Area บน-ล่างเสมอ
- ทุกจอที่มีข้อมูลต้องครบ 4 สถานะ: loading (skeleton ไม่ใช้ spinner), empty, error (พร้อมปุ่ม retry), content
- รายการยาวใช้ FlatList + pagination ทีละ 15-20 รายการ ห้าม map ลิสต์ยาวใน ScrollView
- ตัวหนังสือหน้าจอเป็นภาษาไทยเป็นหลัก ยกเว้นคำเทคนิค/ชื่อแบรนด์
- สีและสไตล์ใช้ token จาก `tailwind.config.js` (โทนครีม-เหลือง-น้ำตาลตาม `../docs/design-spec.md`) ห้าม hardcode hex ในหน้าจอ

## ความเสถียรและความปลอดภัย

- ทุก route หลักครอบ Error Boundary — จอพังต้องไม่ลากทั้งแอปดับ ให้แสดงหน้าจอ error พร้อมปุ่มลองใหม่
- ห้ามเก็บ token/ข้อมูลลับใน AsyncStorage ธรรมดา — ใช้ `expo-secure-store` (Keychain/Keystore) เมื่อถึงเฟสล็อกอิน
- รูปที่อัปโหลดต้องลบ GPS ใน EXIF ก่อนส่ง (privacy เป็น core ของแอปนี้)
- ฟิลด์ลับตาม requirement (ที่อยู่, เลขบัญชี, พิกัดละเอียดประกาศ) ห้าม render ออกหน้าจอสาธารณะ

## สิ่งที่ยังไม่ต้องทำ (ใส่เมื่อถึงเฟส)

- Backend จริง (ตัดสินใจแล้ว: NestJS) — ตอนนี้ mock ผ่าน service interface
- ล็อกอินจริง — ทำแบบแอปทั่วไปในเฟสถัดไป ไม่รอ UGC/Keycloak
- Biometric, SSL Pinning, E2E (Detox) — ใส่ตอนใกล้ขึ้น Store

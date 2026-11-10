/**
 * สีประจำแบรนด์แมว.live จาก docs/design-spec.md (โทนครีม-เหลือง-น้ำตาล)
 * ใช้กับจุดที่เขียน className ไม่ได้ เช่น NativeTabs, splash, config plugins
 * ส่วนหน้าจอทั่วไปให้ใช้ token เดียวกันผ่าน tailwind.config.js
 */
export const CatColors = {
  page: '#FFFCF3',
  card: '#FFFFFF',
  ink: '#4A3428',
  inkSecondary: '#5E4636',
  inkMuted: '#7A6255',
  inkAccent: '#6E4B00',
  btn: '#FFE89A',
  btnBorder: '#E6C24F',
  soft: '#FFF6D6',
  line: '#F1E6C6',
  lineStrong: '#E8D7A4',
  navTile: '#FFF1C9',
  unchecked: '#D4C4B8',
  danger: '#C0392B',
} as const;

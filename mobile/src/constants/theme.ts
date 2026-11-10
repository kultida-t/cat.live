/**
 * สีประจำแบรนด์แมว.live ดึงจากเว็บ prototype (www.แมว.live)
 * ใช้กับจุดที่เขียน className ไม่ได้ เช่น ไอคอน SVG, gradient, สีใน native component
 * ส่วนหน้าจอทั่วไปให้ใช้ token เดียวกันผ่าน tailwind.config.js
 */
export const CatColors = {
  page: '#FFFBF5',
  card: '#FFFFFF',
  text: '#4A3428',
  text2: '#5E4636',
  muted: '#7A6255',
  ink: '#5A4030',
  btn: '#FFF1E6',
  btnBorder: '#F2CFB4',
  soft: '#F6EFE6',
  line: '#F0E6DA',
  line2: '#E6D9C8',
  tile: '#DCEBFF',
  media: '#F3EDE6',
  heart: '#E2557A',
  unchecked: '#D4C4B8',
  danger: '#C0392B',
  navBackground: 'rgba(255,253,249,0.95)',
  ringUnseenFrom: '#B5C8EC',
  ringUnseenTo: '#8FA6DA',
} as const;

/** ชื่อ family ฟอนต์ IBM Plex Sans Thai Looped ที่โหลดไว้ใน root layout */
export const FontFamily = {
  regular: 'IBMPlexSansThaiLooped_400Regular',
  medium: 'IBMPlexSansThaiLooped_500Medium',
  semibold: 'IBMPlexSansThaiLooped_600SemiBold',
  bold: 'IBMPlexSansThaiLooped_700Bold',
} as const;

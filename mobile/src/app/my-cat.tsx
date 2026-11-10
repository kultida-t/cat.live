import { PlaceholderScreen } from '@/components/placeholder-screen';

export default function MyCatScreen() {
  return (
    <PlaceholderScreen
      title="แมวและฉัน"
      subtitle="โปรไฟล์ของฉันและแมวทุกตัว"
      notes={[
        'โปรไฟล์เจ้าของ — ยืนยันตัวตน บัญชีรับบริจาค ที่อยู่รับขนม (ลับ)',
        'โปรไฟล์แมวหลายตัว — Cat ID + QR และสมุดบันทึกสุขภาพ',
        'ตามหาแมว Find My + โหมดแมวหาย + เมนูร้านค้า (แท็ก/ปลอกคอ/ขนม)',
      ]}
    />
  );
}

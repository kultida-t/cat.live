import { PlaceholderScreen } from '@/components/placeholder-screen';

export default function NearbyScreen() {
  return (
    <PlaceholderScreen
      title="ใกล้ฉัน"
      subtitle="ค้นหาคาเฟ่ คลินิก และร้านค้ารอบตัว"
      notes={[
        'แผนที่เต็มจอ + หมวดลอย (คาเฟ่/คลินิก/ร้านค้า/ประกาศ/อาบน้ำตัดขน/รับฝาก)',
        'สลับมุมมอง แผนที่ ↔ รายการ',
        'หมุดร้านค้าที่มาลงโฆษณา (Business Model จากประชุม)',
      ]}
    />
  );
}

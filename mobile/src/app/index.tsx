import { PlaceholderScreen } from '@/components/placeholder-screen';

export default function HomeScreen() {
  return (
    <PlaceholderScreen
      title="แมว.live"
      subtitle="ภาพรวมแมวของฉันและทางลัดต่าง ๆ"
      notes={[
        'แมวของฉัน — การ์ดแมวพร้อมทางลัดสมุดสุขภาพ ประกาศ และแท็ก',
        'ทางลัด — สร้างโพสต์ แจ้งแมวหาย ค้นหาสถานที่',
        'หน้าเปิดแอป — แมววิ่งเข้าหาเจ้าของตอนเปิดแอป (ทีหลัง)',
      ]}
    />
  );
}

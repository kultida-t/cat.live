import { PlaceholderScreen } from '@/components/placeholder-screen';

export default function CommunityScreen() {
  return (
    <PlaceholderScreen
      title="ฟีด"
      subtitle="ชุมชนคนรักแมว — โพสต์ ติดตาม และบันทึก"
      notes={[
        'โพสต์ได้ไม่เกิน 3 โพสต์/วัน และวิดีโอไม่เกิน 30 วินาที (สเปกจากประชุม)',
        'แท็บ ทั้งหมด/ติดตาม/บันทึกไว้ + กรองตามหมวด',
        'ปุ่ม ไลก์ คอมเมนต์ แชร์ เซฟ และเลี้ยงขนม',
      ]}
    />
  );
}

import { PlaceholderScreen } from '@/components/placeholder-screen';

export default function HelpScreen() {
  return (
    <PlaceholderScreen
      title="ช่วยเหลือ"
      subtitle="ประกาศแมวหาย พบแมว และการระดมทุน"
      notes={[
        'ประกาศ 5 แบบ: แมวหาย / พบแมว / ขอความช่วยเหลือ / รับเลี้ยง / อุปการะ',
        'ปุ่มฉุกเฉิน — อาการเร่งด่วน + รพ.สัตว์ 24 ชม.',
        'แมวหายคือหัวใจของแอป — ผูกกับฟีด แท็ก และแชท',
      ]}
    />
  );
}

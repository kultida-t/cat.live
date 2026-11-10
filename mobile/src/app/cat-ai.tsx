import { PlaceholderScreen } from '@/components/placeholder-screen';

export default function CatAIScreen() {
  return (
    <PlaceholderScreen
      title="Cat AI"
      subtitle="ผู้ช่วยเรื่องแมว — ถามอาการและการดูแล"
      notes={[
        'แชทถาม-ตอบเรื่องแมว (พิมพ์ + เสียง)',
        'โทรคุยสัตวแพทย์ AI และตรวจใบหน้าแมว (เฟสถัดไป)',
        'Embedded AI เป็นชั้นบังคับตามมาตรฐาน UNIVERZA',
      ]}
    />
  );
}

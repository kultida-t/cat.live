/// ข้อความของหน้า Cat AI ทั้งไทยและอังกฤษ
abstract final class CatAiL10n {
  static String tapToSpeak(bool isEn) =>
      isEn ? 'Tap to speak' : 'แตะเพื่อเริ่มพูด';

  static String inputHint(String catName, bool isEn) =>
      isEn ? 'Ask about $catName...' : 'ถามเรื่อง$catName...';

  static String disclaimer(bool isEn) => isEn
      ? 'Cat AI can make mistakes and is not a vet. For general info only.'
      : 'Cat AI อาจผิดพลาดได้ และไม่ใช่สัตวแพทย์ · ใช้เป็นข้อมูลเบื้องต้น';

  static String voiceNotReady(bool isEn) =>
      isEn ? 'Voice is not available yet' : 'ระบบเสียงยังไม่เปิดใช้งาน';

  static String comingSoon(bool isEn) =>
      isEn ? 'Coming soon' : 'ฟีเจอร์นี้กำลังพัฒนา';

  static String sendFailed(bool isEn) => isEn
      ? 'Could not send your question. Please try again.'
      : 'ส่งคำถามไม่สำเร็จ ลองใหม่อีกครั้ง';

  static String emptyTitle(bool isEn) =>
      isEn ? 'No cat profile yet' : 'ยังไม่มีแมวในโปรไฟล์';

  static String emptyMessage(bool isEn) => isEn
      ? 'Add your cat first so Cat AI can get to know them.'
      : 'เพิ่มแมวก่อน Cat AI จะได้รู้จักน้องมากขึ้น';

  static String errorTitle(bool isEn) =>
      isEn ? 'Could not load data' : 'โหลดข้อมูลไม่สำเร็จ';

  static String errorMessage(bool isEn) => isEn
      ? 'Please check your connection and try again.'
      : 'ตรวจสอบการเชื่อมต่อแล้วลองใหม่อีกครั้ง';

  static String retry(bool isEn) => isEn ? 'Retry' : 'ลองใหม่';

  static String editCatLabel(bool isEn) =>
      isEn ? 'Edit cat profile' : 'แก้ไขโปรไฟล์แมว';

  static String myCatLabel(bool isEn) => isEn ? 'My cats' : 'แมวของฉัน';

  static String settingsLabel(bool isEn) =>
      isEn ? 'Cat AI settings' : 'ตั้งค่า Cat AI';

  static String addFileLabel(bool isEn) => isEn ? 'Add' : 'เพิ่มไฟล์';

  static String faceCheckLabel(bool isEn) => isEn ? 'Face check' : 'ดูสีหน้า';

  static String vetVoiceLabel(bool isEn) =>
      isEn ? 'Talk to a vet by voice' : 'คุยกับหมอด้วยเสียง';

  static String voiceInputLabel(bool isEn) =>
      isEn ? 'Voice input' : 'กดแล้วพูด';

  static String settingsTitle(bool isEn) =>
      isEn ? 'Cat AI settings' : 'ตั้งค่า Cat AI';

  static String answerStyleTitle(bool isEn) =>
      isEn ? 'Answer style' : 'รูปแบบคำตอบ';

  static String detailedStyle(bool isEn) => isEn ? 'Detailed' : 'ละเอียด';

  static String shortStyle(bool isEn) => isEn ? 'Short' : 'สั้น ๆ';

  static String clearChat(bool isEn) =>
      isEn ? 'Clear conversation' : 'ล้างการสนทนา';

  static String closeLabel(bool isEn) => isEn ? 'Close' : 'ปิด';

  static String feedbackThanks(bool isEn) =>
      isEn ? 'Thanks for your feedback' : 'ขอบคุณสำหรับความคิดเห็น';

  static String cannotDiagnoseNote(bool isEn) => isEn
      ? 'Cat AI is not a vet. If symptoms are serious, see a vet.'
      : 'Cat AI ไม่ใช่สัตวแพทย์ คำแนะนำเป็นข้อมูลเบื้องต้น หากอาการรุนแรงควรพาไปพบสัตวแพทย์';
}

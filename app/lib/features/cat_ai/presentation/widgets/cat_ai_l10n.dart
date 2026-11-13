import '../../domain/entities/cat_ai_data.dart';

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

  static String addMenuAttachSection(bool isEn) =>
      isEn ? 'Attach photo' : 'แนบรูป';

  static String addMenuFaqSection(bool isEn) =>
      isEn ? 'Common questions' : 'เรื่องที่ถามบ่อย';

  static String takePhotoTitle(bool isEn) => isEn ? 'Take photo' : 'ถ่ายรูป';

  static String takePhotoHint(bool isEn) =>
      isEn ? 'Let AI look at the photo' : 'ให้ AI ดูอาการจากรูป';

  static String pickGalleryTitle(bool isEn) =>
      isEn ? 'Choose from gallery' : 'เลือกจากคลังรูป';

  static String samplePhotosLabel(bool isEn) =>
      isEn ? 'Try sample photos' : 'ลองรูปตัวอย่าง';

  static String faceCheckHint(bool isEn) => isEn
      ? 'Check pain signs from a face photo'
      : 'เช็กสัญญาณเจ็บปวดจากรูปหน้า';

  static String imagePickFailed(bool isEn) => isEn
      ? 'Could not open the camera or gallery'
      : 'ไม่สามารถเปิดกล้องหรือคลังรูปได้';

  static String faqSymptomTitle(bool isEn) => isEn ? 'Symptoms' : 'ถามอาการ';

  static String faqSymptomQuestion(bool isEn) => isEn
      ? 'She vomited twice today but is still eating.'
      : 'น้องอาเจียน 2 ครั้งวันนี้ ยังกินข้าวได้อยู่';

  static String faqSummaryTitle(bool isEn) =>
      isEn ? 'Health summary' : 'สรุปสุขภาพ';

  static String faqSummaryQuestion(bool isEn) => isEn
      ? 'Please summarize her health this month.'
      : 'สรุปสุขภาพเดือนนี้ให้หน่อย';

  static String faqWeightTitle(bool isEn) =>
      isEn ? 'Log weight' : 'บันทึกน้ำหนัก';

  static String faqWeightQuestion(bool isEn) =>
      isEn ? 'Weighed 4.2 kg today.' : 'วันนี้ชั่งน้ำหนักได้ 4.2 กก.';

  static String faqVaccineTitle(bool isEn) =>
      isEn ? 'Vaccines' : 'เรื่องวัคซีน';

  static String faqVaccineQuestion(bool isEn) => isEn
      ? 'How should I prepare for the next vaccine?'
      : 'วัคซีนรอบถัดไปต้องเตรียมตัวยังไง';

  static String closeMenuLabel(bool isEn) => isEn ? 'Close menu' : 'ปิดเมนู';

  static String sendLabel(bool isEn) => isEn ? 'Send' : 'ส่ง';

  static String attachmentHint(bool isEn) => isEn
      ? 'Tell me which part to look at, like eyes, skin, teeth or stool, or just send.'
      : 'พิมพ์บอกจุดที่อยากให้ดู เช่น ตา ผิวหนัง ฟัน อุจจาระ หรือกดส่งได้เลย';

  static String removeAttachmentLabel(bool isEn) =>
      isEn ? 'Remove photo' : 'ลบรูปที่แนบ';

  static String levelLabel(CatAiLevel level, bool isEn) => switch (level) {
    CatAiLevel.watchAtHome =>
      isEn ? 'Level: watch at home' : 'ระดับ: เฝ้าดูอาการที่บ้าน',
    CatAiLevel.seeVetSoon =>
      isEn ? 'Level: see a vet soon' : 'ระดับ: ควรพบสัตวแพทย์เร็ว ๆ นี้',
    CatAiLevel.seeVetNow =>
      isEn ? 'Level: see a vet now' : 'ระดับ: ควรพบสัตวแพทย์ทันที',
  };

  static String recordTitle(bool isEn) =>
      isEn ? 'Summary to save to history' : 'สรุปเพื่อบันทึกเข้าประวัติ';

  static String recordType(bool isEn) => isEn ? 'Type' : 'ประเภท';

  static String recordTopic(bool isEn) => isEn ? 'Topic' : 'หัวข้อ';

  static String recordDate(bool isEn) => isEn ? 'Date' : 'วันที่';

  static String recordDetails(bool isEn) => isEn ? 'Details' : 'รายละเอียด';

  static String recordEdit(bool isEn) => isEn ? 'Edit' : 'แก้ไข';

  static String recordConfirm(bool isEn) =>
      isEn ? 'Confirm & save' : 'ยืนยันและบันทึก';

  static String recordSaved(bool isEn) =>
      isEn ? 'Saved to timeline' : 'บันทึกเข้าไทม์ไลน์แล้ว';

  static String recordViewHistory(bool isEn) =>
      isEn ? 'View history' : 'ดูประวัติ';

  static String recordEditTitle(bool isEn) =>
      isEn ? 'Edit details' : 'แก้ไขรายละเอียด';

  static String recordSaveEdit(bool isEn) =>
      isEn ? 'Save changes' : 'บันทึกการแก้ไข';
}

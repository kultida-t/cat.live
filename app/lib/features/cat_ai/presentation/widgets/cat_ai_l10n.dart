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

  // หน้าดูสีหน้า (/cat-ai/face-check)
  static String faceCheckHeroTitle(bool isEn) =>
      isEn ? 'Pain shows on their face' : 'เจ็บตรงไหน ดูจากสีหน้าได้';

  static String faceCheckHeroSubtitle(bool isEn) => isEn
      ? 'Cats often hide pain, but their face tells. Cat AI checks 5 facial points and tells you what to watch.'
      : 'แมวมักซ่อนความเจ็บปวด แต่หน้าบอกได้ Cat AI ดู 5 จุดบนใบหน้า แล้วบอกว่าควรสังเกตอะไรต่อ';

  static String faceCheckTakePhoto(String catName, bool isEn) =>
      isEn ? 'Take a photo of $catName' : 'ถ่ายรูปหน้า$catName';

  static String faceCheckPickGallery(bool isEn) =>
      isEn ? 'Choose from gallery' : 'เลือกจากคลังรูป';

  static String faceCheckConfirmTitle(bool isEn) =>
      isEn ? 'Use this photo?' : 'ใช้รูปนี้ตรวจไหม?';

  static String faceCheckConfirmSubtitle(bool isEn) =>
      isEn ? 'Clearer photos give better results' : 'รูปชัด ผลก็แม่นขึ้น';

  static List<String> faceCheckTips(bool isEn) => isEn
      ? const [
          'Front view showing eyes, nose, ears, and whiskers',
          'Good lighting, not backlit',
          'Taken while calm, not eating or yawning',
        ]
      : const [
          'หน้าตรง เห็นตา จมูก หู และหนวดครบ',
          'แสงพอ ไม่ย้อนแสง',
          'ถ่ายตอนน้องนิ่ง ๆ ไม่ใช่ตอนกำลังกินหรือหาว',
        ];

  static String faceCheckStartScan(bool isEn) =>
      isEn ? 'Start check with this photo' : 'เริ่มตรวจด้วยรูปนี้';

  static String faceCheckChooseOther(bool isEn) =>
      isEn ? 'Choose another photo' : 'เลือกรูปอื่น';

  static String faceCheckScanningTitle(String catName, bool isEn) => isEn
      ? "Cat AI is checking $catName's face"
      : 'Cat AI กำลังดูสีหน้า$catName';

  static List<String> faceCheckScanSteps(bool isEn) => isEn
      ? const [
          'Detecting face',
          'Reading 5 facial points',
          'Checking pain signals',
        ]
      : const ['หาใบหน้า', 'อ่านสีหน้า 5 จุด', 'ตรวจสัญญาณความเจ็บปวด'];

  static String faceCheckResultTag(bool isEn) =>
      isEn ? 'Cat AI Face Check Result' : 'ผลจาก Cat AI ดูสีหน้า';

  static String faceCheckResultTitle(bool isEn) =>
      isEn ? 'A few points to watch' : 'มีจุดที่ควรสังเกตเล็กน้อย';

  static String faceCheckResultSummary(
    String watchLabels,
    String watchDetails,
    bool isEn,
  ) => isEn
      ? '$watchLabels look $watchDetails. Watch eating, energy, and litter box habits for 1–2 days. See a vet if it continues.'
      : '$watchLabelsดู$watchDetails ลองสังเกตการกิน ความร่าเริง และการขับถ่ายอีก 1–2 วัน ถ้ายังเป็นอยู่ควรพาไปหาสัตวแพทย์';

  static String faceCheckFivePointsTitle(bool isEn) =>
      isEn ? '5 Facial Points' : '5 จุดบนใบหน้า';

  static String faceCheckStatusOk(bool isEn) => isEn ? 'Normal' : 'ปกติ';

  static String faceCheckStatusWatch(bool isEn) => isEn ? 'Watch' : 'ควรสังเกต';

  static String faceCheckShare(bool isEn) =>
      isEn ? 'Share with vet / family' : 'ส่งให้หมอ / ครอบครัว';

  static String faceCheckShareCopied(bool isEn) =>
      isEn ? 'Result copied to clipboard' : 'คัดลอกผลตรวจแล้ว';

  static String faceCheckAskMore(bool isEn) =>
      isEn ? 'Ask Cat AI more' : 'ถาม Cat AI ต่อ';

  static String faceCheckDisclaimer(bool isEn) => isEn
      ? 'Sample result · Not connected to a real model and not a diagnosis. Consult a vet if worried.'
      : 'ผลตัวอย่าง · Cat AI ยังไม่ได้เชื่อมโมเดลจริง และไม่ใช่การวินิจฉัย หากกังวลควรปรึกษาสัตวแพทย์';

  static String faceCheckRetry(bool isEn) =>
      isEn ? 'Check again' : 'ตรวจอีกครั้ง';

  static String faceCheckSave(bool isEn) => isEn ? 'Save result' : 'บันทึกผล';

  static String faceCheckSaved(bool isEn) => isEn ? 'Saved' : 'บันทึกแล้ว';

  // หน้าคุยกับหมอด้วยเสียงเต็มจอ (UI ตัวอย่าง)
  static String voiceCallBadge(bool isEn) =>
      isEn ? 'Talk to Cat AI Vet' : 'คุยกับหมอ Cat AI';

  static String voiceCallDialogLabel(String catName, bool isEn) =>
      isEn ? 'Talk to vet about $catName' : 'คุยกับหมอเรื่อง$catName';

  static String voiceCallGreeting(String catName, bool isEn) => isEn
      ? 'Hello! How is $catName doing today? Tell me any symptoms.'
      : 'สวัสดีครับ วันนี้$catNameเป็นยังไงบ้าง เล่าอาการให้หมอฟังได้เลยครับ';

  static String voiceCallListening(bool isEn) =>
      isEn ? 'Listening… tell me the symptoms' : 'กำลังฟัง… เล่าอาการได้เลย';

  static String voiceCallThinking(bool isEn) =>
      isEn ? 'Thinking…' : 'กำลังคิด…';

  static String voiceCallSpeaking(bool isEn) =>
      isEn ? 'Vet is replying' : 'หมอกำลังตอบ';

  static String voiceCallPaused(bool isEn) =>
      isEn ? 'Mic muted' : 'ปิดไมค์อยู่';

  static String voiceCallAutoSendHint(bool isEn) => isEn
      ? 'Sample voice mode · tap Send to preview a reply'
      : 'โหมดตัวอย่าง (ยังไม่ต่อไมค์จริง) · กดส่งเพื่อลองฟังคำตอบ';

  static String voiceCallYouPrefix(bool isEn) => isEn ? 'You: ' : 'คุณ: ';

  static String voiceCallMute(bool isEn) => isEn ? 'Mute' : 'ปิดไมค์';

  static String voiceCallUnmute(bool isEn) => isEn ? 'Unmute' : 'เปิดไมค์';

  static String voiceCallSend(bool isEn) => isEn ? 'Send' : 'ส่ง';

  static String voiceCallEnd(bool isEn) => isEn ? 'End call' : 'วางสาย';

  static String voiceCallDisclaimer(bool isEn) => isEn
      ? 'Cat AI is not a vet · If symptoms are severe, please see a vet'
      : 'Cat AI ไม่ใช่สัตวแพทย์ · ถ้าอาการรุนแรงให้พาไปพบสัตวแพทย์';

  static String voiceCallSamplePrompt(String catName, bool isEn) => isEn
      ? '$catName has barely eaten since yesterday and seems tired.'
      : '$catNameไม่ค่อยกินข้าวตั้งแต่เมื่อวาน ดูซึม ๆ ด้วยครับ';

  static String voiceCallSampleReply(String catName, bool isEn) => isEn
      ? '$catName has symptoms a vet should check within 1–2 days, especially if not eating for over 24 hours.'
      : '$catNameมีอาการที่ควรให้สัตวแพทย์ตรวจภายใน 1–2 วันครับ โดยเฉพาะถ้าไม่กินอาหารเกิน 24 ชั่วโมง แมวอดอาหารนานอาจเสี่ยงไขมันพอกตับ';
}

import 'dart:typed_data';

/// แมวหนึ่งตัวที่คุยกับ Cat AI ได้ พร้อมคำถามลัดของตัวเอง
class CatAiCat {
  const CatAiCat({
    required this.id,
    required this.name,
    required this.breed,
    required this.ageLabel,
    required this.avatarAsset,
    required this.quickQuestions,
  });

  final String id;
  final String name;
  final String breed;
  final String ageLabel;
  final String avatarAsset;
  final List<CatAiQuickQuestion> quickQuestions;
}

/// ปุ่มคำถามลัดใต้หน้าหลัก (แสดงป้ายสั้น แต่ส่งคำถามเต็มเมื่อกด)
class CatAiQuickQuestion {
  const CatAiQuickQuestion({
    required this.labelTh,
    required this.labelEn,
    required this.questionTh,
    required this.questionEn,
  });

  final String labelTh;
  final String labelEn;
  final String questionTh;
  final String questionEn;
}

/// ข้อความหนึ่งบรรทัดในการแชท (อาจมีรูปที่ผู้ใช้แนบมาด้วย)
/// คำตอบจากรูปจะมีระดับความรุนแรงและการ์ดสรุปเพื่อบันทึกเข้าประวัติด้วย
class CatAiMessage {
  const CatAiMessage({
    required this.text,
    required this.isFromUser,
    this.imageBytes,
    this.level,
    this.record,
  });

  final String text;
  final bool isFromUser;
  final Uint8List? imageBytes;
  final CatAiLevel? level;
  final CatAiRecordSummary? record;

  CatAiMessage copyWith({CatAiRecordSummary? record}) => CatAiMessage(
    text: text,
    isFromUser: isFromUser,
    imageBytes: imageBytes,
    level: level,
    record: record ?? this.record,
  );
}

/// ระดับความรุนแรงที่ Cat AI ประเมินจากรูป (ใช้ค่า key เพื่อให้แปลภาษาได้ที่หน้าจอ)
enum CatAiLevel { watchAtHome, seeVetSoon, seeVetNow }

/// การ์ดสรุปเพื่อบันทึกเข้าประวัติสุขภาพ (ยังไม่ได้เขียนลงสมุดสุขภาพจริง)
class CatAiRecordSummary {
  const CatAiRecordSummary({
    required this.type,
    required this.topic,
    required this.date,
    required this.details,
    this.saved = false,
  });

  final String type;
  final String topic;
  final String date;
  final String details;
  final bool saved;

  CatAiRecordSummary copyWith({String? details, bool? saved}) =>
      CatAiRecordSummary(
        type: type,
        topic: topic,
        date: date,
        details: details ?? this.details,
        saved: saved ?? this.saved,
      );
}

/// ผลวิเคราะห์รูปจาก Cat AI: ข้อความตอบ ระดับ และการ์ดสรุป
class CatAiImageReply {
  const CatAiImageReply({
    required this.text,
    required this.level,
    required this.record,
  });

  final String text;
  final CatAiLevel level;
  final CatAiRecordSummary record;
}

/// ข้อมูลเริ่มต้นของหน้า Cat AI: รายชื่อแมวทั้งหมดของผู้ใช้
class CatAiSnapshot {
  const CatAiSnapshot({required this.cats});

  final List<CatAiCat> cats;
}

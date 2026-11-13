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

/// ข้อความหนึ่งบรรทัดในการแชท
class CatAiMessage {
  const CatAiMessage({required this.text, required this.isFromUser});

  final String text;
  final bool isFromUser;
}

/// ข้อมูลเริ่มต้นของหน้า Cat AI: รายชื่อแมวทั้งหมดของผู้ใช้
class CatAiSnapshot {
  const CatAiSnapshot({required this.cats});

  final List<CatAiCat> cats;
}

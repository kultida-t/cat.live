import '../entities/cat_ai_data.dart';

abstract interface class CatAiRepository {
  Future<CatAiSnapshot> fetchSnapshot();

  /// ส่งคำถามไปให้ Cat AI และรับคำตอบกลับมา
  /// [detailed] = true คือคำตอบแบบละเอียด, false คือคำตอบสั้น ๆ
  Future<String> ask(String question, {required bool detailed});
}

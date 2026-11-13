import '../../domain/entities/cat_ai_data.dart';
import 'cat_ai_remote_data_source.dart';

/// ข้อมูลตัวอย่างสำหรับหน้า Cat AI — ยังไม่เชื่อม AI หรือ Backend จริง
class MockCatAiDataSource implements CatAiRemoteDataSource {
  @override
  Future<CatAiSnapshot> fetchSnapshot() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return CatAiSnapshot(
      cats: [
        _cat(
          id: 'mali',
          name: 'มะลิ',
          breed: 'วิเชียรมาศ',
          ageLabel: '3 ปี',
          avatarAsset: 'assets/images/hero/mali.jpg',
          enName: 'Mali',
        ),
        _cat(
          id: 'somjeed',
          name: 'ส้มจี๊ด',
          breed: 'ไทยสีส้ม',
          ageLabel: '1 ปี',
          avatarAsset: 'assets/images/hero/somjeed.jpg',
          enName: 'Somjeed',
        ),
        _cat(
          id: 'thuadam',
          name: 'ถั่วดำ',
          breed: 'ดำปลอด',
          ageLabel: '6 ปี',
          avatarAsset: 'assets/images/hero/thuadam.jpg',
          enName: 'Thua Dam',
        ),
      ],
    );
  }

  CatAiCat _cat({
    required String id,
    required String name,
    required String breed,
    required String ageLabel,
    required String avatarAsset,
    required String enName,
  }) {
    return CatAiCat(
      id: id,
      name: name,
      breed: breed,
      ageLabel: ageLabel,
      avatarAsset: avatarAsset,
      quickQuestions: [
        CatAiQuickQuestion(
          labelTh: 'วัคซีนรอบถัดไป',
          labelEn: 'Next vaccine',
          questionTh: 'วัคซีนรอบถัดไปของ$nameต้องเตรียมอะไร',
          questionEn: "What should I prepare for $enName's next vaccine?",
        ),
        CatAiQuickQuestion(
          labelTh: 'อาเจียน ทำยังไงดี',
          labelEn: 'Vomiting, what to do',
          questionTh: '$nameอาเจียน ควรทำยังไงดี',
          questionEn: '$enName is vomiting, what should I do?',
        ),
      ],
    );
  }

  @override
  Future<String> ask(String question, {required bool detailed}) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    return detailed
        ? 'ขอบคุณที่ถามนะ ตอนนี้หนูยังเป็นข้อมูลตัวอย่างอยู่ '
              'คำตอบจริงจะมาเมื่อเชื่อมระบบ AI แล้ว'
        : 'รับทราบครับ ตอนนี้เป็นข้อมูลตัวอย่าง';
  }
}

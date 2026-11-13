import 'package:catlive/core/config/app_locale.dart';
import 'package:catlive/features/cat_ai/data/datasources/cat_ai_remote_data_source.dart';
import 'package:catlive/features/cat_ai/data/datasources/mock_cat_ai_data_source.dart';
import 'package:catlive/features/cat_ai/domain/entities/cat_ai_data.dart';
import 'package:catlive/features/cat_ai/presentation/pages/cat_ai_page.dart';
import 'package:catlive/features/cat_ai/presentation/providers/cat_ai_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// ตัวจำลองข้อมูล: สลับได้ว่าจะล้มเหลวก่อนหรือไม่มีแมวในโปรไฟล์
class _FakeCatAiDataSource implements CatAiRemoteDataSource {
  _FakeCatAiDataSource({this.failFirst = false, this.noCat = false});

  final bool failFirst;
  final bool noCat;
  final _delegate = MockCatAiDataSource();
  int _calls = 0;

  @override
  Future<CatAiSnapshot> fetchSnapshot() async {
    _calls++;
    if (failFirst && _calls == 1) throw Exception('Network timeout');
    final data = await _delegate.fetchSnapshot();
    return noCat ? const CatAiSnapshot(cats: []) : data;
  }

  @override
  Future<String> ask(String question, {required bool detailed}) =>
      _delegate.ask(question, detailed: detailed);
}

class _TestLocaleNotifier extends AppLocaleNotifier {
  @override
  String build() => 'th';
}

Widget _wrap(CatAiRemoteDataSource dataSource) {
  return ProviderScope(
    overrides: [
      catAiDataSourceProvider.overrideWithValue(dataSource),
      appLocaleProvider.overrideWith(() => _TestLocaleNotifier()),
    ],
    child: const MaterialApp(home: Scaffold(body: CatAiPage())),
  );
}

/// รอให้แผ่นตั้งค่าเลื่อนขึ้นมาจนอยู่ในจอ (แอนิเมชันเปิดแผ่นใช้เวลาไม่แน่นอนในเทสต์)
Future<void> _waitSheetOpen(WidgetTester tester) async {
  for (var i = 0; i < 50; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (tester.getRect(find.text('รูปแบบคำตอบ')).top < 844) return;
  }
}

void main() {
  testWidgets('แสดงหน้าหลักหลังโหลดเสร็จ: ชื่อแมว, ไมค์, คำถามลัด', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(_FakeCatAiDataSource()));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('มะลิ'), findsOneWidget);
    expect(find.text('แตะเพื่อเริ่มพูด'), findsOneWidget);
    expect(find.text('วัคซีนรอบถัดไป'), findsOneWidget);
    expect(find.text('อาเจียน ทำยังไงดี'), findsOneWidget);
  });

  testWidgets('ระหว่างโหลดแสดง skeleton แทนเนื้อหา', (tester) async {
    await tester.pumpWidget(_wrap(_FakeCatAiDataSource()));
    await tester.pump();

    expect(find.text('แตะเพื่อเริ่มพูด'), findsNothing);
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('โหลดไม่สำเร็จแสดงข้อความผิดพลาดและกดลองใหม่ได้', (tester) async {
    await tester.pumpWidget(_wrap(_FakeCatAiDataSource(failFirst: true)));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('โหลดข้อมูลไม่สำเร็จ'), findsOneWidget);
    await tester.tap(find.text('ลองใหม่'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('แตะเพื่อเริ่มพูด'), findsOneWidget);
  });

  testWidgets('ไม่มีแมวในโปรไฟล์แสดงสถานะว่าง ซ่อนช่องพิมพ์', (tester) async {
    await tester.pumpWidget(_wrap(_FakeCatAiDataSource(noCat: true)));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('ยังไม่มีแมวในโปรไฟล์'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('กดคำถามลัดแล้วเห็นคำถามและคำตอบในแชท', (tester) async {
    await tester.pumpWidget(_wrap(_FakeCatAiDataSource()));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('วัคซีนรอบถัดไป'));
    await tester.pump();
    expect(find.text('วัคซีนรอบถัดไปของมะลิต้องเตรียมอะไร'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 800));
    expect(find.textContaining('ข้อมูลตัวอย่าง'), findsOneWidget);
  });

  testWidgets('กดชื่อแมวแล้วสลับเป็นตัวถัดไป และคำถามลัดเปลี่ยนตามชื่อ', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(_FakeCatAiDataSource()));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('มะลิ'));
    await tester.pump();

    expect(find.text('ส้มจี๊ด'), findsOneWidget);
    expect(find.text('วัคซีนรอบถัดไป'), findsOneWidget);
  });

  testWidgets('แผ่นตั้งค่าเปลี่ยนรูปแบบคำตอบและล้างการสนทนาได้', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_wrap(_FakeCatAiDataSource()));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.bySemanticsLabel('ตั้งค่า Cat AI'));
    await _waitSheetOpen(tester);
    expect(find.text('รูปแบบคำตอบ'), findsOneWidget);
    await tester.tap(find.text('สั้น ๆ'));
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.bySemanticsLabel('ปิด'));
    await tester.pump(const Duration(seconds: 2));

    await tester.tap(find.text('วัคซีนรอบถัดไป'));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('รับทราบครับ ตอนนี้เป็นข้อมูลตัวอย่าง'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('ตั้งค่า Cat AI'));
    await _waitSheetOpen(tester);
    await tester.tap(find.text('ล้างการสนทนา'));
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('รับทราบครับ ตอนนี้เป็นข้อมูลตัวอย่าง'), findsNothing);
    expect(find.text('แตะเพื่อเริ่มพูด'), findsOneWidget);
  });

  testWidgets('ประวัติแชทแยกตามแมวแต่ละตัว สลับกลับมาแล้วยังอยู่', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_wrap(_FakeCatAiDataSource()));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('วัคซีนรอบถัดไป'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('วัคซีนรอบถัดไปของมะลิต้องเตรียมอะไร'), findsOneWidget);

    await tester.tap(find.text('มะลิ'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('วัคซีนรอบถัดไปของมะลิต้องเตรียมอะไร'), findsNothing);
    expect(find.text('แตะเพื่อเริ่มพูด'), findsOneWidget);

    await tester.tap(find.text('ส้มจี๊ด'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('ถั่วดำ'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('วัคซีนรอบถัดไปของมะลิต้องเตรียมอะไร'), findsOneWidget);
  });
}

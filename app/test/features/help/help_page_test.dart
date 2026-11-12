import 'package:catlive/core/config/app_locale.dart';
import 'package:catlive/features/help/data/datasources/help_remote_data_source.dart';
import 'package:catlive/features/help/data/datasources/mock_help_data_source.dart';
import 'package:catlive/features/help/domain/entities/help_data.dart';
import 'package:catlive/features/help/presentation/pages/help_page.dart';
import 'package:catlive/features/help/presentation/providers/help_providers.dart';
import 'package:catlive/features/help/presentation/widgets/help_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingThenSuccessHelpDataSource implements HelpRemoteDataSource {
  bool shouldFail = true;
  final _delegate = MockHelpDataSource(delay: Duration.zero);

  @override
  Future<HelpSnapshot> fetchHelpData() async {
    if (shouldFail) {
      throw Exception('Network timeout');
    }
    return _delegate.fetchHelpData();
  }

  @override
  Future<HelpPost> createHelpPost(CreateHelpPostInput input) =>
      _delegate.createHelpPost(input);

  @override
  Future<void> sendClue(String postId) => _delegate.sendClue(postId);

  @override
  Future<void> updatePostStatus(String postId, HelpPostStatus status) =>
      _delegate.updatePostStatus(postId, status);

  @override
  Future<void> setDonationClosed(String postId, bool isClosed) =>
      _delegate.setDonationClosed(postId, isClosed);

  @override
  Future<void> updatePostContent(
    String postId, {
    required String title,
    required String summary,
    required String location,
  }) =>
      _delegate.updatePostContent(
        postId,
        title: title,
        summary: summary,
        location: location,
      );
}

Widget _wrapWithProviders({
  required HelpRemoteDataSource dataSource,
  String locale = 'th',
}) {
  return ProviderScope(
    overrides: [
      helpDataSourceProvider.overrideWithValue(dataSource),
      appLocaleProvider.overrideWith(() => _TestLocaleNotifier(locale)),
    ],
    child: const MaterialApp(home: Scaffold(body: HelpPage())),
  );
}

class _TestLocaleNotifier extends AppLocaleNotifier {
  _TestLocaleNotifier(this._initial);
  final String _initial;

  @override
  String build() => _initial;
}

void main() {
  testWidgets('แสดง loading skeleton แล้วโหลดการ์ดประกาศสำเร็จ', (tester) async {
    final ds = MockHelpDataSource(delay: const Duration(milliseconds: 80));
    await tester.pumpWidget(_wrapWithProviders(dataSource: ds));

    await tester.pump();
    expect(find.byType(HelpSkeleton), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 120));
    await tester.pumpAndSettle();

    expect(find.text('ช่วยเหลือ'), findsOneWidget);
    expect(find.text('ใกล้คุณ'), findsOneWidget);
    expect(find.text('ประกาศของฉัน'), findsOneWidget);
    expect(find.text('ทั้งหมด'), findsOneWidget);
    expect(find.text('โมจิ'), findsOneWidget);
    expect(find.byKey(const Key('help-emergency-fab')), findsOneWidget);
    expect(find.text('สร้างประกาศ'), findsOneWidget);
  });

  testWidgets('แสดง error state และกดลองใหม่จนโหลดสำเร็จ', (tester) async {
    final ds = _FailingThenSuccessHelpDataSource();
    await tester.pumpWidget(_wrapWithProviders(dataSource: ds));
    await tester.pumpAndSettle();

    expect(find.text('โหลดประกาศช่วยเหลือไม่สำเร็จ'), findsOneWidget);
    ds.shouldFail = false;

    await tester.tap(find.text('ลองใหม่'));
    await tester.pumpAndSettle();

    expect(find.text('โมจิ'), findsOneWidget);
  });

  testWidgets('กดแจ้งเบาะแสเปลี่ยนเป็น ✓ ส่งแล้ว และกางดูรายละเอียดได้', (
    tester,
  ) async {
    final ds = MockHelpDataSource(delay: Duration.zero);
    await tester.pumpWidget(_wrapWithProviders(dataSource: ds));
    await tester.pumpAndSettle();

    // กดแจ้งเบาะแสของการ์ดแรก (โมจิ)
    await tester.tap(find.text('แจ้งเบาะแส').first);
    await tester.pumpAndSettle();
    expect(find.text('✓ ส่งแล้ว'), findsOneWidget);

    // กางรายละเอียดการ์ดแรก
    await tester.tap(find.text('ดูรายละเอียด').first);
    await tester.pumpAndSettle();
    expect(find.text('ย่อ'), findsOneWidget);
    expect(find.textContaining('จุดสังเกตลับ'), findsOneWidget);
    expect(find.textContaining('โพสต์โดย'), findsOneWidget);

    // สลับหมวดหมู่เป็น รับเลี้ยง แล้วกดกลับ ทั้งหมด ในคลิกเดียว
    await tester.ensureVisible(find.byKey(const ValueKey('help-chip-adoption')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('help-chip-adoption')));
    await tester.pumpAndSettle();
    expect(find.text('สนใจรับเลี้ยง'), findsWidgets);

    await tester.ensureVisible(find.byKey(const ValueKey('help-chip-all')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('help-chip-all')));
    await tester.pumpAndSettle();
    expect(find.text('โมจิ'), findsOneWidget);
  });

  testWidgets('เปิดป๊อปอัปฉุกเฉินแสดง 6 อาการวิกฤตและ รพ.สัตว์ 24 ชม.', (
    tester,
  ) async {
    final ds = MockHelpDataSource(delay: Duration.zero);
    await tester.pumpWidget(_wrapWithProviders(dataSource: ds));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('help-emergency-fab')));
    await tester.pumpAndSettle();

    expect(find.text('แมวป่วยฉุกเฉิน?'), findsOneWidget);
    expect(find.text('หายใจลำบาก'), findsOneWidget);
    expect(find.text('รพ.สัตว์ทองหล่อ (พระราม 9)'), findsOneWidget);
    expect(find.text('นำทาง'), findsOneWidget);
    expect(find.text('โทรด่วน · รพ.สัตว์ใกล้ฉัน'), findsOneWidget);
    expect(find.text('ดูบนแผนที่'), findsOneWidget);
    expect(find.text('ถาม Cat AI'), findsOneWidget);

    await tester.ensureVisible(find.text('โทรด่วน · รพ.สัตว์ใกล้ฉัน'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('โทรด่วน · รพ.สัตว์ใกล้ฉัน'));
    await tester.pumpAndSettle();
    expect(find.text('รพ.สัตว์ใกล้คุณ'), findsOneWidget);
    expect(find.text('รพ.สัตว์ทองหล่อ 24 ชม.'), findsOneWidget);
    expect(find.text('ดูอาการฉุกเฉิน'), findsOneWidget);
  });

  testWidgets('สลับแท็บประกาศของฉันและเปิดประวัติการช่วยเหลือของฉันได้', (
    tester,
  ) async {
    final ds = MockHelpDataSource(delay: Duration.zero);
    await tester.pumpWidget(_wrapWithProviders(dataSource: ds));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ประกาศของฉัน').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('มอมแมม'), findsOneWidget);
    expect(find.text('การช่วยเหลือของฉัน'), findsOneWidget);

    await tester.tap(find.text('การช่วยเหลือของฉัน'));
    await tester.pumpAndSettle();

    expect(find.text('แมวที่ฉันช่วย'), findsOneWidget);
    expect(find.text('บันทึกการช่วยเหลือ'), findsOneWidget);

    // กดการ์ดแมวที่ฉันช่วย -> พาไปหมวดขอช่วยในแท็บใกล้คุณ
    await tester.tap(find.text('“ลายสลิดขาเจ็บ”').first);
    await tester.pumpAndSettle();
    expect(find.text('แมวจรขาหัก'), findsOneWidget);

    // กลับไปแท็บประกาศของฉัน -> กดการ์ดมอมแมม -> ปิดรับบริจาค -> เปิดดูอีกครั้ง
    await tester.tap(find.text('ประกาศของฉัน'));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('มอมแมม'));
    await tester.pumpAndSettle();
    expect(find.textContaining('จัดการประกาศ'), findsOneWidget);

    await tester.tap(find.text('ปิดรับบริจาค'));
    await tester.pumpAndSettle();
    expect(find.textContaining('ปิดรับบริจาคแล้ว'), findsOneWidget);

    await tester.tap(find.textContaining('มอมแมม'));
    await tester.pumpAndSettle();
    expect(find.text('เปิดรับบริจาคอีกครั้ง'), findsOneWidget);
  });

  testWidgets('สร้างประกาศใหม่ผ่าน Step 1 -> Step 2 -> Preview -> Confirm ได้', (
    tester,
  ) async {
    final ds = MockHelpDataSource(delay: Duration.zero);
    await tester.pumpWidget(_wrapWithProviders(dataSource: ds));
    await tester.pumpAndSettle();

    await tester.tap(find.text('สร้างประกาศ'));
    await tester.pumpAndSettle();

    expect(find.text('แจ้งประกาศเรื่องอะไร?'), findsOneWidget);
    await tester.tap(find.text('ให้คนแถวนี้ช่วยตามหา'));
    await tester.pumpAndSettle();

    // เลือกโปรไฟล์แมว "มะลิ" แล้วกรอกช่อง "ชื่อแมวและลักษณะ"
    await tester.tap(find.text('มะลิ'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField).first,
      'แมวขาวตาสองสี ปลอกคอฟ้า',
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('ดูตัวอย่างก่อนโพสต์'));
    await tester.tap(find.text('ดูตัวอย่างก่อนโพสต์'));
    await tester.pumpAndSettle();

    expect(find.text('ตัวอย่างประกาศที่จะแสดง'), findsOneWidget);
    await tester.ensureVisible(find.text('ยืนยันและโพสต์ประกาศ'));
    await tester.tap(find.text('ยืนยันและโพสต์ประกาศ'));
    await tester.pumpAndSettle();

    expect(find.text('มะลิ · แมวขาวตาสองสี ปลอกคอฟ้า'), findsOneWidget);
  });

  testWidgets('รองรับการสลับภาษาเป็น EN ครบทุกจุด', (tester) async {
    final ds = MockHelpDataSource(delay: Duration.zero);
    await tester.pumpWidget(_wrapWithProviders(dataSource: ds, locale: 'en'));
    await tester.pumpAndSettle();

    expect(find.text('Help'), findsWidgets);
    expect(find.text('Near you'), findsOneWidget);
    expect(find.text('My posts'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.byKey(const Key('help-emergency-fab')), findsOneWidget);
    expect(find.text('Create post'), findsOneWidget);
    expect(find.text('Mochi'), findsOneWidget);
  });
}

import 'dart:async';

import 'package:catlive/core/config/app_locale.dart';
import 'package:catlive/core/error/failure.dart';
import 'package:catlive/core/theme/app_theme.dart';
import 'package:catlive/features/my_cat/data/datasources/mock_my_cat_data_source.dart';
import 'package:catlive/features/my_cat/data/repositories/my_cat_repository_impl.dart';
import 'package:catlive/features/my_cat/domain/entities/my_cat_data.dart';
import 'package:catlive/features/my_cat/domain/repositories/my_cat_repository.dart';
import 'package:catlive/features/my_cat/presentation/pages/cat_health_page.dart';
import 'package:catlive/features/my_cat/presentation/providers/my_cat_controller.dart';
import 'package:catlive/features/my_cat/presentation/providers/my_cat_providers.dart';
import 'package:catlive/features/my_cat/presentation/widgets/my_cat_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _ControlledHealthRepository implements MyCatRepository {
  _ControlledHealthRepository(this._inner);

  final MyCatRepository _inner;
  Completer<MyCatBundle>? pendingBundle;
  bool failFetch = false;
  bool returnEmptyCats = false;
  bool includeEmptyHealthCat = false;

  @override
  Future<MyCatBundle> fetchBundle() async {
    if (pendingBundle != null) return pendingBundle!.future;
    if (failFetch) {
      throw const NetworkFailure('อินเทอร์เน็ตขัดข้อง ลองใหม่อีกครั้ง');
    }
    final bundle = await _inner.fetchBundle();
    if (returnEmptyCats) {
      return bundle.copyWith(cats: const []);
    }
    if (includeEmptyHealthCat) {
      const emptyCat = CatProfile(
        id: 'cat-new',
        publicId: 'MAW000199',
        name: 'ข้าวปุ้น',
        breed: 'ไทยผสม',
        gender: CatGender.female,
        neutered: false,
        ageLabel: '6 เดือน',
        weightKg: 2.3,
        recordCount: 0,
        adoptedYear: 2026,
        avatarSource: 'asset:assets/images/hero/kitten.jpg',
        avatarBg: 0xFFFFF1E6,
        healthBadge: CatHealthBadge.good,
        trackerStatus: CatTrackerStatus.noCollar,
        trackerLabel: 'ยังไม่มีปลอกคอ',
        photos: [],
        careTasks: [],
        healthReminderTitle: '',
        healthReminderSubtitle: '',
        healthHighlights: [],
        caregivers: [],
      );
      return bundle.copyWith(cats: [...bundle.cats, emptyCat]);
    }
    return bundle;
  }

  @override
  Future<void> toggleCareTask({
    required String catId,
    required String taskId,
    required bool isDone,
  }) => _inner.toggleCareTask(catId: catId, taskId: taskId, isDone: isDone);

  @override
  Future<CatProfile> updateCatProfile(CatProfile cat) =>
      _inner.updateCatProfile(cat);

  @override
  Future<CatProfile> addCatProfile(CatProfile newCat) =>
      _inner.addCatProfile(newCat);

  @override
  Future<OwnerProfile> updateOwnerProfile(OwnerProfile owner) =>
      _inner.updateOwnerProfile(owner);

  @override
  Future<CatPhotoItem> addCatPhoto({
    required String catId,
    required String imageSource,
    required String caption,
  }) => _inner.addCatPhoto(
    catId: catId,
    imageSource: imageSource,
    caption: caption,
  );
}

_ControlledHealthRepository _createRepo() => _ControlledHealthRepository(
  MyCatRepositoryImpl(MockMyCatDataSource(delay: Duration.zero)),
);

Widget _buildTestApp(_ControlledHealthRepository repo) {
  final router = GoRouter(
    initialLocation: '/my-cat/health',
    routes: [
      GoRoute(path: '/my-cat/health', builder: (_, _) => const CatHealthPage()),
      GoRoute(
        path: '/my-cat',
        builder: (_, _) =>
            const Scaffold(body: Center(child: Text('หน้าแมวและฉัน'))),
      ),
      GoRoute(
        path: '/nearby',
        builder: (_, _) =>
            const Scaffold(body: Center(child: Text('หน้าใกล้ฉัน'))),
      ),
    ],
  );

  return ProviderScope(
    overrides: [myCatRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
  );
}

void _useMobileViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('แสดง loading skeleton แล้วโหลดสมุดสุขภาพของมะลิและกรองประวัติได้', (
    tester,
  ) async {
    _useMobileViewport(tester);
    final repo = _createRepo();
    final completer = Completer<MyCatBundle>();
    repo.pendingBundle = completer;

    await tester.pumpWidget(_buildTestApp(repo));
    await tester.pump();
    expect(find.byType(MyCatSkeleton), findsOneWidget);

    final realBundle = await tester.runAsync(
      () => MyCatRepositoryImpl(
        MockMyCatDataSource(delay: Duration.zero),
      ).fetchBundle(),
    );
    completer.complete(realBundle!);
    await tester.pumpAndSettle();

    expect(find.byType(MyCatSkeleton), findsNothing);
    expect(find.text('สมุดสุขภาพ'), findsOneWidget);
    expect(find.text('นัดถัดไป'), findsOneWidget);
    expect(find.text('วัคซีนรวม (FVRCP)'), findsOneWidget);
    expect(find.text('อาเจียน 2 ครั้ง'), findsOneWidget);
    expect(find.text('จาก Cat AI'), findsOneWidget);
    expect(find.text('อ่านจากเอกสาร'), findsOneWidget);
    expect(find.text('เพิ่มบันทึก'), findsOneWidget);

    // เพิ่มบันทึกใหม่จากแท็บประวัติ
    await tester.ensureVisible(find.text('เพิ่มบันทึก'));
    await tester.tap(find.text('เพิ่มบันทึก'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).first,
      'จามตอนเช้า 2 ครั้ง',
    );
    await tester.pump();
    await tester.tap(find.text('บันทึก'));
    await tester.pumpAndSettle();
    expect(find.text('จามตอนเช้า 2 ครั้ง'), findsOneWidget);

    // ปุ่มหาคลินิกพาไปหน้า /nearby
    await tester.ensureVisible(find.text('หาคลินิก'));
    await tester.tap(find.text('หาคลินิก'));
    await tester.pumpAndSettle();
    expect(find.text('หน้าใกล้ฉัน'), findsOneWidget);
  });

  testWidgets('รองรับ error retry และ empty state เมื่อยังไม่มีแมวหรือแมวใหม่ยังไม่มีบันทึก', (
    tester,
  ) async {
    _useMobileViewport(tester);
    final repo = _createRepo()..failFetch = true;

    await tester.pumpWidget(_buildTestApp(repo));
    await tester.pumpAndSettle();
    expect(find.textContaining('อินเทอร์เน็ตขัดข้อง'), findsOneWidget);

    // ลองใหม่แบบไม่มีแมว
    repo.failFetch = false;
    repo.returnEmptyCats = true;
    await tester.tap(find.text('ลองใหม่'));
    await tester.pumpAndSettle();
    expect(find.text('ยังไม่มีข้อมูลแมวในสมุดสุขภาพ'), findsOneWidget);

    // โหลดใหม่แบบมีแมวใหม่ที่สมุดสุขภาพว่าง
    repo.returnEmptyCats = false;
    repo.includeEmptyHealthCat = true;
    final container = ProviderScope.containerOf(
      tester.element(find.byType(CatHealthPage)),
    );
    await container.read(myCatControllerProvider.notifier).load();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('ข้าวปุ้น'));
    await tester.tap(find.text('ข้าวปุ้น'));
    await tester.pumpAndSettle();
    expect(find.text('ยังไม่มีบันทึกสุขภาพ'), findsOneWidget);
  });

  testWidgets('แท็บร่างกาย 8 จุด: สลับแมว แตะอวัยวะ และกดอัปโหลดเอกสารจากจุดว่างได้', (
    tester,
  ) async {
    _useMobileViewport(tester);
    final repo = _createRepo();

    await tester.pumpWidget(_buildTestApp(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ร่างกาย'));
    await tester.pumpAndSettle();

    // มะลิมี 8 จุดครบ และแตะ "ตาและหู" (ยังไม่มีข้อมูล -> แสดงปุ่มอัปโหลดเอกสาร)
    expect(find.text('ตาและหู'), findsOneWidget);
    expect(find.text('ข้อและกระดูก'), findsOneWidget);
    await tester.tap(find.text('ตาและหู').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('ยังไม่มีข้อมูลของตาและหูของมะลิ'), findsOneWidget);
    expect(find.text('อัปโหลดเอกสาร'), findsOneWidget);

    // สลับเป็นถั่วดำ -> แสดงสถานะผิดปกติที่ไตและตับ
    await tester.ensureVisible(find.text('ถั่วดำ'));
    await tester.tap(find.text('ถั่วดำ'));
    await tester.pumpAndSettle();
    expect(find.textContaining('ผิดปกติ 1'), findsOneWidget);
    expect(find.textContaining('ค่าไตสูงเล็กน้อย'), findsOneWidget);

    // แตะจุดที่ยังไม่มีข้อมูลแล้วกด "อัปโหลดเอกสาร" -> พาไปแท็บเอกสาร
    await tester.tap(find.text('ตาและหู').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('อัปโหลดเอกสาร'));
    await tester.tap(find.text('อัปโหลดเอกสาร'));
    await tester.pumpAndSettle();
    expect(find.text('อัปโหลดรูปหรือ PDF'), findsOneWidget);
  });

  testWidgets('แท็บสมุดวัคซีน ยา ปฏิทิน น้ำหนัก และเอกสารทำงานครบทุกแท็บ', (
    tester,
  ) async {
    _useMobileViewport(tester);
    final repo = _createRepo();

    await tester.pumpWidget(_buildTestApp(repo));
    await tester.pumpAndSettle();

    // 3. สมุดวัคซีน + เพิ่มการฉีดวัคซีน
    await tester.tap(find.text('สมุดวัคซีน'));
    await tester.pumpAndSettle();
    expect(find.text('ข้อมูลสัตว์เลี้ยง'), findsOneWidget);
    expect(find.text('MAW000123'), findsOneWidget);
    expect(
      find.textContaining('Nobivac Tricat Trio · MSD Animal Health'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('เพิ่มการฉีดวัคซีน'));
    await tester.tap(find.text('เพิ่มการฉีดวัคซีน'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'วัคซีนลิวคีเมีย');
    await tester.pump();
    await tester.tap(find.text('บันทึก'));
    await tester.pumpAndSettle();
    expect(find.text('วัคซีนลิวคีเมีย'), findsOneWidget);

    // 4. ยา + เพิ่มยา (เลื่อนแถบแท็บให้ "ยา" อยู่ในจอชัดก่อนแตะ)
    await tester.drag(find.text('สมุดวัคซีน'), const Offset(80, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ยา'));
    await tester.pumpAndSettle();
    expect(find.text('ยาที่ใช้'), findsOneWidget);
    expect(find.text('Cerenia (ยาลดอาเจียน)'), findsOneWidget);
    expect(find.text('กำลังใช้'), findsOneWidget);
    await tester.tap(find.text('เพิ่มยา'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'วิตามินบำรุงขน');
    await tester.pump();
    await tester.tap(find.text('บันทึก'));
    await tester.pumpAndSettle();
    expect(find.text('วิตามินบำรุงขน'), findsOneWidget);

    // 5. ปฏิทิน + แตะวันที่ 20 พ.ย. (ส้มจี๊ด) และเขียนบันทึกด่วนในกล่องปฏิทิน
    await tester.ensureVisible(find.text('ปฏิทิน'));
    await tester.tap(find.text('ปฏิทิน'));
    await tester.pumpAndSettle();
    expect(find.text('พฤศจิกายน 2569'), findsOneWidget);
    await tester.tap(find.text('20').first);
    await tester.pumpAndSettle();
    expect(find.text('Frontline (ยาหยดหลังคอ)'), findsAtLeastNWidgets(1));
    expect(find.text('ตรวจเลือด'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'นัดอาบน้ำ');
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('ส่งบันทึก'));
    await tester.pumpAndSettle();
    expect(find.text('นัดอาบน้ำ'), findsOneWidget);

    // 6. น้ำหนัก + แบนเนอร์เตือน + บันทึกน้ำหนักใหม่ (เปิดชีตเพิ่มบันทึกสุขภาพโหมดน้ำหนัก)
    await tester.ensureVisible(find.text('น้ำหนัก'));
    await tester.tap(find.text('น้ำหนัก'));
    await tester.pumpAndSettle();
    expect(find.text('4.1'), findsOneWidget);
    expect(find.textContaining('น้ำหนักลดลงต่อเนื่อง'), findsOneWidget);
    await tester.ensureVisible(find.text('บันทึกน้ำหนักวันนี้'));
    await tester.tap(find.text('บันทึกน้ำหนักวันนี้'));
    await tester.pumpAndSettle();
    expect(find.text('เพิ่มบันทึกสุขภาพ'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(1), '4.5 กก.');
    await tester.tap(find.text('บันทึก'));
    await tester.pumpAndSettle();
    expect(find.text('4.5'), findsOneWidget);

    // 7. เอกสาร + แนบ PDF ตัวอย่าง
    await tester.ensureVisible(find.text('เอกสาร'));
    await tester.tap(find.text('เอกสาร'));
    await tester.pumpAndSettle();
    expect(find.text('ผลตรวจเลือด ก.ย. 2569.pdf'), findsOneWidget);
    await tester.tap(find.text('อัปโหลดรูปหรือ PDF'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('แนบไฟล์ผลตรวจ PDF ตัวอย่าง'));
    await tester.pumpAndSettle();
    expect(find.text('ผลตรวจสุขภาพ_พย2569.pdf'), findsOneWidget);
  });

  testWidgets('เปิด Vet Summary สลับแมว คัดลอกสรุป และสลับภาษา EN ได้ครบ', (
    tester,
  ) async {
    _useMobileViewport(tester);
    final repo = _createRepo();
    String? copiedText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copiedText = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.pumpWidget(_buildTestApp(repo));
    await tester.pumpAndSettle();

    // เปิด Vet Summary
    await tester.tap(find.byTooltip('สร้าง Vet Summary'));
    await tester.pumpAndSettle();
    expect(find.text('Vet Summary'), findsOneWidget);
    expect(find.textContaining('Vet Summary · มะลิ (MAW000123)'), findsOneWidget);

    await tester.ensureVisible(find.text('คัดลอก'));
    await tester.tap(find.text('คัดลอก'));
    await tester.pumpAndSettle();
    expect(copiedText, contains('มะลิ'));

    await tester.tap(find.bySemanticsLabel('ปิด'));
    await tester.pumpAndSettle();

    // สลับเป็นภาษา EN
    final container = ProviderScope.containerOf(
      tester.element(find.byType(CatHealthPage)),
    );
    container.read(appLocaleProvider.notifier).setLocale('en');
    await tester.pumpAndSettle();

    expect(find.text('Health book'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Body'), findsOneWidget);
    expect(find.text('Vaccine book'), findsOneWidget);
    expect(find.text('Medicine'), findsOneWidget);
    expect(find.text('Calendar'), findsOneWidget);
    expect(find.text('Weight'), findsAtLeastNWidgets(1));
    expect(find.text('Documents'), findsOneWidget);
    expect(find.text('Next appointment'), findsOneWidget);
  });
}

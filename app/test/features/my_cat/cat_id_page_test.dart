import 'dart:async';

import 'package:catlive/core/config/app_locale.dart';
import 'package:catlive/core/error/failure.dart';
import 'package:catlive/core/theme/app_theme.dart';
import 'package:catlive/features/my_cat/data/datasources/mock_my_cat_data_source.dart';
import 'package:catlive/features/my_cat/data/repositories/my_cat_repository_impl.dart';
import 'package:catlive/features/my_cat/domain/entities/my_cat_data.dart';
import 'package:catlive/features/my_cat/domain/repositories/my_cat_repository.dart';
import 'package:catlive/features/my_cat/presentation/pages/cat_id_page.dart';
import 'package:catlive/features/my_cat/presentation/providers/my_cat_controller.dart';
import 'package:catlive/features/my_cat/presentation/providers/my_cat_providers.dart';
import 'package:catlive/features/my_cat/presentation/widgets/cat_id_card.dart';
import 'package:catlive/features/my_cat/presentation/widgets/my_cat_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _ControlledCatIdRepository implements MyCatRepository {
  _ControlledCatIdRepository(this._inner);

  final MyCatRepository _inner;
  Completer<MyCatBundle>? pendingBundle;
  bool failFetch = false;
  bool returnEmptyCats = false;

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

_ControlledCatIdRepository _createRepo() => _ControlledCatIdRepository(
  MyCatRepositoryImpl(MockMyCatDataSource(delay: Duration.zero)),
);

Widget _buildTestApp(_ControlledCatIdRepository repo) {
  final router = GoRouter(
    initialLocation: '/my-cat/profile',
    routes: [
      GoRoute(path: '/my-cat/profile', builder: (_, _) => const CatIdPage()),
      GoRoute(
        path: '/my-cat',
        builder: (_, _) =>
            const Scaffold(body: Center(child: Text('หน้าแมวและฉัน'))),
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
  testWidgets('แสดง loading skeleton แล้วโหลดบัตร Cat ID ของมะลิครบถ้วน', (
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
    expect(find.text('บัตรประจำตัวแมว'), findsNWidgets(2)); // header + card
    expect(find.text('MAW000123'), findsOneWidget);
    expect(find.text('ครีม แต้มน้ำตาล'), findsOneWidget);
    expect(find.text('เฝ้าระวัง'), findsOneWidget);
    expect(find.text('•••• •••• [หมายเลข]'), findsOneWidget);
    expect(find.text('jutamas.lk'), findsOneWidget);
    expect(find.text('สีบัตร · น้ำผึ้ง'), findsOneWidget);
    expect(find.byType(CatIdQrMatrix), findsOneWidget);
    expect(
      find.textContaining('หน้าสาธารณะจาก QR แสดงแค่ชื่อ รูป'),
      findsOneWidget,
    );
  });

  testWidgets('สลับแมวเป็นส้มจี๊ดและถั่วดำ อัปเดตข้อมูล ธีม และอาการติดตามตรงเว็บ', (
    tester,
  ) async {
    _useMobileViewport(tester);
    final repo = _createRepo();

    await tester.pumpWidget(_buildTestApp(repo));
    await tester.pumpAndSettle();

    // สลับไปส้มจี๊ด (พีช + สุขภาพดี + ไม่มีอาการที่ต้องติดตาม)
    await tester.ensureVisible(find.text('ส้มจี๊ด'));
    await tester.tap(find.text('ส้มจี๊ด'));
    await tester.pumpAndSettle();

    expect(find.text('MAW000124'), findsOneWidget);
    expect(find.text('สีบัตร · พีช'), findsOneWidget);
    expect(find.text('สุขภาพดี'), findsOneWidget);
    expect(find.text('อาการที่ต้องติดตาม'), findsNothing);

    // สลับไปถั่วดำ (กลางคืน + สุขภาพไม่ดี + โรคประจำตัว)
    await tester.ensureVisible(find.text('ถั่วดำ'));
    await tester.tap(find.text('ถั่วดำ'));
    await tester.pumpAndSettle();

    expect(find.text('MAW000188'), findsOneWidget);
    expect(find.text('สีบัตร · กลางคืน'), findsOneWidget);
    expect(find.text('สุขภาพไม่ดี'), findsOneWidget);
    expect(find.textContaining('เสี่ยงภาวะไตเรื้อรัง'), findsOneWidget);
  });

  testWidgets('เปลี่ยนสีบัตรเป็นมิ้นต์และจำค่าแยกตามตัวแมวเมื่อสลับไปมา', (
    tester,
  ) async {
    _useMobileViewport(tester);
    final repo = _createRepo();

    await tester.pumpWidget(_buildTestApp(repo));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.bySemanticsLabel('มิ้นต์'));
    await tester.tap(find.bySemanticsLabel('มิ้นต์'));
    await tester.pumpAndSettle();
    expect(find.text('สีบัตร · มิ้นต์'), findsOneWidget);

    // สลับไปส้มจี๊ดแล้วย้อนกลับมามะลิ — สีมิ้นต์ของมะลิต้องยังอยู่
    await tester.ensureVisible(find.text('ส้มจี๊ด'));
    await tester.tap(find.text('ส้มจี๊ด'));
    await tester.pumpAndSettle();
    expect(find.text('สีบัตร · พีช'), findsOneWidget);

    await tester.tap(find.text('มะลิ').first);
    await tester.pumpAndSettle();
    expect(find.text('สีบัตร · มิ้นต์'), findsOneWidget);
  });

  testWidgets('กดแชร์ Cat ID แล้วคัดลอกลิงก์ปิดชีตและขึ้น toast สำเร็จ', (
    tester,
  ) async {
    _useMobileViewport(tester);
    final repo = _createRepo();

    await tester.pumpWidget(_buildTestApp(repo));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('แชร์ Cat ID'));
    await tester.tap(find.text('แชร์ Cat ID'));
    await tester.pumpAndSettle();

    expect(find.text('มะลิ · MAW000123'), findsOneWidget);
    await tester.tap(find.text('คัดลอก'));
    await tester.pumpAndSettle();

    expect(find.text('แชร์ Cat ID แล้ว'), findsOneWidget);
    expect(find.text('มะลิ · MAW000123'), findsNothing);
  });

  testWidgets('เปิดชีตสั่งพิมพ์ป้าย เลือกสติกเกอร์ QR แล้วส่งคำสั่งได้จริง', (
    tester,
  ) async {
    _useMobileViewport(tester);
    final repo = _createRepo();

    await tester.pumpWidget(_buildTestApp(repo));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('สั่งพิมพ์ป้าย'));
    await tester.tap(find.text('สั่งพิมพ์ป้าย'));
    await tester.pumpAndSettle();

    expect(find.text('สั่งพิมพ์ป้าย มะลิ'), findsOneWidget);
    expect(find.text('พิมพ์ / บันทึกเป็น PDF'), findsOneWidget);

    await tester.tap(find.text('สติกเกอร์ QR'));
    await tester.pumpAndSettle();
    expect(find.text('ส่งคำสั่งทำป้าย'), findsOneWidget);

    await tester.tap(find.text('ส่งคำสั่งทำป้าย'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('บันทึกคำสั่งสติกเกอร์ QRแล้ว'),
      findsOneWidget,
    );
  });

  testWidgets('รองรับสถานะ empty, error และภาษาอังกฤษครบถ้วน', (tester) async {
    _useMobileViewport(tester);
    final repo = _createRepo()..failFetch = true;

    await tester.pumpWidget(_buildTestApp(repo));
    await tester.pumpAndSettle();
    expect(find.textContaining('อินเทอร์เน็ตขัดข้อง'), findsOneWidget);

    repo
      ..failFetch = false
      ..returnEmptyCats = true;
    await tester.tap(find.text('ลองใหม่'));
    await tester.pumpAndSettle();
    expect(find.text('ยังไม่มีบัตร Cat ID'), findsOneWidget);

    // สลับกลับมามีข้อมูลและเปลี่ยนภาษาเป็น EN
    repo.returnEmptyCats = false;
    final element = tester.element(find.byType(CatIdPage));
    final container = ProviderScope.containerOf(element);
    await tester.runAsync(() => container.read(myCatControllerProvider.notifier).load());
    container.read(appLocaleProvider.notifier).setLocale('en');
    await tester.pumpAndSettle();

    expect(find.text('Cat ID Card'), findsNWidgets(2));
    expect(find.text('Share Cat ID'), findsOneWidget);
    expect(find.text('Print tag'), findsOneWidget);
  });

  testWidgets('เปิดหน้า Cat ID จากแมวตัวท้าย ๆ แถวแคปซูลเลื่อนโฟกัสให้เห็นชัดเจน', (
    tester,
  ) async {
    _useMobileViewport(tester);
    final repo = _createRepo();

    await tester.pumpWidget(_buildTestApp(repo));
    await tester.pumpAndSettle();

    // เพิ่มแมวตัวที่ 4 ชื่อฮานอย ซึ่งจะถูกเลือกเป็น active cat โดยอัตโนมัติ
    final element = tester.element(find.byType(CatIdPage));
    final container = ProviderScope.containerOf(element);
    final baseCat = container.read(myCatControllerProvider).bundle!.cats.first;
    await tester.runAsync(
      () => container.read(myCatControllerProvider.notifier).addCat(
            baseCat.copyWith(
              id: 'cat-hanoi',
              publicId: 'MAW000189',
              name: 'ฮานอย',
              breed: 'เปอร์เซีย',
            ),
          ),
    );
    await tester.pumpAndSettle();

    // แคปซูล "ฮานอย" ต้องเลื่อนเข้ามาอยู่ในกรอบจอ 390px ไม่ตกขอบขวา
    final chipRect = tester.getRect(find.text('ฮานอย').first);
    expect(chipRect.right, lessThanOrEqualTo(390));
    expect(chipRect.left, greaterThanOrEqualTo(0));
  });
}

import 'dart:async';
import 'dart:typed_data';

import 'package:catlive/core/config/app_locale.dart';
import 'package:catlive/core/error/failure.dart';
import 'package:catlive/core/theme/app_theme.dart';
import 'package:catlive/features/my_cat/data/datasources/mock_my_cat_data_source.dart';
import 'package:catlive/features/my_cat/data/repositories/my_cat_repository_impl.dart';
import 'package:catlive/features/my_cat/domain/entities/my_cat_data.dart';
import 'package:catlive/features/my_cat/domain/repositories/my_cat_repository.dart';
import 'package:catlive/features/my_cat/presentation/pages/cat_tracker_page.dart';
import 'package:catlive/features/my_cat/presentation/providers/my_cat_providers.dart';
import 'package:catlive/features/my_cat/presentation/widgets/cat_tracker_sheet.dart';
import 'package:catlive/features/my_cat/presentation/widgets/my_cat_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

final _kTransparentPng = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

class _MemoryTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(_kTransparentPng);
}

class _ControlledTrackerRepository implements MyCatRepository {
  _ControlledTrackerRepository(this._inner);

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

_ControlledTrackerRepository _createRepo() => _ControlledTrackerRepository(
  MyCatRepositoryImpl(MockMyCatDataSource(delay: Duration.zero)),
);

Widget _buildTestApp(
  _ControlledTrackerRepository repo, {
  String initialLocation = '/my-cat/tracker',
}) {
  final tileProvider = _MemoryTileProvider();
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/my-cat/tracker',
        builder: (_, state) => CatTrackerPage(
          initialDeviceMode: state.uri.queryParameters['device'] == '1',
          tileProvider: tileProvider,
        ),
      ),
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
  testWidgets('แสดง loading skeleton แล้วโหลดแผนที่และรายการแมว 3 ตัวครบถ้วน', (
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
      () =>
          MyCatRepositoryImpl(MockMyCatDataSource(delay: Duration.zero))
              .fetchBundle(),
    );
    completer.complete(realBundle!);
    await tester.pumpAndSettle();

    expect(find.byType(MyCatSkeleton), findsNothing);
    expect(find.text('ตามหาแมว'), findsOneWidget);
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.text('แมวของฉัน'), findsOneWidget);
    expect(find.text('มะลิ'), findsOneWidget);
    expect(find.text('อยู่บ้าน'), findsOneWidget);
    expect(find.text('78%'), findsOneWidget);
    expect(find.text('ส้มจี๊ด'), findsOneWidget);
    expect(find.text('260 ม.'), findsOneWidget);
    expect(find.text('23%'), findsOneWidget);
    expect(find.text('ถั่วดำ'), findsOneWidget);
    expect(find.text('ยังไม่มีแท็ก · แตะเพื่อเพิ่ม'), findsOneWidget);
    expect(find.text('แตะเพื่อดูเต็มจอ'), findsOneWidget);
  });

  testWidgets('ขยายแผนที่เต็มจอและย่อกลับผ่านปุ่มดูรายการได้', (tester) async {
    _useMobileViewport(tester);
    final repo = _createRepo();

    await tester.pumpWidget(_buildTestApp(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('แตะเพื่อดูเต็มจอ'));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('ย่อแผนที่'), findsOneWidget);
    expect(find.text('ดูรายการ'), findsOneWidget);

    await tester.tap(find.text('ดูรายการ'));
    await tester.pumpAndSettle();

    expect(find.text('แตะเพื่อดูเต็มจอ'), findsOneWidget);
    expect(find.text('78%'), findsOneWidget);
  });

  testWidgets(
    'เปิดแผงรายละเอียดมะลิ เล่นเสียง ปรับรัศมี และเปิดโหมดแมวหายได้',
    (tester) async {
      _useMobileViewport(tester);
      final repo = _createRepo();

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('มะลิ'));
      await tester.pumpAndSettle();

      expect(find.text('อยู่ในเขตปลอดภัย'), findsOneWidget);
      expect(find.text('บ้าน · ซ.อารีย์ 4'), findsNWidgets(2));
      expect(find.text('เส้นทางวันนี้'), findsOneWidget);
      expect(find.text('หลังบ้านเลขที่ 18'), findsOneWidget);
      expect(find.text('50 ม.'), findsOneWidget);
      expect(find.text('100 ม.'), findsOneWidget);
      expect(find.text('200 ม.'), findsOneWidget);

      // กดเล่นเสียงแล้วกดซ้ำเพื่อหยุดทันที
      await tester.tap(find.text('เล่นเสียง'));
      await tester.pump();
      expect(find.text('กำลังส่งเสียง…'), findsOneWidget);
      expect(find.text('ปลอกคอของมะลิกำลังส่งเสียง (จำลอง)'), findsOneWidget);
      await tester.tap(find.text('เล่นเสียง'));
      await tester.pump(const Duration(seconds: 2));

      // เปลี่ยนรัศมีเป็น 200 ม. -> CircleLayer อัปเดตเป็น 200 เมตร
      await tester.ensureVisible(find.text('200 ม.'));
      await tester.tap(find.text('200 ม.'));
      await tester.pumpAndSettle();
      final circleLayer = tester.widget<CircleLayer>(find.byType(CircleLayer));
      expect(circleLayer.circles.first.radius, 200);

      // เปิดโหมดแมวหาย -> ขึ้น toast
      final lostSwitch = find.byWidgetPredicate(
        (w) => w is TrackerPillSwitch && w.label == 'โหมดแมวหาย',
      );
      await tester.ensureVisible(lostSwitch);
      await tester.tap(lostSwitch);
      await tester.pump();
      expect(find.text('เปิดโหมดแมวหายของมะลิแล้ว'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));

      // กดเพิ่มคนช่วยติดตาม -> ขึ้น toast
      await tester.ensureVisible(find.text('เพิ่มคนช่วยติดตาม'));
      await tester.tap(find.text('เพิ่มคนช่วยติดตาม'));
      await tester.pump();
      expect(find.text('ส่งคำเชิญแล้ว (จำลอง)'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
    },
  );

  testWidgets(
    'เปิดแผงส้มจี๊ดแสดงสถานะออกนอกเขต และแตะถั่วดำแสดงหน้าชวนติดแท็ก',
    (tester) async {
      _useMobileViewport(tester);
      final repo = _createRepo();

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ส้มจี๊ด'));
      await tester.pumpAndSettle();

      expect(find.text('ออกนอกเขต · ห่างบ้าน 260 ม.'), findsOneWidget);
      expect(find.text('เดิน 260 ม.'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('ปิด'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ถั่วดำ'));
      await tester.pumpAndSettle();

      expect(find.text('ถั่วดำยังไม่มี แมว.live Tag'), findsOneWidget);
      expect(find.text('ดู แมว.live Tag · ฿990'), findsOneWidget);
      expect(
        find.text('ค่าบริการติดตาม ฿59/เดือน · ราคาตัวอย่าง'),
        findsOneWidget,
      );

      await tester.ensureVisible(find.text('มีปลอกคออยู่แล้ว เชื่อมต่อ >'));
      await tester.tap(find.text('มีปลอกคออยู่แล้ว เชื่อมต่อ >'));
      await tester.pump();
      expect(
        find.text('สแกน QR บนปลอกคอเพื่อเชื่อมต่อ (จำลอง)'),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 2));
    },
  );

  testWidgets('เปิดโหมดตั้งค่าอุปกรณ์ผ่าน ?device=1 และตั้งค่ารายแท็กได้ครบ', (
    tester,
  ) async {
    _useMobileViewport(tester);
    final repo = _createRepo();

    await tester.pumpWidget(
      _buildTestApp(repo, initialLocation: '/my-cat/tracker?device=1'),
    );
    await tester.pumpAndSettle();

    expect(find.text('ตั้งค่าอุปกรณ์'), findsOneWidget);
    expect(find.text('แท็กของฉัน · 2 ชิ้น'), findsOneWidget);

    // ขยายเพิ่มอุปกรณ์แล้วเลือกถั่วดำ -> ปุ่มซื้อแท็กปรากฏ
    await tester.tap(find.text('เพิ่มอุปกรณ์'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('ยังไม่มีแท็ก'));
    await tester.tap(find.text('ยังไม่มีแท็ก'));
    await tester.pumpAndSettle();
    expect(find.text('ซื้อแท็ก'), findsOneWidget);

    // เข้าแท็ก 1 ของมะลิ -> ตรวจการ์ดหัวแท็ก เปลี่ยนความถี่เป็นเรียลไทม์ + เช็กอัปเดตล่าสุดแล้ว
    final tag1Row = find.bySemanticsLabel('แท็ก 1 มะลิ แบต 78%');
    await tester.ensureVisible(tag1Row);
    await tester.tap(tag1Row);
    await tester.pumpAndSettle();

    expect(find.text('แท็ก 1 · มะลิ'), findsOneWidget);
    expect(find.text('แมว.live Tag'), findsOneWidget);
    expect(find.text('ใส่อยู่ที่ปลอกคอของมะลิ'), findsOneWidget);
    expect(
      find.text('4G · สัญญาณดี · ซิงก์ล่าสุด 2 นาทีที่แล้ว'),
      findsOneWidget,
    );
    await tester.tap(find.text('เรียลไทม์'));
    await tester.pumpAndSettle();
    expect(find.text('ทุก 10 วินาที · แบตอยู่ ~1 วัน'), findsOneWidget);

    await tester.ensureVisible(find.text('ตรวจสอบอัปเดต'));
    await tester.tap(find.text('ตรวจสอบอัปเดต'));
    await tester.pump();
    expect(find.text('เป็นเวอร์ชันล่าสุดแล้ว'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));

    // ย้อนกลับไปเข้าแท็ก 2 ของส้มจี๊ด -> เช็กอัปเดต + ยกเลิกเชื่อมต่อ inline
    await tester.ensureVisible(find.bySemanticsLabel('กลับไปตั้งค่าอุปกรณ์'));
    await tester.tap(find.bySemanticsLabel('กลับไปตั้งค่าอุปกรณ์'));
    await tester.pumpAndSettle();
    final tag2Row = find.bySemanticsLabel('แท็ก 2 ส้มจี๊ด แบต 23%');
    await tester.ensureVisible(tag2Row);
    await tester.tap(tag2Row);
    await tester.pumpAndSettle();

    expect(find.text('แท็ก 2 · ส้มจี๊ด'), findsOneWidget);
    expect(
      find.text('4G · สัญญาณอ่อน · ซิงก์ล่าสุด 6 นาทีที่แล้ว'),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('ตรวจสอบอัปเดต'));
    await tester.tap(find.text('ตรวจสอบอัปเดต'));
    await tester.pump();
    expect(find.text('กำลังอัปเดตเป็น 1.4.2 (จำลอง)'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));

    await tester.ensureVisible(find.text('ยกเลิกการเชื่อมต่ออุปกรณ์'));
    await tester.tap(find.text('ยกเลิกการเชื่อมต่ออุปกรณ์'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('ยกเลิกการเชื่อมต่อปลอกคอกับส้มจี๊ด'),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('ยกเลิกการเชื่อมต่อ'));
    await tester.tap(find.text('ยกเลิกการเชื่อมต่อ'));
    await tester.pump();
    expect(find.text('ยกเลิกการเชื่อมต่อแล้ว (จำลอง)'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('รองรับสถานะ error พร้อมปุ่มลองใหม่ และ empty state', (
    tester,
  ) async {
    _useMobileViewport(tester);
    final repo = _createRepo()..failFetch = true;

    await tester.pumpWidget(_buildTestApp(repo));
    await tester.pumpAndSettle();

    expect(find.text('อินเทอร์เน็ตขัดข้อง ลองใหม่อีกครั้ง'), findsOneWidget);
    repo.failFetch = false;
    repo.returnEmptyCats = true;

    await tester.tap(find.text('ลองใหม่'));
    await tester.pumpAndSettle();

    expect(find.text('ยังไม่มีแมวที่ติดตาม'), findsOneWidget);
    await tester.tap(find.text('ไปหน้าแมวและฉัน'));
    await tester.pumpAndSettle();
    expect(find.text('หน้าแมวและฉัน'), findsOneWidget);
  });

  testWidgets(
    'สลับเป็นภาษาอังกฤษแสดงข้อความภาษาอังกฤษครบทั้งหน้าติดตามและตั้งค่าอุปกรณ์',
    (tester) async {
      _useMobileViewport(tester);
      final repo = _createRepo();

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(CatTrackerPage)),
      );
      container.read(appLocaleProvider.notifier).setLocale('en');
      await tester.pumpAndSettle();

      expect(find.text('Find my cat'), findsOneWidget);
      expect(find.text('My cats'), findsOneWidget);
      expect(find.text('At home'), findsOneWidget);
      expect(find.text('No tag yet · tap to add'), findsOneWidget);
      expect(find.text('Tap for full screen'), findsOneWidget);

      await tester.tap(find.text('Mali'));
      await tester.pumpAndSettle();
      expect(find.text('In the safe zone'), findsOneWidget);
      expect(find.text('Lost mode'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Device settings for Mali'));
      await tester.pumpAndSettle();
      expect(find.text('Device settings'), findsOneWidget);
      expect(find.text('My tags · 2 pcs'), findsOneWidget);
    },
  );
}

import 'dart:async';

import 'package:catlive/core/error/failure.dart';
import 'package:catlive/core/router/app_router.dart';
import 'package:catlive/core/theme/app_theme.dart';
import 'package:catlive/core/widgets/app_avatar.dart';
import 'package:catlive/features/my_cat/data/datasources/mock_my_cat_data_source.dart';
import 'package:catlive/features/my_cat/data/repositories/my_cat_repository_impl.dart';
import 'package:catlive/features/my_cat/domain/entities/my_cat_data.dart';
import 'package:catlive/features/my_cat/domain/repositories/my_cat_repository.dart';
import 'package:catlive/features/my_cat/presentation/pages/my_cat_page.dart';
import 'package:catlive/features/my_cat/presentation/providers/my_cat_providers.dart';
import 'package:catlive/features/my_cat/presentation/widgets/my_cat_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _ControlledMyCatRepository implements MyCatRepository {
  _ControlledMyCatRepository(this._inner);

  final MyCatRepository _inner;
  Completer<MyCatBundle>? pendingBundle;
  bool failFetch = false;
  bool failToggleCare = false;
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
  }) async {
    if (failToggleCare) {
      throw const ServerFailure('บันทึกไม่สำเร็จ');
    }
    return _inner.toggleCareTask(catId: catId, taskId: taskId, isDone: isDone);
  }

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

Widget _buildTestApp(_ControlledMyCatRepository repo) {
  final router = GoRouter(
    initialLocation: '/my-cat',
    routes: [
      GoRoute(path: '/my-cat', builder: (_, _) => const MyCatPage()),
      GoRoute(
        path: '/my-cat/health',
        builder: (_, _) =>
            const Scaffold(body: Center(child: Text('หน้าสมุดสุขภาพ'))),
      ),
      GoRoute(
        path: '/my-cat/profile',
        builder: (_, _) =>
            const Scaffold(body: Center(child: Text('หน้า Cat ID'))),
      ),
      GoRoute(
        path: '/my-cat/tracker',
        builder: (_, _) =>
            const Scaffold(body: Center(child: Text('หน้าตามหาแมว'))),
      ),
      GoRoute(
        path: '/guidelines',
        builder: (_, _) => const Scaffold(body: Center(child: Text('กฎชุมชน'))),
      ),
      GoRoute(
        path: '/nearby',
        builder: (_, _) => const Scaffold(body: Center(child: Text('ใกล้ฉัน'))),
      ),
    ],
  );

  return ProviderScope(
    overrides: [myCatRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
  );
}

_ControlledMyCatRepository _createRepo() => _ControlledMyCatRepository(
  MyCatRepositoryImpl(MockMyCatDataSource(delay: Duration.zero)),
);

void _useMobileViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('แสดง loading skeleton แล้วโหลดหน้าแมวและฉันของมะลิสำเร็จ', (
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
    expect(find.byType(GradientAvatar), findsOneWidget);
    expect(find.text('แมวของฉัน'), findsOneWidget);
    expect(find.text('ตัวฉัน'), findsOneWidget);
    expect(find.text('มะลิ'), findsAtLeastNWidgets(2));
    expect(find.text('ส้มจี๊ด'), findsOneWidget);
    expect(find.text('ถั่วดำ'), findsOneWidget);
    expect(find.text('เพิ่มแมว'), findsOneWidget);
    expect(find.text('@MAW000123 · รับเลี้ยงตั้งแต่ 2023'), findsOneWidget);
    expect(find.text('สมุดสุขภาพ'), findsOneWidget);
    expect(find.text('Cat ID'), findsOneWidget);
    expect(find.text('ตามหา'), findsOneWidget);
  });

  testWidgets('แสดง ErrorView เมื่อโหลดล้มเหลว และกดลองใหม่แล้วโหลดสำเร็จ', (
    tester,
  ) async {
    _useMobileViewport(tester);
    final repo = _createRepo()..failFetch = true;
    await tester.pumpWidget(_buildTestApp(repo));
    await tester.pumpAndSettle();

    expect(find.text('อินเทอร์เน็ตขัดข้อง ลองใหม่อีกครั้ง'), findsOneWidget);
    expect(find.text('ลองใหม่'), findsOneWidget);

    repo.failFetch = false;
    await tester.tap(find.text('ลองใหม่'));
    await tester.pumpAndSettle();

    expect(find.text('@MAW000123 · รับเลี้ยงตั้งแต่ 2023'), findsOneWidget);
  });

  testWidgets('แสดง Empty state เมื่อยังไม่มีแมวในบัญชี', (tester) async {
    _useMobileViewport(tester);
    final repo = _createRepo()..returnEmptyCats = true;
    await tester.pumpWidget(_buildTestApp(repo));
    await tester.pumpAndSettle();

    // เมื่อไม่มีแมว หน้าเริ่มต้นจะเป็นตัวฉัน และลิสต์แมวของฉันแสดงข้อความแนะนำ
    expect(find.text('แมวของฉัน 0 ตัว'), findsOneWidget);
    expect(
      find.text('ยังไม่มีแมวในบัญชี กด "+ เพิ่มแมว" ด้านบนเพื่อสร้างโปรไฟล์'),
      findsOneWidget,
    );
  });

  testWidgets('สลับโปรไฟล์เป็นส้มจี๊ดและตัวฉัน พร้อมเปิดชีตความน่าเชื่อถือ', (
    tester,
  ) async {
    _useMobileViewport(tester);
    final repo = _createRepo();
    await tester.pumpWidget(_buildTestApp(repo));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('ส้มจี๊ด'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ส้มจี๊ด'));
    await tester.pumpAndSettle();
    expect(find.text('@MAW000124 · รับเลี้ยงตั้งแต่ 2025'), findsOneWidget);

    await tester.ensureVisible(find.text('ตัวฉัน').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('ตัวฉัน').first);
    await tester.pumpAndSettle();
    expect(find.text('จุฑามาศ ลูกแก้ว'), findsOneWidget);
    expect(
      find.bySemanticsLabel('ยืนยันตัวตนแล้ว ดูรายละเอียด'),
      findsOneWidget,
    );
    expect(find.text('แมวของฉัน 3 ตัว'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('ยืนยันตัวตนแล้ว ดูรายละเอียด'));
    await tester.pumpAndSettle();
    expect(find.text('ความน่าเชื่อถือ 3/3 ขั้นตอน'), findsOneWidget);
    expect(find.text('ยืนยันเบอร์โทร'), findsOneWidget);
  });

  testWidgets(
    'สลับ 4 แท็บ ติ๊กงานดูแลวันนี้แบบ optimistic และย้อนกลับเมื่อ error',
    (tester) async {
      _useMobileViewport(tester);
      final repo = _createRepo();
      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      // แท็บ รูปภาพ -> กดดูรูปภาพเต็มจอ ครบ 5 ปุ่ม + ดูความคิดเห็นทั้งหมด
      await tester.tap(find.bySemanticsLabel('เปิดรูปที่ 1 ของมะลิ'));
      await tester.pumpAndSettle();
      expect(find.text('รูปภาพ มะลิ'), findsOneWidget);
      expect(find.text('48'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('ดูความคิดเห็นทั้งหมด 5 รายการ'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('ถูกใจ').first);
      await tester.pump();
      expect(find.text('49'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('รีโพสต์').first);
      await tester.pump();
      expect(find.bySemanticsLabel('ยกเลิกการรีโพสต์'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('บันทึก').first);
      await tester.pump();
      expect(find.bySemanticsLabel('ยกเลิกการบันทึก'), findsOneWidget);

      await tester.tap(find.text('ดูความคิดเห็นทั้งหมด 5 รายการ'));
      await tester.pumpAndSettle();
      expect(find.text('ความคิดเห็น 5'), findsOneWidget);

      await tester.tap(find.text('👏'));
      await tester.pumpAndSettle();
      expect(find.text('ความคิดเห็น 6'), findsOneWidget);

      await tester.tap(find.byTooltip('ปิด'));
      await tester.pumpAndSettle();
      expect(find.text('ดูความคิดเห็นทั้งหมด 6 รายการ'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('แชร์').first);
      await tester.pumpAndSettle();
      expect(find.text('แชร์รูป'), findsOneWidget);
      expect(
        find.textContaining('คนที่เปิดลิงก์จะเห็นหน้าโปรไฟล์สาธารณะ'),
        findsNothing,
      );
      await tester.tap(find.bySemanticsLabel('ปิด').last);
      await tester.pumpAndSettle();

      // กดย้อนกลับแล้วเปิดเข้ามาดูรูปที่ 1 ใหม่ — ค่าที่กดต้องยังคงอยู่ครบ
      await tester.tap(find.bySemanticsLabel('ย้อนกลับ'));
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('เปิดรูปที่ 1 ของมะลิ'));
      await tester.pumpAndSettle();
      expect(find.text('49'), findsOneWidget);
      expect(find.bySemanticsLabel('ยกเลิกการรีโพสต์'), findsOneWidget);
      expect(find.bySemanticsLabel('ยกเลิกการบันทึก'), findsOneWidget);
      expect(find.text('ดูความคิดเห็นทั้งหมด 6 รายการ'), findsOneWidget);

      await tester.tap(find.text('ดูความคิดเห็นทั้งหมด 6 รายการ'));
      await tester.pumpAndSettle();
      expect(find.text('ความคิดเห็น 6'), findsOneWidget);
      await tester.drag(find.byType(ListView).last, const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(find.textContaining('👏', findRichText: true), findsNWidgets(2));
      expect(find.text('เมื่อสักครู่'), findsOneWidget);
      await tester.tap(find.byTooltip('ปิด'));
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('ย้อนกลับ'));
      await tester.pumpAndSettle();

      // แท็บ ดูแลวันนี้
      await tester.tap(find.text('ดูแลวันนี้'));
      await tester.pumpAndSettle();
      expect(find.text('เสร็จ 2/5'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      await tester.ensureVisible(find.text('ทราย'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ทราย'));
      await tester.pump();
      expect(find.text('เสร็จ 3/5'), findsOneWidget);
      await tester.pumpAndSettle();

      // จำลอง API ล้มเหลว -> ต้องย้อนกลับเป็น 3/5 และแสดง toast
      repo.failToggleCare = true;
      await tester.ensureVisible(find.text('ยา'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ยา'));
      await tester.pumpAndSettle();
      expect(find.text('เสร็จ 3/5'), findsOneWidget);
      expect(find.text('บันทึกไม่สำเร็จ'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));

      // แท็บ สุขภาพ
      await tester.tap(find.text('สุขภาพ'));
      await tester.pumpAndSettle();
      expect(find.text('วัคซีนรวมครบกำหนดใน 12 วัน'), findsOneWidget);
      expect(find.text('ดูสมุดสุขภาพทั้งหมด'), findsOneWidget);

      // แท็บ ผู้ดูแล + ชวนผู้ดูแลเพิ่ม
      await tester.tap(find.text('ผู้ดูแล'));
      await tester.pumpAndSettle();
      expect(find.text('ผู้ดูแลในบ้าน 3 คน'), findsOneWidget);
      await tester.ensureVisible(find.text('ชวนผู้ดูแลเพิ่ม'));
      await tester.tap(find.text('ชวนผู้ดูแลเพิ่ม'));
      await tester.pumpAndSettle();
      expect(find.text('ให้สิทธิ์แบบไหน'), findsOneWidget);
      expect(find.text('รับคำเชิญ'), findsOneWidget);
      expect(
        find.text('https://www.xn--y3cm0f.live/join/carer-MAW000123'),
        findsOneWidget,
      );

      // สลับสิทธิ์เป็น ผู้ช่วยชั่วคราว แล้วลิงก์ + ข้อความตัวอย่างเปลี่ยนตาม
      await tester.tap(find.text('ผู้ช่วยชั่วคราว'));
      await tester.pumpAndSettle();
      expect(
        find.text('https://www.xn--y3cm0f.live/join/helper-MAW000123'),
        findsOneWidget,
      );
      expect(find.text('LINE'), findsNWidgets(2));
      expect(find.text('ส่งในแอป'), findsOneWidget);
      expect(find.text('QR'), findsOneWidget);

      await tester.ensureVisible(find.text('คัดลอก'));
      await tester.tap(find.text('คัดลอก'));
      await tester.pump();
      expect(find.text('คัดลอกแล้ว'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
    },
  );

  testWidgets('กด + เพิ่มแมว กรอกฟอร์มแล้วเพิ่มแมวใหม่เข้าแถวบนได้จริง', (
    tester,
  ) async {
    _useMobileViewport(tester);
    final repo = _createRepo();
    await tester.pumpWidget(_buildTestApp(repo));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('เพิ่มแมว'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('เพิ่มแมว'));
    await tester.pumpAndSettle();
    expect(find.text('เพิ่มแมวใหม่'), findsOneWidget);

    await tester.ensureVisible(find.text('สร้างโปรไฟล์แมว'));
    await tester.tap(find.text('สร้างโปรไฟล์แมว'));
    await tester.pumpAndSettle();
    expect(find.text('กรุณาระบุชื่อแมว'), findsOneWidget);

    // ชื่อซ้ำกับแมวที่มีอยู่ต้องไม่ผ่าน
    await tester.enterText(
      find.widgetWithText(TextFormField, 'เช่น มะลิ, ถั่วเขียว'),
      'มะลิ',
    );
    await tester.ensureVisible(find.text('สร้างโปรไฟล์แมว'));
    await tester.tap(find.text('สร้างโปรไฟล์แมว'));
    await tester.pumpAndSettle();
    expect(find.text('มีแมวชื่อ "มะลิ" อยู่ในบัญชีแล้ว'), findsOneWidget);

    // เลือกอายุจากชีตด้านล่างได้จริง
    await tester.tap(find.text('1 ปี'));
    await tester.pumpAndSettle();
    expect(find.text('เลือกอายุแมว'), findsOneWidget);
    await tester.tap(find.text('6 เดือน'));
    await tester.pumpAndSettle();
    expect(find.text('6 เดือน'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'เช่น มะลิ, ถั่วเขียว'),
      'ถั่วเขียว',
    );
    await tester.ensureVisible(find.text('สร้างโปรไฟล์แมว'));
    await tester.tap(find.text('สร้างโปรไฟล์แมว'));
    await tester.pumpAndSettle();

    expect(find.text('ถั่วเขียว'), findsAtLeastNWidgets(2));
    expect(
      find.text('@MAW000189 · รับเลี้ยงตั้งแต่ ${DateTime.now().year}'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('แก้ไขโปรไฟล์แมวและโปรไฟล์เจ้าของพร้อมเปิดที่อยู่รับขนมได้', (
    tester,
  ) async {
    _useMobileViewport(tester);
    final repo = _createRepo();
    await tester.pumpWidget(_buildTestApp(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('แก้ไข'));
    await tester.pumpAndSettle();
    expect(find.text('แก้ไขโปรไฟล์แมว'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'มะลิ'),
      'มะลิขาว',
    );
    await tester.tap(find.widgetWithText(TextButton, 'บันทึก'));
    await tester.pumpAndSettle();
    expect(find.text('มะลิขาว'), findsAtLeastNWidgets(2));
    await tester.pump(const Duration(seconds: 2));

    await tester.ensureVisible(find.text('ตัวฉัน').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('ตัวฉัน').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('แก้ไขโปรไฟล์'));
    await tester.pumpAndSettle();
    final treatFinder = find.text(
      'ยังไม่ได้ตั้งที่อยู่ เพิ่มเพื่อให้คนอื่นเลี้ยงขนมแมวของคุณได้',
    );
    await tester.ensureVisible(treatFinder);
    await tester.pumpAndSettle();
    expect(find.text('ที่อยู่รับขนมแมว'), findsOneWidget);
    await tester.tap(treatFinder);
    await tester.pumpAndSettle();
    expect(
      find.text(
        'ข้อมูลนี้เห็นเฉพาะคุณและระบบจัดส่ง · คนที่เลี้ยงขนมจะไม่เห็นที่อยู่จริงของคุณ',
      ),
      findsOneWidget,
    );
  });

  testWidgets('หน้าตั้งค่าแสดง toast ทันทีและสลับภาษา ไทย/EN ได้จริง', (
    tester,
  ) async {
    _useMobileViewport(tester);
    final repo = _createRepo();
    await tester.pumpWidget(_buildTestApp(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('ตั้งค่า'));
    await tester.pumpAndSettle();
    expect(find.text('ตั้งค่า'), findsOneWidget);

    await tester.tap(find.text('การแจ้งเตือน'));
    await tester.pumpAndSettle();
    expect(find.text('ปิดการแจ้งเตือนแล้ว'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));

    await tester.tap(find.text('ความเป็นส่วนตัว'));
    await tester.pumpAndSettle();
    expect(find.text('ความเป็นส่วนตัว · หน้านี้กำลังพัฒนา'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));

    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();
    expect(find.text('Switched to English'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));

    await tester.tap(find.bySemanticsLabel('Close settings'));
    await tester.pumpAndSettle();
    expect(find.text('My cats'), findsOneWidget);
    expect(find.text('Mali'), findsAtLeastNWidgets(2));
    expect(find.text('Siamese · Female · spayed'), findsOneWidget);

    await tester.tap(find.text('Health'));
    await tester.pumpAndSettle();
    expect(find.text('Combo vaccine due in 12 days'), findsOneWidget);
    expect(find.text('26 Oct 2026'), findsOneWidget);

    await tester.tap(find.text('Me').first);
    await tester.pumpAndSettle();
    expect(find.text('Jutamas Lukkaew'), findsOneWidget);
    expect(find.text('My cats 3 cats'), findsOneWidget);
  });

  testWidgets('สลับภาษา EN เปลี่ยนแถบเมนูล่างและหน้าย่อยชั่วคราวด้วย', (
    tester,
  ) async {
    _useMobileViewport(tester);
    final repo = _createRepo();
    final router = createAppRouter();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [myCatRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('แมวและฉัน'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.bySemanticsLabel('ตั้งค่า'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('EN'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.bySemanticsLabel('Close settings'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Feed'), findsOneWidget);
    expect(find.text('Nearby'), findsOneWidget);
    expect(find.text('Help'), findsOneWidget);
    expect(find.text('My Cat'), findsOneWidget);

    await tester.tap(find.text('Health book'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Health book'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Next appointment'), findsOneWidget);
  });
}

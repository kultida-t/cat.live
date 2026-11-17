import 'package:catlive/core/config/app_locale.dart';
import 'package:catlive/core/config/app_text_scale.dart';
import 'package:catlive/core/error/failure.dart';
import 'package:catlive/features/settings/domain/entities/settings_data.dart';
import 'package:catlive/features/settings/domain/repositories/settings_repository.dart';
import 'package:catlive/features/settings/presentation/pages/settings_page.dart';
import 'package:catlive/features/settings/presentation/providers/settings_controller.dart';
import 'package:catlive/features/settings/presentation/widgets/settings_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _EmptySettingsRepo implements SettingsRepository {
  @override
  Future<SettingsData> getSettings() async => const SettingsData(
    accountName: '',
    accountHandle: '',
    accountVerified: false,
    pushEnabled: true,
    quietHoursEnabled: false,
    quietStart: '22:00',
    quietEnd: '07:00',
    notificationCategories: {},
    pdpaConsents: [],
    dataExportRequested: false,
    faqs: [],
    appVersion: '0.1',
  );

  @override
  Future<SettingsData> saveSettings(SettingsData next) async => next;

  @override
  Future<void> requestDataExport() async {}

  @override
  Future<void> submitSupportMessage({
    required String subject,
    required String message,
  }) async {}
}

class _FailingSettingsRepo implements SettingsRepository {
  @override
  Future<SettingsData> getSettings() async =>
      throw const UnknownFailure('เชื่อมต่อไม่สำเร็จ');

  @override
  Future<SettingsData> saveSettings(SettingsData next) async => next;

  @override
  Future<void> requestDataExport() async {}

  @override
  Future<void> submitSupportMessage({
    required String subject,
    required String message,
  }) async {}
}

Widget _wrapSettings({
  SettingsRepository? repo,
  void Function(WidgetRef ref)? onRefReady,
}) {
  final router = GoRouter(
    initialLocation: '/settings',
    routes: [
      GoRoute(path: '/settings', builder: (_, _) => const SettingsPage()),
      GoRoute(
        path: '/settings/guidelines',
        builder: (_, _) => const Scaffold(body: Text('Guidelines')),
      ),
      GoRoute(
        path: '/settings/tracker',
        builder: (_, _) => const Scaffold(body: Text('Tracker')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      if (repo != null) settingsRepositoryProvider.overrideWithValue(repo),
    ],
    child: Consumer(
      builder: (context, ref, _) {
        onRefReady?.call(ref);
        return MaterialApp.router(routerConfig: router);
      },
    ),
  );
}

void main() {
  testWidgets('แสดง Skeleton และโหลดรายการตั้งค่าครบทุกหมวด (SET-01)', (
    tester,
  ) async {
    await tester.pumpWidget(_wrapSettings());
    expect(find.byType(SettingsSkeleton), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(find.text('ตั้งค่าและช่วยเหลือ'), findsOneWidget);
    expect(find.text('จุฑามาศ ลูกแก้ว'), findsOneWidget);
    expect(find.text('ภาษา'), findsOneWidget);
    expect(find.text('ขนาดตัวอักษร'), findsOneWidget);
    expect(find.text('การแจ้งเตือน'), findsNWidgets(2));
    expect(find.text('โหมดเงียบ'), findsOneWidget);
    expect(find.text('จัดการประเภทการแจ้งเตือน'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('ออกจากระบบ'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('ความเป็นส่วนตัว & PDPA'), findsNWidgets(2));
    expect(find.text('ศูนย์ช่วยเหลือ & ติดต่อทีม'), findsOneWidget);
    expect(find.text('ออกจากระบบ'), findsOneWidget);
  });

  testWidgets('แสดง Empty และ Error state พร้อมปุ่มลองใหม่', (tester) async {
    await tester.pumpWidget(_wrapSettings(repo: _EmptySettingsRepo()));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.text('ยังไม่มีข้อมูลการตั้งค่า'), findsOneWidget);

    await tester.pumpWidget(_wrapSettings(repo: _FailingSettingsRepo()));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.text('โหลดการตั้งค่าไม่สำเร็จ'), findsOneWidget);
    expect(find.text('เชื่อมต่อไม่สำเร็จ'), findsOneWidget);
  });

  testWidgets('สลับภาษา EN และเปลี่ยนขนาดตัวอักษรมีผลทันที (SET-01)', (
    tester,
  ) async {
    late WidgetRef capturedRef;
    await tester.pumpWidget(
      _wrapSettings(onRefReady: (ref) => capturedRef = ref),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();
    expect(find.text('Settings & Help'), findsOneWidget);
    expect(capturedRef.read(appLocaleProvider), 'en');

    await tester.tap(find.text('Large'));
    await tester.pumpAndSettle();
    expect(capturedRef.read(appTextScaleProvider), AppTextSizePreset.large);
  });

  testWidgets(
    'จัดการประเภทการแจ้งเตือน 8 หมวด และ "มีคนพบแมว" ปิดไม่ได้ (NOTI-01)',
    (tester) async {
      await tester.pumpWidget(_wrapSettings());
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      await tester.tap(find.text('จัดการประเภทการแจ้งเตือน'));
      await tester.pumpAndSettle();

      expect(find.text('มีคนพบแมว (สแกน Cat ID)'), findsOneWidget);
      expect(find.text('ปิดไม่ได้'), findsOneWidget);

      await tester.tap(find.text('มีคนพบแมว (สแกน Cat ID)'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'ไม่สามารถปิดแจ้งเตือน "มีคนพบแมว" ได้ เพื่อความปลอดภัยของน้องแมว',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('ตั้งเวลาโหมดเงียบ 23:00 – 06:00 ได้ (NOTI-02)', (tester) async {
    await tester.pumpWidget(_wrapSettings());
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    await tester.tap(find.text('โหมดเงียบ'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('23:00 – 06:00'));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();

    expect(
      find.text('ไม่แจ้งเตือน 23:00–06:00 ยกเว้นเตือนยาและพบแมว'),
      findsOneWidget,
    );
  });

  testWidgets('เปิดชีต PDPA ถอนความยินยอม และขอสำเนาข้อมูลได้ (PDPA-01/02)', (
    tester,
  ) async {
    await tester.pumpWidget(_wrapSettings());
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    // scroll หา subtitle ของแถว PDPA ซึ่ง unique
    // (ชื่อ 'ความเป็นส่วนตัว & PDPA' ซ้ำกันทั้ง section header และ row)
    await tester.scrollUntilVisible(
      find.textContaining('ขอสำเนาข้อมูล'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('ความเป็นส่วนตัว & PDPA').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('ความเป็นส่วนตัว & PDPA').last);
    await tester.pumpAndSettle();

    expect(find.text('ตำแหน่งที่ตั้ง (Location)'), findsOneWidget);
    expect(find.text('ข่าวสารการตลาดและโปรโมชัน'), findsOneWidget);
    expect(find.text('ใช้ข้อมูลช่วยฝึกฝน Cat AI'), findsOneWidget);

    final sheetScrollable = find
        .descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('ขอสำเนาข้อมูลของฉัน (JSON + PDF)'),
      200,
      scrollable: sheetScrollable,
    );
    await tester.tap(find.text('ขอสำเนาข้อมูลของฉัน (JSON + PDF)'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(
      find.text('ส่งคำขอสำเนาข้อมูลแล้ว (รับ JSON + PDF ภายใน 30 วัน)'),
      findsOneWidget,
    );
  });

  testWidgets('เปิดศูนย์ช่วยเหลือ กาง FAQ และกดออกจากระบบแสดง Dialog', (
    tester,
  ) async {
    await tester.pumpWidget(_wrapSettings());
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('ออกจากระบบ'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('ศูนย์ช่วยเหลือ & ติดต่อทีม'));
    await tester.pumpAndSettle();

    expect(find.text('คำถามที่พบบ่อย (FAQ)'), findsOneWidget);
    final sheetScrollable = find
        .descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('ส่งข้อความ'),
      200,
      scrollable: sheetScrollable,
    );
    await tester.tap(find.text('ส่งข้อความ'));
    await tester.pumpAndSettle();
    expect(find.text('กรุณากรอกหัวข้อและรายละเอียดก่อนส่ง'), findsOneWidget);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ออกจากระบบ'));
    await tester.pumpAndSettle();
    expect(find.text('ออกจากระบบ?'), findsOneWidget);
  });
}

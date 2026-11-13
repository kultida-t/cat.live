import 'package:catlive/core/config/app_locale.dart';
import 'package:catlive/core/error/failure.dart';
import 'package:catlive/features/menu/domain/entities/menu_data.dart';
import 'package:catlive/features/menu/domain/repositories/menu_repository.dart';
import 'package:catlive/features/menu/presentation/pages/menu_page.dart';
import 'package:catlive/features/menu/presentation/providers/menu_controller.dart';
import 'package:catlive/features/menu/presentation/widgets/menu_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _EmptyMenuRepo implements MenuRepository {
  @override
  Future<MenuData> getMenuData() async =>
      const MenuData(services: [], settings: MenuSettings(), appVersion: '0.1');

  @override
  Future<MenuSettings> saveSettings(MenuSettings settings) async => settings;
}

class _FailingMenuRepo implements MenuRepository {
  @override
  Future<MenuData> getMenuData() async =>
      throw const UnknownFailure('เชื่อมต่อไม่สำเร็จ');

  @override
  Future<MenuSettings> saveSettings(MenuSettings settings) async =>
      throw const UnknownFailure('บันทึกไม่สำเร็จ');
}

Widget _wrapMenu({MenuRepository? repo, String initialLocale = 'th'}) {
  final router = GoRouter(
    initialLocation: '/menu',
    routes: [
      GoRoute(path: '/menu', builder: (_, _) => const MenuPage()),
      GoRoute(
        path: '/cat-profile',
        builder: (_, _) => const Scaffold(body: Text('Cat ID')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      if (repo != null) menuRepositoryProvider.overrideWithValue(repo),
    ],
    child: Consumer(
      builder: (context, ref, child) {
        if (initialLocale == 'en' && ref.read(appLocaleProvider) != 'en') {
          Future.microtask(
            () => ref.read(appLocaleProvider.notifier).setLocale('en'),
          );
        }
        return MaterialApp.router(routerConfig: router);
      },
    ),
  );
}

void main() {
  testWidgets(
    'แสดงบริการเสริม 8 รายการตรงตามเว็บจริงและไม่มีตั้งค่า/ออกจากระบบ',
    (tester) async {
      await tester.pumpWidget(_wrapMenu());
      expect(find.byType(MenuSkeleton), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.text('บริการเสริม'), findsOneWidget);
      expect(find.text('แมว.live Tag'), findsOneWidget);
      expect(find.text('เลี้ยงอาหารน้อง ๆ'), findsOneWidget);
      expect(find.text('บริการรำลึก'), findsOneWidget);
      expect(find.text('ฌาปนกิจแมว'), findsOneWidget);
      expect(find.text('เว็บไซต์รำลึก'), findsOneWidget);
      expect(find.text('สั่งพิมพ์ Cat ID / ป้าย QR'), findsOneWidget);
      expect(find.text('ใบเพ็ดดีกรี'), findsOneWidget);
      expect(find.text('ประกันสุขภาพแมว'), findsOneWidget);
      expect(find.text('เร็ว ๆ นี้'), findsNWidgets(2));

      expect(find.text('ตั้งค่า'), findsNothing);
      expect(find.text('ออกจากระบบ'), findsNothing);
    },
  );

  testWidgets('แสดง Empty state พร้อมปุ่มลองใหม่', (tester) async {
    await tester.pumpWidget(_wrapMenu(repo: _EmptyMenuRepo()));
    await tester.pumpAndSettle();
    expect(find.text('ยังไม่มีรายการเมนู'), findsOneWidget);
    expect(find.text('ลองใหม่'), findsOneWidget);
  });

  testWidgets('แสดง Error state พร้อมปุ่มลองใหม่', (tester) async {
    await tester.pumpWidget(_wrapMenu(repo: _FailingMenuRepo()));
    await tester.pumpAndSettle();
    expect(find.text('โหลดเมนูไม่สำเร็จ'), findsOneWidget);
    expect(find.text('เชื่อมต่อไม่สำเร็จ'), findsOneWidget);
  });

  testWidgets('กดบริการที่กำลังพัฒนา/เร็ว ๆ นี้ แสดง toast และรองรับภาษา EN', (
    tester,
  ) async {
    await tester.pumpWidget(_wrapMenu(initialLocale: 'en'));
    await tester.pumpAndSettle();

    expect(find.text('Services'), findsOneWidget);
    expect(find.text('Coming soon'), findsNWidgets(2));

    await tester.tap(find.text('Pedigree'));
    await tester.pumpAndSettle();
    expect(find.text('Pedigree — Coming soon'), findsOneWidget);
  });
}

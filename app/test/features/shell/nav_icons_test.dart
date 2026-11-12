import 'package:catlive/core/theme/app_colors.dart';
import 'package:catlive/features/shell/presentation/nav_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ไอคอนแมวและฉันมี CustomPaint สำหรับขยับลูกตาซ้าย-ขวา', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: NavIcon(name: NavIconName.myCat, active: false)),
      ),
    );

    final customPaintFinder = find.descendant(
      of: find.byType(NavIcon),
      matching: find.byType(CustomPaint),
    );
    expect(customPaintFinder, findsOneWidget);

    await tester.pump(const Duration(milliseconds: 700));
    expect(customPaintFinder, findsOneWidget);
  });

  test('สีปุ่มติดตามแล้วเป็นสีขาวตรงตามหน้าตัวอย่าง', () {
    expect(AppColors.btnFollowing, Colors.white);
  });

  testWidgets('ไอคอน Cat AI (active) มี CustomPaint ดาววิบวับ และ Help (active) มี ScaleTransition', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              NavIcon(name: NavIconName.ai, active: true),
              NavIcon(name: NavIconName.help, active: true),
            ],
          ),
        ),
      ),
    );

    expect(
      find.descendant(
        of: find.byWidgetPredicate(
          (w) => w is NavIcon && w.name == NavIconName.ai,
        ),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byWidgetPredicate(
          (w) => w is NavIcon && w.name == NavIconName.help,
        ),
        matching: find.byType(ScaleTransition),
      ),
      findsOneWidget,
    );
  });
}

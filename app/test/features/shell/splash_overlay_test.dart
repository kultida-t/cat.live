import 'package:catlive/core/theme/app_theme.dart';
import 'package:catlive/features/shell/presentation/splash_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void _useMobileViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets(
    'แสดงหน้าแอนิเมชันเปิดแอปพร้อมโลโก้ ข้อความ และจบเองใน ~4.05 วินาที',
    (tester) async {
      _useMobileViewport(tester);
      var finished = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Stack(
            children: [
              const Scaffold(body: Center(child: Text('หน้าแรก'))),
              SplashOverlay(onFinished: () => finished = true),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(find.text('เพราะทุกแมวมีเรื่องราวที่สำคัญ'), findsOneWidget);
      expect(find.text('แตะเพื่อเข้าแอป'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(finished, isFalse);

      // ที่ 2.8 วินาที โลโก้แสดงเต็มที่แล้ว แต่แอนิเมชันยังไม่จบ
      await tester.pump(const Duration(milliseconds: 2800));
      expect(find.bySemanticsLabel('แมว.live'), findsOneWidget);
      expect(finished, isFalse);

      // ผ่านไปครบ 3.6 วินาที เริ่ม fade-out และจบที่ ~4.05 วินาที
      await tester.pump(const Duration(milliseconds: 800));
      expect(finished, isFalse);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(finished, isTrue);
    },
  );

  testWidgets('แตะตรงไหนก็ได้บนหน้าแอนิเมชันเพื่อข้ามเข้าแอปทันที', (
    tester,
  ) async {
    _useMobileViewport(tester);
    var finished = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: SplashOverlay(onFinished: () => finished = true),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('แตะเพื่อเข้าแอป'));
    await tester.pumpAndSettle();
    expect(finished, isTrue);
  });

  testWidgets('รองรับภาษาอังกฤษและโหมดลดแอนิเมชัน (disableAnimations)', (
    tester,
  ) async {
    _useMobileViewport(tester);
    var finished = false;

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(390, 844),
          disableAnimations: true,
        ),
        child: MaterialApp(
          theme: AppTheme.light,
          home: SplashOverlay(isEn: true, onFinished: () => finished = true),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.text('Because every cat has a story that matters'),
      findsOneWidget,
    );
    expect(find.text('Tap to enter'), findsOneWidget);

    await tester.tap(find.byType(SplashOverlay));
    await tester.pumpAndSettle();
    expect(finished, isTrue);
  });
}

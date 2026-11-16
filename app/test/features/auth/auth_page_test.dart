import 'package:catlive/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:catlive/features/auth/domain/usecases/auth_rules.dart';
import 'package:catlive/features/auth/presentation/pages/login_page.dart';
import 'package:catlive/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Widget _wrapLoginPage({
  void Function(WidgetRef ref)? onRefReady,
  AuthRemoteDataSource? remoteDataSource,
}) {
  final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
      GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Text('Home'))),
    ],
  );
  return ProviderScope(
    overrides: [
      if (remoteDataSource != null)
        authRemoteDataSourceProvider.overrideWithValue(remoteDataSource),
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
  test('AuthRules ตรวจเบอร์ไทย, ปิดบังเบอร์ และเกณฑ์อายุ PDPA-03 ถูกต้อง', () {
    expect(AuthRules.isValidThaiPhone('0812345678'), isTrue);
    expect(AuthRules.isValidThaiPhone('+66812345678'), isTrue);
    expect(AuthRules.isValidThaiPhone('12345'), isFalse);
    expect(AuthRules.maskThaiPhone('0812345678'), '081-xxx-5678');

    expect(
      AuthRules.evaluateAge(birthYear: 2016, currentYear: 2026),
      AgeEligibility.under13Blocked,
    );
    expect(
      AuthRules.evaluateAge(birthYear: 2010, currentYear: 2026),
      AgeEligibility.minorNeedsGuardianConsent,
    );
    expect(
      AuthRules.evaluateAge(birthYear: 1995, currentYear: 2026),
      AgeEligibility.adult,
    );
  });

  testWidgets('LoginPage ขอ OTP, กรอกผิด 5 ครั้งล็อก 15 นาที, และยืนยันสำเร็จ', (
    tester,
  ) async {
    WidgetRef? capturedRef;
    await tester.pumpWidget(
      _wrapLoginPage(
        remoteDataSource: MockAuthRemoteDataSource(latency: Duration.zero),
        onRefReady: (r) => capturedRef = r,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ยินดีต้อนรับสู่ แมว.live'), findsOneWidget);

    // 1. กรอกเบอร์ไม่ถูกต้อง -> แจ้ง error
    await tester.enterText(find.byType(TextField).first, '1234');
    await tester.tap(find.text('ขอรหัส OTP'));
    await tester.pumpAndSettle();
    expect(
      find.text('กรุณากรอกเบอร์มือถือไทย 10 หลักให้ถูกต้อง (เช่น 0812345678)'),
      findsOneWidget,
    );

    // 2. กรอกเบอร์ถูกต้อง -> ขอ OTP สำเร็จ
    await tester.enterText(find.byType(TextField).first, '0812345678');
    await tester.tap(find.text('ขอรหัส OTP'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump();
    expect(find.text('ยืนยันรหัส OTP'), findsWidgets);
    expect(find.textContaining('Ref: ML5678'), findsOneWidget);

    // 3. กรอกผิด 5 ครั้ง -> ล็อก 15 นาที
    for (var i = 1; i <= 5; i++) {
      await tester.enterText(find.byType(TextField).first, '000000');
      await tester.tap(find.text('ยืนยันและเข้าสู่ระบบ'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();
    }
    expect(find.textContaining('กรอกรหัสผิดครบ 5 ครั้ง'), findsOneWidget);

    // 4. เปลี่ยนเบอร์แล้วขอใหม่ + กดเติม 123456 แล้วยืนยันสำเร็จ
    await tester.tap(find.text('เปลี่ยนเบอร์โทรศัพท์'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, '0812345678');
    await tester.tap(find.text('ขอรหัส OTP'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump();

    await tester.tap(find.text('กรอก 123456'));
    await tester.pump();
    await tester.tap(find.text('ยืนยันและเข้าสู่ระบบ'));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(capturedRef!.read(authControllerProvider).isAuthenticated, isTrue);
  });

  testWidgets('LoginPage รองรับเข้าใช้งานต่อแบบผู้เยี่ยมชม (Guest Mode)', (
    tester,
  ) async {
    WidgetRef? capturedRef;
    await tester.pumpWidget(
      _wrapLoginPage(
        remoteDataSource: MockAuthRemoteDataSource(latency: Duration.zero),
        onRefReady: (r) => capturedRef = r,
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('เข้าใช้งานต่อแบบผู้เยี่ยมชม (Guest Mode)'),
      200,
    );
    await tester.tap(find.text('เข้าใช้งานต่อแบบผู้เยี่ยมชม (Guest Mode)'));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(capturedRef!.read(authControllerProvider).isGuest, isTrue);
  });

  testWidgets('LoginPage รองรับ Social Login (Apple / Google / LINE)', (
    tester,
  ) async {
    WidgetRef? capturedRef;
    await tester.pumpWidget(
      _wrapLoginPage(
        remoteDataSource: MockAuthRemoteDataSource(latency: Duration.zero),
        onRefReady: (r) => capturedRef = r,
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('ดำเนินการต่อด้วย LINE'),
      200,
    );
    await tester.tap(find.text('ดำเนินการต่อด้วย LINE'));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(capturedRef!.read(authControllerProvider).isAuthenticated, isTrue);
  });
}

import 'package:catlive/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:catlive/features/auth/data/datasources/auth_token_storage.dart';
import 'package:catlive/features/auth/domain/entities/auth_data.dart';
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
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Text('Home')),
      ),
    ],
  );
  // seed session เป็น guest — ไม่อย่างนั้น mock จะ restore เป็นล็อกอินแล้ว
  // ทำให้ guard ของหน้า /login เด้งออกก่อน test ได้ทดสอบฟอร์ม
  final guestStorage = InMemoryAuthTokenStorage()
    ..saveSession(const AuthSession.guest());
  return ProviderScope(
    overrides: [
      authTokenStorageProvider.overrideWithValue(guestStorage),
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

Widget _wrapRouter({required String initialLocation, bool seedGuest = true}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, state) => LoginPage(
          returnTo: state.uri.queryParameters['return'],
          initialRegister: state.uri.queryParameters['mode'] == 'register',
        ),
      ),
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Text('Home')),
      ),
      GoRoute(
        path: '/treats',
        builder: (_, _) => const Scaffold(body: Text('Treats')),
      ),
    ],
  );
  final overrides = [
    authRemoteDataSourceProvider.overrideWithValue(
      MockAuthRemoteDataSource(latency: Duration.zero),
    ),
    if (seedGuest)
      authTokenStorageProvider.overrideWithValue(
        InMemoryAuthTokenStorage()..saveSession(const AuthSession.guest()),
      ),
  ];
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(routerConfig: router),
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

  testWidgets(
    'แท็บสมัครสมาชิก: เปิดอ่านรายละเอียด PDPA, Wheel Picker, และขอ/ยืนยัน OTP สำเร็จ',
    (tester) async {
      WidgetRef? capturedRef;
      await tester.pumpWidget(
        _wrapLoginPage(
          remoteDataSource: MockAuthRemoteDataSource(latency: Duration.zero),
          onRefReady: (r) => capturedRef = r,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ยินดีต้อนรับสู่ แมว.live'), findsOneWidget);
      expect(
        find.text('ดูแลโปรไฟล์ สมุดสุขภาพ และชุมชนคนรักแมว'),
        findsOneWidget,
      );

      // สลับไปแท็บ สมัครสมาชิก
      await tester.tap(find.text('สมัครสมาชิก'));
      await tester.pumpAndSettle();

      // 1. เปิด Wheel Picker ปีเกิด
      await tester.tap(find.text('1995 (พ.ศ. 2538)'));
      await tester.pumpAndSettle();
      expect(find.text('เลือกปีเกิด'), findsOneWidget);
      await tester.tap(find.text('ตกลง'));
      await tester.pumpAndSettle();

      // 2. ติ๊ก PDPA
      await tester.tap(find.byType(Checkbox).first);
      await tester.pump();

      // 3. กรอกเบอร์ไม่ครบ -> ปุ่มขอ OTP ยังกดไม่ได้ (disabled)
      await tester.enterText(find.byType(TextField).last, '1234');
      await tester.pump();
      final disabledBtn = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'ขอรหัส OTP'),
      );
      expect(disabledBtn.onPressed, isNull);

      // 4. กรอกเบอร์ถูกต้อง -> ขอ OTP สำเร็จ
      await tester.enterText(find.byType(TextField).last, '0812345678');
      await tester.pump();
      await tester.ensureVisible(find.text('ขอรหัส OTP'));
      await tester.tap(find.text('ขอรหัส OTP'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();
      expect(find.text('ยืนยันรหัส OTP'), findsWidgets);
      expect(find.textContaining('Ref: ML5678'), findsOneWidget);

      // ยังไม่กรอก OTP -> ปุ่มยืนยันต้อง disabled (ไม่หักสิทธิ์)
      final verifyDisabled = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'ยืนยันรหัส OTP'),
      );
      expect(verifyDisabled.onPressed, isNull);

      // 5. กรอกผิด 5 ครั้ง -> ล็อก 15 นาที
      for (var i = 1; i <= 5; i++) {
        await tester.enterText(find.byType(TextField).first, '000000');
        await tester.pump();
        await tester.tap(find.widgetWithText(FilledButton, 'ยืนยันรหัส OTP'));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump();
      }
      expect(find.textContaining('กรอกรหัสผิดครบ 5 ครั้ง'), findsOneWidget);

      // 6. เปลี่ยนเบอร์แล้วขอใหม่ + กดเติม 123456 แล้วยืนยันสำเร็จ
      await tester.tap(find.text('เปลี่ยนเบอร์โทรศัพท์'));
      await tester.pump();
      await tester.enterText(find.byType(TextField).last, '0812345678');
      await tester.pump();
      await tester.ensureVisible(find.text('ขอรหัส OTP'));
      await tester.tap(find.text('ขอรหัส OTP'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();

      await tester.enterText(find.byType(TextField).first, '123456');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'ยืนยันรหัส OTP'));
      await tester.pumpAndSettle();

      // เบอร์นี้ยังไม่มี PIN บนเครื่อง → ต้องเจอขั้นเสนอตั้ง PIN ก่อนเข้าแอป
      expect(find.text('ตั้งรหัส PIN 6 หลัก'), findsWidgets);
      await tester.ensureVisible(find.text('ไว้ทีหลัง'));
      await tester.tap(find.text('ไว้ทีหลัง'));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(capturedRef!.read(authControllerProvider).isAuthenticated, isTrue);
    },
  );

  testWidgets('แท็บเข้าสู่ระบบ: เข้า Guest Mode และ Social Login (LINE) ได้', (
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

    // กดเข้า Guest Mode
    await tester.scrollUntilVisible(
      find.text('เข้าใช้งานต่อแบบผู้เยี่ยมชม (Guest Mode)'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(
      find.text('เข้าใช้งานต่อแบบผู้เยี่ยมชม (Guest Mode)'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('เข้าใช้งานต่อแบบผู้เยี่ยมชม (Guest Mode)'));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(capturedRef!.read(authControllerProvider).isGuest, isTrue);
  });

  testWidgets('แท็บเข้าสู่ระบบ: เข้าด้วยเบอร์โทร + PIN 6 หลักได้', (
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

    // เบอร์เดโมที่ seed PIN ไว้ (จุฑามาศ) — ตัวจริงคือ 0812344567
    await tester.enterText(find.byType(TextField).first, '0812344567');
    await tester.enterText(find.byType(TextField).last, '123456');
    await tester.pump();

    await tester.tap(find.text('เข้าสู่ระบบด้วย PIN'));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(capturedRef!.read(authControllerProvider).isAuthenticated, isTrue);
  });

  testWidgets('AUTH-02: ล็อกอินด้วย PIN สำเร็จแล้วกลับไปปลายทางที่ตั้งใจไว้', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrapRouter(initialLocation: '/login?return=%2Ftreats%3Fto%3Dmali'),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '0812344567');
    await tester.enterText(find.byType(TextField).last, '123456');
    await tester.pump();
    await tester.tap(find.text('เข้าสู่ระบบด้วย PIN'));
    await tester.pumpAndSettle();

    expect(find.text('Treats'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
  });

  testWidgets('AUTH-02: mode=register เปิดแท็บสมัครสมาชิกให้เลย', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrapRouter(initialLocation: '/login?mode=register'),
    );
    await tester.pumpAndSettle();

    // แท็บสมัครต้องแสดงช่องชื่อที่แสดงกับปีเกิดทันทีโดยไม่ต้องกดสลับแท็บ
    expect(find.text('ชื่อที่แสดง (ไม่บังคับ)'), findsOneWidget);
    expect(find.textContaining('ปีเกิด'), findsWidgets);
  });

  testWidgets(
    'AUTH-02: ผู้ใช้ที่ล็อกอินอยู่แล้วเข้า /login จะถูกเด้งกลับหน้าแรก',
    (tester) async {
      // ไม่ seed guest — mock restore จะได้ session ล็อกอินค่าเริ่มต้น
      await tester.pumpWidget(
        _wrapRouter(initialLocation: '/login', seedGuest: false),
      );
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
    },
  );

  testWidgets('แท็บเข้าสู่ระบบ: กด Social Login LINE สำเร็จทันที', (
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
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('ดำเนินการต่อด้วย LINE'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ดำเนินการต่อด้วย LINE'));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(capturedRef!.read(authControllerProvider).isAuthenticated, isTrue);
  });
}

import 'package:catlive/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:catlive/features/auth/data/datasources/auth_token_storage.dart';
import 'package:catlive/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:catlive/features/auth/domain/entities/auth_data.dart';
import 'package:catlive/features/auth/presentation/pages/delete_account_page.dart';
import 'package:catlive/features/auth/presentation/pages/login_page.dart';
import 'package:catlive/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _authedSession = AuthSession(
  mode: AuthMode.authenticated,
  user: AuthUser(
    id: 'user-lookkaew',
    displayName: 'จุฑามาศ ลูกแก้ว',
    method: AuthMethod.phoneOtp,
    phoneMasked: '081-xxx-4567',
    birthYear: 1995,
  ),
  accessToken: 'test-token',
);

Widget _wrapDeletePage({
  required InMemoryAuthTokenStorage storage,
  required MockAuthRemoteDataSource remote,
}) {
  final router = GoRouter(
    initialLocation: '/settings/delete-account',
    routes: [
      GoRoute(
        path: '/settings/delete-account',
        builder: (_, _) => const DeleteAccountPage(),
      ),
      GoRoute(
        path: '/settings',
        builder: (_, _) => const Scaffold(body: Text('Settings')),
      ),
      GoRoute(
        path: '/login',
        builder: (_, _) => const Scaffold(body: Text('Login')),
      ),
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Text('Home')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      authTokenStorageProvider.overrideWithValue(storage),
      authRemoteDataSourceProvider.overrideWithValue(remote),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  group('AUTH-05 mock flow', () {
    test(
      'ขอลบบัญชีแล้วล็อกอินใหม่ภายใน 30 วันเจอ session ค้างลบ และกู้คืนได้',
      () async {
        final remote = MockAuthRemoteDataSource(latency: Duration.zero);

        await remote.requestAccountDeletion(
          accessToken: 't',
          transferDecisions: const {'cat-mali': 'cg-mom'},
        );

        final pending = await remote.signInWithProvider(
          method: AuthMethod.phoneOtp,
          birthYear: 1995,
          guardianConsentGranted: false,
        );
        expect(pending.isPendingDeletion, isTrue);
        expect(pending.deletionScheduledAt, isNotNull);

        final restored = await remote.restorePendingDeletion('t');
        expect(restored, isNotNull);
        expect(restored!.isPendingDeletion, isFalse);

        // กู้แล้ว → ล็อกอินครั้งต่อไปเจอบัญชีปกติ ไม่ใช่ค้างลบ
        expect(await remote.restorePendingDeletion('t'), isNull);
        final normal = await remote.signInWithProvider(
          method: AuthMethod.line,
          birthYear: 1995,
          guardianConsentGranted: false,
        );
        expect(normal.isPendingDeletion, isFalse);
      },
    );

    test(
      'เลยกำหนด 30 วันแล้วถือว่าลบถาวร — ล็อกอินได้บัญชีใหม่ กู้คืนไม่ได้',
      () async {
        var now = DateTime(2026, 1, 1, 12);
        final remote = MockAuthRemoteDataSource(
          latency: Duration.zero,
          nowProvider: () => now,
        );

        await remote.requestAccountDeletion(
          accessToken: 't',
          transferDecisions: const {},
        );

        // เลยเส้นตาย 30 วัน
        now = now.add(const Duration(days: 31));

        expect(await remote.restorePendingDeletion('t'), isNull);
        final session = await remote.signInWithProvider(
          method: AuthMethod.google,
          birthYear: 1995,
          guardianConsentGranted: false,
        );
        expect(session.isPendingDeletion, isFalse);
      },
    );

    test(
      'loadDeletionRequirements มีแมวที่มีผู้ดูแลร่วมต้องจัดการก่อนลบ',
      () async {
        final remote = MockAuthRemoteDataSource(latency: Duration.zero);
        final cats = await remote.loadDeletionRequirements('t');

        final mali = cats.firstWhere((c) => c.catName == 'มะลิ');
        expect(mali.mustResolve, isTrue);
        expect(mali.coCaretakers.length, 2);
        expect(cats.any((c) => !c.mustResolve), isTrue);
      },
    );

    test(
      'repository.requestAccountDeletion เคลียร์ session กลับเป็น guest',
      () async {
        final storage = InMemoryAuthTokenStorage()..saveSession(_authedSession);
        final repo = AuthRepositoryImpl(
          remoteDataSource: MockAuthRemoteDataSource(latency: Duration.zero),
          tokenStorage: storage,
        );

        await repo.requestAccountDeletion(
          transferDecisions: const {'cat-mali': 'cg-mom'},
        );

        final stored = await storage.readSession();
        expect(stored, isNotNull);
        expect(stored!.isGuest, isTrue);
      },
    );
  });

  group('AUTH-05 หน้าลบบัญชี', () {
    testWidgets('ผู้เยี่ยมชมเข้าหน้าลบบัญชีไม่ได้ เจอจอชวนล็อกอิน', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapDeletePage(
          storage: InMemoryAuthTokenStorage()
            ..saveSession(const AuthSession.guest()),
          remote: MockAuthRemoteDataSource(latency: Duration.zero),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ต้องเข้าสู่ระบบก่อน'), findsOneWidget);
      expect(find.text('เข้าสู่ระบบ'), findsOneWidget);
    });

    testWidgets(
      'flow ครบ: เตือน → เลือกโอนสิทธิ์/ลบแมว → ยืนยัน → สำเร็จ แล้วกลายเป็น guest',
      (tester) async {
        WidgetRef? capturedRef;
        final storage = InMemoryAuthTokenStorage()..saveSession(_authedSession);
        final remote = MockAuthRemoteDataSource(latency: Duration.zero);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authTokenStorageProvider.overrideWithValue(storage),
              authRemoteDataSourceProvider.overrideWithValue(remote),
            ],
            child: Consumer(
              builder: (context, ref, _) {
                capturedRef = ref;
                return MaterialApp.router(
                  routerConfig: GoRouter(
                    initialLocation: '/settings/delete-account',
                    routes: [
                      GoRoute(
                        path: '/settings/delete-account',
                        builder: (_, _) => const DeleteAccountPage(),
                      ),
                      GoRoute(
                        path: '/',
                        builder: (_, _) => const Scaffold(body: Text('Home')),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // ขั้น 1: เตือน — เห็นรายชื่อแมวและคำเตือน 30 วัน
        expect(find.text('การลบบัญชีเป็นการกระทำถาวร'), findsOneWidget);
        expect(find.text('มะลิ'), findsWidgets);
        await tester.scrollUntilVisible(
          find.text('ดำเนินการต่อ'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(find.text('ดำเนินการต่อ'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('ดำเนินการต่อ'));
        await tester.pumpAndSettle();

        // ขั้น 2: เลือกจัดการแมวที่มีผู้ดูแลร่วม — ปุ่มต่อยังกดไม่ได้จนเลือกครบ
        expect(find.text('จัดการแมวของคุณก่อนลบบัญชี'), findsOneWidget);
        await tester.tap(find.text('โอนสิทธิ์เจ้าของให้ แม่').first);
        await tester.pump();
        // ส้มจี๊ดเลือกลบไปพร้อมบัญชี
        await tester.tap(find.text('ลบโปรไฟล์ส้มจี๊ดไปพร้อมบัญชี'));
        await tester.pump();
        await tester.scrollUntilVisible(
          find.text('ดำเนินการต่อ'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(find.text('ดำเนินการต่อ'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('ดำเนินการต่อ'));
        await tester.pumpAndSettle();

        // ขั้น 3: ยืนยัน — scroll กลับขึ้นบนก่อนเพราะ PageStorage จำตำแหน่งจากขั้น 2
        await tester.scrollUntilVisible(
          find.text('ยืนยันการลบบัญชี'),
          -300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('ยืนยันการลบบัญชี'), findsOneWidget);
        await tester.tap(
          find.textContaining('ข้าพเจ้าเข้าใจว่าบัญชีจะถูกลบถาวร'),
        );
        await tester.pump();
        await tester.scrollUntilVisible(
          find.text('ลบบัญชีของฉัน'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(find.text('ลบบัญชีของฉัน'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('ลบบัญชีของฉัน'));
        await tester.pumpAndSettle();

        // ขั้น 4: สำเร็จ + session กลายเป็น guest
        expect(find.text('ส่งคำขอลบบัญชีแล้ว'), findsOneWidget);
        expect(capturedRef!.read(authControllerProvider).isGuest, isTrue);

        await tester.tap(find.text('กลับหน้าหลัก'));
        await tester.pumpAndSettle();
        expect(find.text('Home'), findsOneWidget);
      },
    );
  });

  group('AUTH-05 กู้คืนบัญชีค้างลบ', () {
    testWidgets(
      'ล็อกอินบัญชีที่ค้างลบเจอชีตเตือน กดกู้คืนแล้วเข้าแอปเป็นบัญชีปกติ',
      (tester) async {
        WidgetRef? capturedRef;
        final remote = MockAuthRemoteDataSource(latency: Duration.zero);
        await remote.requestAccountDeletion(
          accessToken: 't',
          transferDecisions: const {},
        );

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
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRemoteDataSourceProvider.overrideWithValue(remote),
              authTokenStorageProvider.overrideWithValue(
                InMemoryAuthTokenStorage()
                  ..saveSession(const AuthSession.guest()),
              ),
            ],
            child: Consumer(
              builder: (context, ref, _) {
                capturedRef = ref;
                return MaterialApp.router(routerConfig: router);
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // ล็อกอินด้วย PIN — mock คืน session ค้างลบ → เจอชีตแทนการเข้าแอป
        await tester.enterText(find.byType(TextField).first, '0812345678');
        await tester.enterText(find.byType(TextField).last, '123456');
        await tester.pump();
        await tester.tap(find.text('เข้าสู่ระบบด้วย PIN'));
        await tester.pumpAndSettle();

        expect(find.text('บัญชีนี้กำลังรอลบ'), findsOneWidget);
        expect(find.text('Home'), findsNothing);

        await tester.tap(find.text('กู้คืนบัญชี'));
        await tester.pumpAndSettle();

        expect(find.text('Home'), findsOneWidget);
        final auth = capturedRef!.read(authControllerProvider);
        expect(auth.isAuthenticated, isTrue);
        expect(auth.isPendingDeletion, isFalse);
      },
    );

    testWidgets('เลือกลบต่อจากชีต → ออกจากระบบกลับหน้าหลักเป็น guest', (
      tester,
    ) async {
      WidgetRef? capturedRef;
      final remote = MockAuthRemoteDataSource(latency: Duration.zero);
      await remote.requestAccountDeletion(
        accessToken: 't',
        transferDecisions: const {},
      );

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
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRemoteDataSourceProvider.overrideWithValue(remote),
            authTokenStorageProvider.overrideWithValue(
              InMemoryAuthTokenStorage()
                ..saveSession(const AuthSession.guest()),
            ),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              capturedRef = ref;
              return MaterialApp.router(routerConfig: router);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '0812345678');
      await tester.enterText(find.byType(TextField).last, '123456');
      await tester.pump();
      await tester.tap(find.text('เข้าสู่ระบบด้วย PIN'));
      await tester.pumpAndSettle();

      expect(find.text('บัญชีนี้กำลังรอลบ'), findsOneWidget);
      await tester.tap(find.text('ลบบัญชีถาวรต่อไป'));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(capturedRef!.read(authControllerProvider).isGuest, isTrue);
    });
  });
}

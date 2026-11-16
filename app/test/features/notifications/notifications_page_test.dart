import 'dart:async';

import 'package:catlive/core/config/app_locale.dart';
import 'package:catlive/core/error/failure.dart';
import 'package:catlive/features/notifications/data/datasources/mock_notifications_data_source.dart';
import 'package:catlive/features/notifications/domain/entities/app_notification.dart';
import 'package:catlive/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:catlive/features/notifications/presentation/pages/notification_post_detail_page.dart';
import 'package:catlive/features/notifications/presentation/pages/notifications_page.dart';
import 'package:catlive/features/notifications/presentation/pages/received_treats_page.dart';
import 'package:catlive/features/notifications/presentation/providers/notifications_providers.dart';
import 'package:catlive/features/notifications/presentation/widgets/notifications_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class _EmptyRepo implements NotificationsRepository {
  @override
  Future<List<AppNotification>> fetchNotifications() async => const [];

  @override
  Future<void> markAllAsRead() async {}

  @override
  Future<void> markAsRead(String id) async {}
}

class _DelayedRepo implements NotificationsRepository {
  final completer = Completer<List<AppNotification>>();

  @override
  Future<List<AppNotification>> fetchNotifications() => completer.future;

  @override
  Future<void> markAllAsRead() async {}

  @override
  Future<void> markAsRead(String id) async {}
}

class _SequenceRepo implements NotificationsRepository {
  int calls = 0;

  @override
  Future<List<AppNotification>> fetchNotifications() async {
    calls++;
    if (calls == 1) {
      throw const UnknownFailure('เชื่อมต่อไม่สำเร็จ');
    }
    final models = await const MockNotificationsDataSource()
        .fetchNotifications();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> markAllAsRead() async {}

  @override
  Future<void> markAsRead(String id) async {}
}

class _FailingMarkAllRepo implements NotificationsRepository {
  @override
  Future<List<AppNotification>> fetchNotifications() async {
    final models = await const MockNotificationsDataSource()
        .fetchNotifications();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> markAllAsRead() async =>
      throw const UnknownFailure('อัปเดตไม่สำเร็จ');

  @override
  Future<void> markAsRead(String id) async {}
}

class _FixedLocale extends AppLocaleNotifier {
  _FixedLocale(this._initial);
  final String _initial;

  @override
  String build() => _initial;
}

Widget _wrapNotifications({
  NotificationsRepository? repo,
  String initialLocale = 'th',
}) {
  final router = GoRouter(
    initialLocation: '/notifications',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Text('Home')),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, _) => const NotificationsPage(),
      ),
      GoRoute(
        path: '/notifications/post/:id',
        builder: (_, state) =>
            Scaffold(body: Text('Post ${state.pathParameters['id']}')),
      ),
      GoRoute(
        path: '/notifications/treats',
        builder: (_, _) => const Scaffold(body: Text('Received Treats')),
      ),
      GoRoute(
        path: '/notifications/help',
        builder: (_, _) => const Scaffold(body: Text('Help Alert')),
      ),
      GoRoute(
        path: '/notifications/health',
        builder: (_, _) => const Scaffold(body: Text('Health')),
      ),
      GoRoute(
        path: '/connections',
        builder: (_, _) => const Scaffold(body: Text('Connections')),
      ),
      GoRoute(
        path: '/cat-profile',
        builder: (_, _) => const Scaffold(body: Text('Profile')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      appLocaleProvider.overrideWith(() => _FixedLocale(initialLocale)),
      if (repo != null) notificationsRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('แสดง Skeleton ระหว่างโหลดข้อมูล', (tester) async {
    final repo = _DelayedRepo();
    await tester.pumpWidget(_wrapNotifications(repo: repo));
    await tester.pump();

    expect(find.byType(NotificationsSkeleton), findsOneWidget);

    repo.completer.complete(const []);
    await tester.pumpAndSettle();
    expect(find.text('ยังไม่มีการแจ้งเตือน'), findsOneWidget);
  });

  testWidgets('แสดงรายการ mock ครบ กรองยังไม่อ่าน และอ่านทั้งหมดแล้วได้', (
    tester,
  ) async {
    await tester.pumpWidget(_wrapNotifications());
    await tester.pumpAndSettle();

    expect(find.text('การแจ้งเตือน'), findsOneWidget);
    expect(find.text('ยังไม่อ่าน (3)'), findsOneWidget);
    expect(find.text('อ่านทั้งหมดแล้ว'), findsOneWidget);
    expect(
      find.textContaining('ส้มจี๊ดรายวัน (@somjeed.daily)'),
      findsOneWidget,
    );

    // กรองเฉพาะยังไม่อ่าน
    await tester.tap(find.text('ยังไม่อ่าน (3)'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('ส้มจี๊ดรายวัน (@somjeed.daily)'),
      findsOneWidget,
    );
    expect(find.textContaining('มุก อารีย์ (@muk.ari)'), findsNothing);

    // กดอ่านทั้งหมดแล้ว -> แสดง empty ของแท็บยังไม่อ่าน + ปุ่มดูทั้งหมด
    await tester.tap(find.text('อ่านทั้งหมดแล้ว'));
    await tester.pumpAndSettle();
    expect(find.text('อ่านครบทุกรายการแล้ว'), findsOneWidget);
    expect(find.text('ดูทั้งหมด'), findsOneWidget);

    await tester.tap(find.text('ดูทั้งหมด'));
    await tester.pumpAndSettle();
    expect(find.textContaining('มุก อารีย์ (@muk.ari)'), findsOneWidget);
  });

  testWidgets('แตะรายการแจ้งเตือนแล้วทำเครื่องหมายอ่านและนำทางไปหน้าปลายทาง', (
    tester,
  ) async {
    await tester.pumpWidget(_wrapNotifications());
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('ส้มจี๊ดรายวัน (@somjeed.daily)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Post p1'), findsOneWidget);
  });

  testWidgets('แสดง Empty state เมื่อไม่มีแจ้งเตือน', (tester) async {
    await tester.pumpWidget(_wrapNotifications(repo: _EmptyRepo()));
    await tester.pumpAndSettle();

    expect(find.text('ยังไม่มีการแจ้งเตือน'), findsOneWidget);
  });

  testWidgets('แสดง Error state และกดลองใหม่จนโหลดสำเร็จ', (tester) async {
    final repo = _SequenceRepo();
    await tester.pumpWidget(_wrapNotifications(repo: repo));
    await tester.pumpAndSettle();

    expect(find.text('โหลดการแจ้งเตือนไม่สำเร็จ'), findsOneWidget);
    expect(find.text('ลองใหม่'), findsOneWidget);

    await tester.tap(find.text('ลองใหม่'));
    await tester.pumpAndSettle();

    expect(find.text('ยังไม่อ่าน (3)'), findsOneWidget);
  });

  testWidgets('ย้อนกลับสถานะหากอ่านทั้งหมดแล้วล้มเหลว', (tester) async {
    await tester.pumpWidget(_wrapNotifications(repo: _FailingMarkAllRepo()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('อ่านทั้งหมดแล้ว'));
    await tester.pumpAndSettle();

    expect(find.text('ยังไม่อ่าน (3)'), findsOneWidget);
    expect(find.text('อัปเดตไม่สำเร็จ'), findsOneWidget);
  });

  testWidgets('รองรับภาษาอังกฤษเมื่อ appLocale เป็น en', (tester) async {
    await tester.pumpWidget(_wrapNotifications(initialLocale: 'en'));
    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Mark all read'), findsOneWidget);
    expect(find.text('Unread (3)'), findsOneWidget);
  });

  testWidgets('หน้ารายละเอียดโพสต์จากแจ้งเตือนแสดงคอมเมนต์และกดกลับได้', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/notifications',
      routes: [
        GoRoute(
          path: '/notifications',
          builder: (_, _) => const NotificationsPage(),
        ),
        GoRoute(
          path: '/notifications/post/:id',
          builder: (_, state) => NotificationPostDetailPage(
            postId: state.pathParameters['id']!,
            openComments: state.uri.queryParameters['comments'] == '1',
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appLocaleProvider.overrideWith(() => _FixedLocale('th'))],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('ส้มจี๊ดรายวัน (@somjeed.daily)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('โพสต์'), findsOneWidget);
    // เด้งชีตความคิดเห็นเหมือนหน้าฟีดขึ้นมาอัตโนมัติ
    expect(find.textContaining('แสดงความคิดเห็นถึง'), findsOneWidget);
    expect(find.byIcon(LucideIcons.x), findsOneWidget);

    await tester.tap(find.byIcon(LucideIcons.x));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('ย้อนกลับ'));
    await tester.pumpAndSettle();

    expect(find.text('การแจ้งเตือน'), findsOneWidget);
    expect(find.text('ยังไม่อ่าน (2)'), findsOneWidget);
  });

  testWidgets('หน้าขนมที่ได้รับแสดงผู้ส่ง โน้ต และประวัติขนมที่ได้รับ', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appLocaleProvider.overrideWith(() => _FixedLocale('th'))],
        child: const MaterialApp(home: ReceivedTreatsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ขนมที่ได้รับ'), findsOneWidget);
    expect(find.text('กาย · แมวสูงวัย (@guy.oldcat)'), findsOneWidget);
    expect(find.text('“ขอให้น้องมะลิแข็งแรงนะ”'), findsOneWidget);
    expect(find.text('ประวัติขนมที่ได้รับ'), findsOneWidget);
    expect(find.text('ส่งข้อความขอบคุณ'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:catlive/core/error/failure.dart';
import 'package:catlive/features/messages/domain/entities/messages_data.dart';
import 'package:catlive/features/messages/domain/repositories/messages_repository.dart';
import 'package:catlive/features/messages/presentation/pages/chat_room_page.dart';
import 'package:catlive/features/messages/presentation/pages/messages_page.dart';
import 'package:catlive/features/messages/presentation/providers/messages_controller.dart';

Widget _buildTestApp({MessagesRepository? overrideRepo}) {
  final router = GoRouter(
    initialLocation: '/messages',
    routes: [
      GoRoute(path: '/messages', builder: (_, _) => const MessagesPage()),
      GoRoute(
        path: '/messages/:id',
        builder: (_, state) =>
            ChatRoomPage(threadId: state.pathParameters['id']!),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      if (overrideRepo != null)
        messagesRepositoryProvider.overrideWithValue(overrideRepo),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

class _FailingMessagesRepo implements MessagesRepository {
  @override
  Future<MessagesInboxData> getInbox() async {
    throw const NetworkFailure('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้');
  }

  @override
  Future<void> blockThread(String threadId) async {}
  @override
  Future<void> deleteThread(String threadId) async {}
  @override
  Future<void> moveToBox(String threadId, MessagesBoxTab box) async {}
  @override
  Future<ChatThread> openOrCreateThread(ChatUser peer) =>
      throw UnimplementedError();
  @override
  Future<ChatThread> sendMessage({
    required String threadId,
    required String text,
    String? imagePath,
  }) => throw UnimplementedError();
  @override
  Future<void> setUnread(String threadId, {required bool unread}) async {}
  @override
  Future<void> toggleMute(String threadId) async {}
  @override
  Future<void> togglePin(String threadId) async {}
  @override
  Future<void> updateMyNote(String noteText) async {}
  @override
  Future<void> updateSettings(MessagesSettings settings) async {}
}

void main() {
  testWidgets('MessagesPage shows tabs, notes, and threads like web', (
    tester,
  ) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 350));

    expect(find.text('ข้อความ'), findsOneWidget);
    expect(find.text('หลัก'), findsOneWidget);
    expect(find.text('ทั่วไป'), findsOneWidget);
    expect(find.text('คำขอ (1)'), findsOneWidget);
    expect(find.text('โน้ตของคุณ'), findsOneWidget);
    expect(find.text('noon.mochi'), findsWidgets);
    expect(find.text('maew.vetnote'), findsWidgets);
    expect(find.text('rescue.bkk'), findsWidgets);
    expect(find.text('somjeed.daily'), findsWidgets);

    await tester.tap(find.text('ทั่วไป'));
    await tester.pumpAndSettle();
    expect(find.text('muk.ari'), findsOneWidget);

    await tester.tap(find.text('คำขอ (1)'));
    await tester.pumpAndSettle();
    expect(find.text('guy.oldcat'), findsOneWidget);
  });

  testWidgets('MessagesPage search filters threads', (tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 350));

    await tester.enterText(find.byType(TextField).first, 'rescue');
    await tester.pumpAndSettle();

    expect(find.text('rescue.bkk'), findsWidgets);
    expect(find.text('maew.vetnote · 2 ชม.'), findsNothing);
  });

  testWidgets('Opening thread and sending a new message updates chat room', (
    tester,
  ) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 350));

    await tester.tap(find.text('🤣🤣 · 38 นาที'));
    await tester.pumpAndSettle();

    expect(find.text('ใช้งานล่าสุด 38 นาทีที่แล้ว'), findsOneWidget);
    expect(find.text('รูปโมจิกอดตุ๊กตาน่ารักมาก'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'น่ารักจริง ๆ ค่ะ');
    await tester.tap(find.bySemanticsLabel('ส่ง'));
    await tester.pumpAndSettle(const Duration(milliseconds: 350));

    expect(find.text('น่ารักจริง ๆ ค่ะ'), findsOneWidget);
  });

  testWidgets('MessagesPage displays error state and retry button', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildTestApp(overrideRepo: _FailingMessagesRepo()),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    expect(find.text('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้'), findsOneWidget);
    expect(find.text('ลองใหม่'), findsOneWidget);
  });
}

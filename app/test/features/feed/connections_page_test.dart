import 'package:catlive/core/widgets/app_avatar.dart';
import 'package:catlive/features/feed/data/datasources/mock_feed_data_source.dart';
import 'package:catlive/features/feed/data/repositories/feed_repository_impl.dart';
import 'package:catlive/features/feed/domain/entities/feed_tab.dart';
import 'package:catlive/features/feed/presentation/pages/community_page.dart';
import 'package:catlive/features/feed/presentation/pages/connections_page.dart';
import 'package:catlive/features/feed/presentation/providers/feed_controller.dart';
import 'package:catlive/features/feed/presentation/providers/feed_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

Future<ProviderContainer> _prepareContainer(
  WidgetTester tester,
  FeedTab tab,
) async {
  final repo = FeedRepositoryImpl(MockFeedDataSource(latency: Duration.zero));
  final container = ProviderContainer(
    overrides: [feedRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);

  // ห่อด้วย runAsync เพราะ MockFeedDataSource ใช้ Future.delayed
  await tester.runAsync(() async {
    container.read(feedControllerProvider);
    await Future<void>.delayed(Duration.zero);
    await container.read(feedControllerProvider.notifier).selectTab(tab);
  });
  return container;
}

void main() {
  testWidgets(
    'หน้า Connections แสดง 3 แท็บ ค้นหา เรียง 3 โหมด และวงแหวนสตอรี่ตรงตามเว็บ',
    (tester) async {
      final container = await _prepareContainer(tester, FeedTab.following);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ConnectionsPage()),
        ),
      );
      await tester.pump();

      expect(find.text('12 ผู้ติดตาม'), findsOneWidget);
      expect(find.text('3 กำลังติดตาม'), findsOneWidget);
      expect(find.text('แนะนำ'), findsOneWidget);
      expect(find.text('เรียงลำดับตาม '), findsOneWidget);
      expect(find.text('ค่าเริ่มต้น'), findsOneWidget);

      // กดปุ่มเรียงลำดับ 3 โหมด: ค่าเริ่มต้น -> ล่าสุด -> ชื่อ ก–ฮ / A–Z
      final sortButton = find.byIcon(LucideIcons.arrowDownUp);
      await tester.tap(sortButton);
      await tester.pump();
      expect(find.text('ล่าสุด'), findsOneWidget);

      await tester.tap(sortButton);
      await tester.pump();
      expect(find.text('ชื่อ ก–ฮ / A–Z'), findsOneWidget);

      await tester.tap(sortButton);
      await tester.pump();
      expect(find.text('ค่าเริ่มต้น'), findsOneWidget);

      // ค้นหาเจอ และไม่เจอแสดงข้อความตรงเว็บ
      await tester.enterText(find.byType(TextField), 'vet');
      await tester.pump();
      expect(find.text('maew.vetnote'), findsOneWidget);
      expect(find.text('noon.mochi'), findsNothing);

      await tester.enterText(find.byType(TextField), 'zzzz');
      await tester.pump();
      expect(find.text('ไม่พบบัญชีที่ค้นหา'), findsOneWidget);

      // ล้างคำค้นแล้วกดเลิกติดตาม
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();
      await tester.tap(find.text('กำลังติดตาม').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('2 กำลังติดตาม'), findsOneWidget);

      // สลับไปแท็บผู้ติดตาม: มีปุ่ม ส่งข้อความ / ติดตามกลับ / ลบ (×) และวงแหวนสตอรี่เฉพาะคนมีสตอรี่
      await tester.tap(find.text('12 ผู้ติดตาม'));
      await tester.pump();
      expect(find.text('ส่งข้อความ'), findsWidgets);
      expect(find.text('ติดตามกลับ'), findsWidgets);

      final storyAvatars = tester
          .widgetList<StoryAvatar>(find.byType(StoryAvatar))
          .toList();
      expect(
        storyAvatars.where((a) => a.hasUnseenStory).length,
        greaterThan(0),
      );
      expect(
        storyAvatars.where((a) => !a.hasUnseenStory).length,
        greaterThan(0),
      );

      // กดติดตามกลับแล้วตัวเลขกำลังติดตามเพิ่ม
      await tester.tap(find.text('ติดตามกลับ').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('3 กำลังติดตาม'), findsOneWidget);

      // กดปุ่ม × ลบผู้ติดตามคนแรกออกทันที
      await tester.tap(find.byIcon(LucideIcons.x).first);
      await tester.pump();
      expect(find.text('11 ผู้ติดตาม'), findsOneWidget);

      // สลับไปแท็บแนะนำ กดติดตามครบแล้วแสดงข้อความตามเว็บ
      await tester.tap(find.text('แนะนำ'));
      await tester.pump();
      expect(find.text('guy.oldcat'), findsOneWidget);
      expect(find.text('somjeed.daily'), findsOneWidget);

      await tester.tap(find.text('ติดตาม').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('ติดตาม').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('ติดตามครบทุกบัญชีแล้ว'), findsOneWidget);
    },
  );

  testWidgets(
    'แท็บบันทึกไว้แสดงไอคอนหลายรูปไม่มีกรอบพื้นหลังบนโพสต์ที่มีมากกว่า 1 รูป',
    (tester) async {
      final container = await _prepareContainer(tester, FeedTab.saved);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: CommunityPage())),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // โพสต์ที่บันทึกไว้เริ่มต้น (p2 มี 3 รูป, p4 มี 2 รูป) ต้องมีไอคอนหลายรูปขนาด 16 และไม่มีกรอบพื้นหลัง
      final copyIcons = find.byIcon(LucideIcons.copy);
      expect(copyIcons, findsNWidgets(2));
      final firstIcon = tester.widget<Icon>(copyIcons.first);
      expect(firstIcon.size, 16);
      expect(firstIcon.color, Colors.white);
    },
  );
}

import 'package:catlive/features/auth/domain/entities/auth_data.dart';
import 'package:catlive/features/auth/presentation/providers/auth_controller.dart';
import 'package:catlive/features/feed/data/datasources/mock_feed_data_source.dart';
import 'package:catlive/features/feed/data/repositories/feed_repository_impl.dart';
import 'package:catlive/features/feed/domain/entities/feed_user.dart';
import 'package:catlive/features/feed/domain/entities/post.dart';
import 'package:catlive/features/feed/presentation/pages/post_link_page.dart';
import 'package:catlive/features/feed/presentation/providers/feed_providers.dart';
import 'package:catlive/features/feed/presentation/widgets/share_sheet.dart';
import 'package:catlive/features/menu/presentation/pages/menu_page.dart';
import 'package:catlive/features/messages/presentation/pages/messages_page.dart';
import 'package:catlive/features/notifications/presentation/pages/notifications_page.dart';
import 'package:catlive/features/treats/presentation/pages/treats_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Controller ปลอมที่บังคับสถานะเป็นผู้เยี่ยมชมตั้งแต่เปิดหน้า (เลี่ยงการรอ restore)
class _GuestAuth extends AuthController {
  @override
  AuthState build() => const AuthState(session: AuthSession.guest());
}

Widget _wrap(String location, List<GoRoute> routes) {
  final router = GoRouter(
    initialLocation: location,
    routes: [
      ...routes,
      GoRoute(path: '/login', builder: (_, _) => const Scaffold()),
    ],
  );
  return ProviderScope(
    overrides: [authControllerProvider.overrideWith(_GuestAuth.new)],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('Guest กด "เลี้ยงอาหารน้อง ๆ" ในเมนูแล้วเจอชีตชวนเข้าสู่ระบบ', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap('/menu', [
        GoRoute(path: '/menu', builder: (_, _) => const MenuPage()),
      ]),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('เลี้ยงอาหารน้อง ๆ'));
    await tester.pumpAndSettle();

    expect(find.textContaining('เข้าสู่ระบบเพื่อใช้งาน'), findsOneWidget);
    expect(find.text('เข้าสู่ระบบ / สมัครสมาชิก'), findsOneWidget);
    expect(find.text('ดูต่อแบบผู้เยี่ยมชม'), findsOneWidget);
  });

  testWidgets('Guest กด "เลี้ยงขนม" บนหน้าลิงก์โพสต์แล้วเจอชีตชวนเข้าสู่ระบบ', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_GuestAuth.new),
          feedRepositoryProvider.overrideWithValue(
            FeedRepositoryImpl(MockFeedDataSource(latency: Duration.zero)),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/p/p1',
            routes: [
              GoRoute(
                path: '/p/:id',
                builder: (_, state) =>
                    PostLinkPage(postId: state.pathParameters['id']!),
              ),
              GoRoute(
                path: '/login',
                builder: (_, _) => const Scaffold(),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.textContaining('เลี้ยงขนม'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.textContaining('เลี้ยงขนม'));
    await tester.pumpAndSettle();

    expect(find.textContaining('เข้าสู่ระบบเพื่อใช้งาน'), findsOneWidget);
    expect(find.text('เข้าสู่ระบบ / สมัครสมาชิก'), findsOneWidget);
  });

  testWidgets(
    'Guest เลือกเพื่อนในชีตแชร์แล้วเจอชีตชวนเข้าสู่ระบบ (แชร์นอกแอปยังใช้ได้)',
    (tester) async {
      const post = Post(
        id: 'p-share',
        type: PostType.normal,
        categoryLabel: 'ชีวิตแมว',
        author: FeedUser(
          id: 'noon',
          handle: 'noon.mochi',
          avatar: 'asset:assets/images/avatars/1592194996308-7b43878e84a6.jpg',
          avatarBg: 0xFFFCE7D6,
          hasUnseenStory: false,
        ),
        caption: 'ทดสอบแชร์',
        media: [
          PostMedia(url: 'asset:x.jpg', alt: 'แมวส้ม'),
        ],
        likeCount: 1,
        commentCount: 0,
        shareCount: 0,
        likedBy: LikedBy(handle: 'tonkla_meow', avatars: []),
        previewComments: [],
        postedAgoText: '1 ชม.ที่แล้ว',
        isFollowingAuthor: false,
        isLiked: false,
        isSaved: false,
        isOwn: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(_GuestAuth.new),
            feedRepositoryProvider.overrideWithValue(
              FeedRepositoryImpl(MockFeedDataSource(latency: Duration.zero)),
            ),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => showShareSheet(context, post),
                  child: const Text('share'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('share'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('guy.oldcat').first);
      await tester.pumpAndSettle();

      expect(find.textContaining('เข้าสู่ระบบเพื่อใช้งาน'), findsOneWidget);
      expect(find.text('เข้าสู่ระบบ / สมัครสมาชิก'), findsOneWidget);
      // ช่องแชร์ออกนอกแอปยังแสดงอยู่ใต้ชีตล็อกอิน
      expect(find.text('คัดลอกลิงก์'), findsWidgets);
    },
  );

  testWidgets('สมาชิกส่งให้เพื่อนในแอปแล้วชีตปิดอัตโนมัติหลังแจ้งผล', (
    tester,
  ) async {
    const post = Post(
      id: 'p-share',
      type: PostType.normal,
      categoryLabel: 'ชีวิตแมว',
      author: FeedUser(
        id: 'noon',
        handle: 'noon.mochi',
        avatar: 'asset:assets/images/avatars/1592194996308-7b43878e84a6.jpg',
        avatarBg: 0xFFFCE7D6,
        hasUnseenStory: false,
      ),
      caption: 'ทดสอบแชร์',
      media: [
        PostMedia(url: 'asset:x.jpg', alt: 'แมวส้ม'),
      ],
      likeCount: 1,
      commentCount: 0,
      shareCount: 0,
      likedBy: LikedBy(handle: 'tonkla_meow', avatars: []),
      previewComments: [],
      postedAgoText: '1 ชม.ที่แล้ว',
      isFollowingAuthor: false,
      isLiked: false,
      isSaved: false,
      isOwn: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          feedRepositoryProvider.overrideWithValue(
            FeedRepositoryImpl(MockFeedDataSource(latency: Duration.zero)),
          ),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showShareSheet(context, post),
                child: const Text('share'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('share'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('guy.oldcat').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('ส่ง'));
    await tester.pump();

    // toast แจ้งผลขึ้นก่อน แล้วชีตค่อยปิดเองหลัง ~1.3 วินาที
    expect(find.text('ส่งให้ 1 คนแล้ว'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
    expect(find.text('แชร์'), findsNothing);
  });

  testWidgets('Guest เปิด /treats ตรง ๆ เห็นการ์ดชวนเข้าสู่ระบบแทนเนื้อหาหน้า', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap('/treats', [
        GoRoute(path: '/treats', builder: (_, _) => const TreatsPage()),
      ]),
    );
    // เผื่อเวลาให้ mock repo ที่โหลดพื้นหลังทำงานจบ กัน timer ค้างตอนจบเทส
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('เข้าสู่ระบบเพื่อเลี้ยงขนม'), findsOneWidget);
    expect(find.text('เข้าสู่ระบบ / สมัครสมาชิก'), findsOneWidget);
    expect(find.text('ส่งให้แมวตัวไหน'), findsNothing);
  });

  testWidgets('Guest เปิด /messages ตรง ๆ เห็นการ์ดชวนเข้าสู่ระบบแทนเนื้อหาหน้า', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap('/messages', [
        GoRoute(path: '/messages', builder: (_, _) => const MessagesPage()),
      ]),
    );
    // เผื่อเวลาให้ mock repo ที่โหลดพื้นหลังทำงานจบ กัน timer ค้างตอนจบเทส
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('เข้าสู่ระบบเพื่อใช้ข้อความแชท'), findsOneWidget);
    expect(find.text('เข้าสู่ระบบ / สมัครสมาชิก'), findsOneWidget);
    expect(find.text('ยังไม่มีข้อความ'), findsNothing);
  });

  testWidgets(
    'Guest เปิด /notifications ตรง ๆ เห็นการ์ดชวนเข้าสู่ระบบแทนเนื้อหาหน้า',
    (tester) async {
      await tester.pumpWidget(
        _wrap('/notifications', [
          GoRoute(
            path: '/notifications',
            builder: (_, _) => const NotificationsPage(),
          ),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text('เข้าสู่ระบบเพื่อดูการแจ้งเตือน'), findsOneWidget);
      expect(find.text('เข้าสู่ระบบ / สมัครสมาชิก'), findsOneWidget);
      expect(find.text('ทั้งหมด'), findsNothing);
    },
  );
}

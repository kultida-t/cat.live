import 'dart:async';

import 'package:catlive/core/error/failure.dart';
import 'package:catlive/core/theme/app_theme.dart';
import 'package:catlive/features/feed/data/datasources/mock_feed_data_source.dart';
import 'package:catlive/features/feed/data/repositories/feed_repository_impl.dart';
import 'package:catlive/features/feed/domain/entities/comment.dart';
import 'package:catlive/features/feed/domain/entities/feed_tab.dart';
import 'package:catlive/features/feed/domain/entities/feed_user.dart';
import 'package:catlive/features/feed/domain/entities/new_post.dart';
import 'package:catlive/features/feed/domain/entities/post.dart';
import 'package:catlive/features/feed/domain/repositories/feed_repository.dart';
import 'package:catlive/features/feed/presentation/providers/feed_providers.dart';
import 'package:catlive/features/home/presentation/pages/home_page.dart';
import 'package:catlive/features/home/presentation/providers/home_controller.dart';
import 'package:catlive/features/home/presentation/widgets/home_post_preview_card.dart';
import 'package:catlive/features/home/presentation/widgets/home_updates_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class _ControlledFeedRepository implements FeedRepository {
  _ControlledFeedRepository(this._inner);

  final FeedRepository _inner;
  Completer<FeedPage>? pendingGetPosts;
  bool shouldFail = false;

  @override
  Future<FeedPage> getPosts({
    required FeedTab tab,
    int cursor = 0,
    int limit = 5,
  }) async {
    if (pendingGetPosts != null) {
      return pendingGetPosts!.future;
    }
    if (shouldFail) {
      throw const NetworkFailure('เชื่อมต่อไม่สำเร็จ');
    }
    return _inner.getPosts(tab: tab, cursor: cursor, limit: limit);
  }

  @override
  Future<List<FeedUser>> getStoryUsers() => _inner.getStoryUsers();

  @override
  Future<List<FeedUser>> getAccounts() => _inner.getAccounts();

  @override
  Future<Post> getPost(String postId) => _inner.getPost(postId);

  @override
  Future<Post> createPost(NewPost input) => _inner.createPost(input);

  @override
  Future<Post> toggleLike(String postId) => _inner.toggleLike(postId);

  @override
  Future<Post> toggleSave(String postId) => _inner.toggleSave(postId);

  @override
  Future<void> toggleFollow(String userId) => _inner.toggleFollow(userId);

  @override
  Future<void> hidePost(String postId) => _inner.hidePost(postId);

  @override
  Future<void> hideAccountPosts(String userId) =>
      _inner.hideAccountPosts(userId);

  @override
  Future<List<Comment>> getComments(String postId) =>
      _inner.getComments(postId);

  @override
  Future<Comment> addComment(
    String postId,
    String text, {
    String? replyToHandle,
  }) => _inner.addComment(postId, text, replyToHandle: replyToHandle);

  @override
  Future<Comment> toggleCommentLike(String postId, String commentId) =>
      _inner.toggleCommentLike(postId, commentId);

  @override
  Future<void> reportPost(String postId, String reason) =>
      _inner.reportPost(postId, reason);

  @override
  Future<void> deletePost(String postId) => _inner.deletePost(postId);
}

class _EmptyFeedRepository extends _ControlledFeedRepository {
  _EmptyFeedRepository(super.inner);

  @override
  Future<FeedPage> getPosts({
    required FeedTab tab,
    int cursor = 0,
    int limit = 5,
  }) async => const FeedPage(posts: [], nextCursor: null);
}

void _useMobileViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

GoRouter _testRouter({Widget? home}) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => home ?? const HomePage()),
      GoRoute(
        path: '/community',
        builder: (_, _) => const Scaffold(body: Text('ROUTE:/community')),
      ),
      GoRoute(
        path: '/cat-ai',
        builder: (_, _) => const Scaffold(body: Text('ROUTE:/cat-ai')),
      ),
      GoRoute(
        path: '/help',
        builder: (_, _) => const Scaffold(body: Text('ROUTE:/help')),
      ),
    ],
  );
}

void main() {
  testWidgets(
    'หน้าแรกแสดงหัวหน้าจอ แบนเนอร์ การ์ดทางลัด 3 ใบ และอัปเดตชุมชน 5 โพสต์',
    (tester) async {
      _useMobileViewport(tester);
      final repo = FeedRepositoryImpl(
        MockFeedDataSource(latency: Duration.zero),
      );
      final container = ProviderContainer(
        overrides: [feedRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await tester.runAsync(() async {
        container.read(homeControllerProvider);
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: _testRouter(),
          ),
        ),
      );
      await tester.pump();

      // หัวหน้าแรก 5 ส่วน
      expect(find.bySemanticsLabel('เปิดเมนู'), findsOneWidget);
      expect(find.bySemanticsLabel('ค้นหา'), findsOneWidget);
      expect(find.bySemanticsLabel('แมว.live'), findsOneWidget);
      expect(
        find.bySemanticsLabel('การแจ้งเตือน 3 รายการใหม่'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('ข้อความ 3 รายการยังไม่อ่าน'),
        findsOneWidget,
      );

      // แบนเนอร์ต้อนรับ
      expect(find.textContaining('สวัสดี'), findsOneWidget);
      expect(find.textContaining('เพราะทุกแมว'), findsOneWidget);

      // การ์ดทางลัด 3 ใบ
      expect(find.text('ฟีดแมว'), findsOneWidget);
      expect(find.text('ถาม Cat AI'), findsOneWidget);
      expect(find.text('ขอความ\nช่วยเหลือ'), findsOneWidget);

      // ส่วนอัปเดตจากชุมชน: หัวข้อ + ดูทั้งหมด > + 5 โพสต์แบบย่อ (ไม่มีปุ่มติดตาม)
      expect(find.text('อัปเดตจากชุมชน'), findsOneWidget);
      expect(find.text('ดูทั้งหมด'), findsOneWidget);
      expect(find.byIcon(LucideIcons.chevronRight), findsOneWidget);
      expect(find.byType(HomePostPreviewCard), findsWidgets);
      final posts = container.read(homeControllerProvider).posts;
      expect(posts.length, 5);
      for (final post in posts) {
        final comments = await tester.runAsync(() => repo.getComments(post.id));
        expect(post.commentCount, comments!.length);
      }
      expect(find.text('ติดตาม'), findsNothing);
      expect(find.text('ติดตามแล้ว'), findsNothing);
    },
  );

  testWidgets(
    'แบนเนอร์วนรูปถัดไปได้ และเลือกรูปน้องแมวของฉันแล้วปิดสวิตช์อัตโนมัติ',
    (tester) async {
      _useMobileViewport(tester);
      final repo = FeedRepositoryImpl(
        MockFeedDataSource(latency: Duration.zero),
      );
      final container = ProviderContainer(
        overrides: [feedRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await tester.runAsync(() async {
        container.read(homeControllerProvider);
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: _testRouter(),
          ),
        ),
      );
      await tester.pump();

      expect(
        container.read(homeControllerProvider).activeHeroPhoto.id,
        'preset-group',
      );

      // กดรูปแมวฝั่งขวาเพื่อดูรูปถัดไป
      await tester.tap(find.bySemanticsLabel('ดูรูปแมวถัดไป'));
      await tester.pump(const Duration(milliseconds: 700));
      expect(
        container.read(homeControllerProvider).activeHeroPhoto.id,
        'preset-kitten',
      );

      // กดปุ่มเปิดชีตเลือกรูปหน้าแรก
      await tester.tap(find.bySemanticsLabel('เปลี่ยนรูปหน้าแรก'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('รูปหน้าแรก'), findsOneWidget);
      expect(find.text('น้องแมวของฉัน'), findsOneWidget);
      expect(find.text('มะลิ'), findsOneWidget);
      expect(find.text('ส้มจี๊ด'), findsOneWidget);
      expect(find.text('ถั่วดำ'), findsOneWidget);
      expect(find.text('อัปโหลด'), findsOneWidget);
      expect(find.text('รูปจากแมว.live'), findsOneWidget);
      expect(find.text('สลับรูปอัตโนมัติ'), findsOneWidget);
      expect(container.read(homeControllerProvider).autoRotate, isTrue);

      // กดเลือก "มะลิ" → ปิดชีต + ปิดสวิตช์อัตโนมัติ + ล็อกรูปมะลิ
      await tester.tap(find.text('มะลิ'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('รูปหน้าแรก'), findsNothing);
      final after = container.read(homeControllerProvider);
      expect(after.activeHeroPhoto.id, 'cat-mali');
      expect(after.autoRotate, isFalse);
      expect(after.isCustomSelected, isTrue);
    },
  );

  testWidgets('การ์ดทางลัดและลิงก์ดูทั้งหมดนำทางไปยังแท็บเป้าหมายถูกต้อง', (
    tester,
  ) async {
    _useMobileViewport(tester);
    final repo = FeedRepositoryImpl(MockFeedDataSource(latency: Duration.zero));

    Future<void> verifyRoute(String tapText, String expectedRoute) async {
      final container = ProviderContainer(
        overrides: [feedRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await tester.runAsync(() async {
        container.read(homeControllerProvider);
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: _testRouter(),
          ),
        ),
      );
      await tester.pump();
      await tester.ensureVisible(find.text(tapText));
      await tester.tap(find.text(tapText));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('ROUTE:$expectedRoute'), findsOneWidget);
    }

    await verifyRoute('ฟีดแมว', '/community');
    await verifyRoute('ถาม Cat AI', '/cat-ai');
    await verifyRoute('ขอความ\nช่วยเหลือ', '/help');
    await verifyRoute('ดูทั้งหมด', '/community');
  });

  testWidgets(
    'ครบ 4 สถานะ: Loading, Error + ลองใหม่, Empty และกดถูกใจ/บันทึก',
    (tester) async {
      _useMobileViewport(tester);
      final baseRepo = FeedRepositoryImpl(
        MockFeedDataSource(latency: Duration.zero),
      );
      final controlledRepo = _ControlledFeedRepository(baseRepo)
        ..pendingGetPosts = Completer<FeedPage>();

      final container = ProviderContainer(
        overrides: [feedRepositoryProvider.overrideWithValue(controlledRepo)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: _testRouter(),
          ),
        ),
      );
      await tester.pump();

      // 1) Loading skeleton ตอนเริ่มต้น
      expect(find.byType(HomeUpdatesSkeleton), findsOneWidget);

      // 2) โหลดพลาด → แสดง ErrorView + ปุ่มลองใหม่
      controlledRepo.pendingGetPosts!.completeError(
        const NetworkFailure('เชื่อมต่อไม่สำเร็จ'),
      );
      controlledRepo.pendingGetPosts = null;
      controlledRepo.shouldFail = true;
      await tester.pump();
      await tester.pump();
      expect(find.text('เชื่อมต่อไม่สำเร็จ'), findsOneWidget);
      expect(find.text('ลองใหม่'), findsOneWidget);

      // 3) กดลองใหม่เมื่อระบบกลับมา → โหลด 5 โพสต์สำเร็จ
      controlledRepo.shouldFail = false;
      await tester.ensureVisible(find.text('ลองใหม่'));
      await tester.tap(find.text('ลองใหม่'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();
      expect(find.byType(HomePostPreviewCard), findsWidgets);

      // กดถูกใจโพสต์แรก (p1 เดิมถูกใจอยู่ 128 → เลิกถูกใจเหลือ 127)
      final beforeLikes = container
          .read(homeControllerProvider)
          .posts
          .first
          .likeCount;
      await tester.ensureVisible(find.bySemanticsLabel('เลิกถูกใจ').first);
      await tester.tap(find.bySemanticsLabel('เลิกถูกใจ').first);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();
      expect(
        container.read(homeControllerProvider).posts.first.likeCount,
        beforeLikes - 1,
      );

      // 4) กรณีไม่มีอัปเดต → แสดงข้อความว่าง
      final emptyContainer = ProviderContainer(
        overrides: [
          feedRepositoryProvider.overrideWithValue(
            _EmptyFeedRepository(baseRepo),
          ),
        ],
      );
      addTearDown(emptyContainer.dispose);
      await tester.runAsync(() async {
        emptyContainer.read(homeControllerProvider);
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: emptyContainer,
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: _testRouter(),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('ยังไม่มีอัปเดตจากชุมชน'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      container.dispose();
      emptyContainer.dispose();
    },
  );

  testWidgets('ส่งคอมเมนต์จากการ์ดหน้าแรกแล้วจำนวนคอมเมนต์เพิ่มขึ้นทันที', (
    tester,
  ) async {
    _useMobileViewport(tester);
    final repo = FeedRepositoryImpl(MockFeedDataSource(latency: Duration.zero));
    final container = ProviderContainer(
      overrides: [feedRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await tester.runAsync(() async {
      container.read(homeControllerProvider);
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: _testRouter(),
        ),
      ),
    );
    await tester.pump();

    final firstPost = container.read(homeControllerProvider).posts.first;
    final initialCount = firstPost.commentCount;

    await tester.ensureVisible(
      find.bySemanticsLabel('ความคิดเห็น $initialCount รายการ'),
    );
    await tester.tap(find.bySemanticsLabel('ความคิดเห็น $initialCount รายการ'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    await tester.tap(find.bySemanticsLabel('ส่ง ❤️'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump();

    expect(
      container.read(homeControllerProvider).posts.first.commentCount,
      initialCount + 1,
    );
    expect(find.text('${initialCount + 1}'), findsWidgets);

    await tester.pumpWidget(const SizedBox());
    container.dispose();
  });
}

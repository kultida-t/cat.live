import 'package:catlive/core/error/failure.dart';
import 'package:catlive/features/feed/data/datasources/mock_feed_data_source.dart';
import 'package:catlive/features/feed/data/repositories/feed_repository_impl.dart';
import 'package:catlive/features/feed/domain/entities/comment.dart';
import 'package:catlive/features/feed/domain/entities/feed_tab.dart';
import 'package:catlive/features/feed/domain/entities/feed_user.dart';
import 'package:catlive/features/feed/domain/entities/new_post.dart';
import 'package:catlive/features/feed/domain/entities/post.dart';
import 'package:catlive/features/feed/domain/repositories/feed_repository.dart';
import 'package:catlive/features/feed/presentation/providers/feed_controller.dart';
import 'package:catlive/features/feed/presentation/providers/feed_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// repository ที่ใช้ mock จริง แต่สั่งให้ล้มเหลวเฉพาะคำขอกดไลก์/เซฟ/ติดตามได้
class _FlakyRepository implements FeedRepository {
  _FlakyRepository(this._inner);

  final FeedRepository _inner;
  bool failWrites = false;

  @override
  Future<FeedPage> getPosts({
    required FeedTab tab,
    int cursor = 0,
    int limit = 5,
  }) => _inner.getPosts(tab: tab, cursor: cursor, limit: limit);

  @override
  Future<List<FeedUser>> getStoryUsers() => _inner.getStoryUsers();

  @override
  Future<List<FeedUser>> getAccounts() => _inner.getAccounts();

  Future<T> _write<T>(Future<T> Function() action) async {
    if (failWrites) throw const NetworkFailure();
    return action();
  }

  @override
  Future<Post> toggleLike(String postId) =>
      _write(() => _inner.toggleLike(postId));

  @override
  Future<Post> toggleSave(String postId) =>
      _write(() => _inner.toggleSave(postId));

  @override
  Future<void> toggleFollow(String userId) =>
      _write(() => _inner.toggleFollow(userId));

  @override
  Future<void> hidePost(String postId) => _write(() => _inner.hidePost(postId));

  @override
  Future<void> hideAccountPosts(String userId) =>
      _write(() => _inner.hideAccountPosts(userId));

  @override
  Future<void> reportPost(String postId, String reason) =>
      _write(() => _inner.reportPost(postId, reason));

  @override
  Future<void> deletePost(String postId) =>
      _write(() => _inner.deletePost(postId));

  @override
  Future<Post> getPost(String postId) => _inner.getPost(postId);

  @override
  Future<Post> createPost(NewPost draft) =>
      _write(() => _inner.createPost(draft));

  @override
  Future<List<Comment>> getComments(String postId) =>
      _inner.getComments(postId);

  @override
  Future<Comment> addComment(
    String postId,
    String text, {
    String? replyToHandle,
  }) => _write(
    () => _inner.addComment(postId, text, replyToHandle: replyToHandle),
  );

  @override
  Future<Comment> toggleCommentLike(String postId, String commentId) =>
      _write(() => _inner.toggleCommentLike(postId, commentId));
}

ProviderContainer _container(_FlakyRepository repo) {
  final c = ProviderContainer(
    overrides: [feedRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(c.dispose);
  return c;
}

_FlakyRepository _newRepo() => _FlakyRepository(
  FeedRepositoryImpl(MockFeedDataSource(latency: Duration.zero)),
);

Future<FeedState> _loaded(ProviderContainer c) async {
  c.read(feedControllerProvider);
  await pumpEventQueue();
  return c.read(feedControllerProvider);
}

void main() {
  test('เปิดฟีด — โหลดโพสต์ทั้ง 5 ใบ ตามลำดับเดียวกับเว็บ', () async {
    final state = await _loaded(_container(_newRepo()));

    expect(state.status, FeedStatus.ready);
    expect(state.posts.map((p) => p.author.handle), [
      'noon.mochi',
      'maew.vetnote',
      'guy.oldcat',
      'muk.ari',
      'rescue.bkk',
    ]);
    expect(state.nextCursor, isNull);
  });

  test('แท็บติดตาม — เห็นเฉพาะบัญชีที่ติดตามอยู่ 3 โพสต์', () async {
    final c = _container(_newRepo());
    await _loaded(c);
    await c.read(feedControllerProvider.notifier).selectTab(FeedTab.following);

    final posts = c.read(feedControllerProvider).posts;
    expect(posts.map((p) => p.author.handle), [
      'noon.mochi',
      'maew.vetnote',
      'rescue.bkk',
    ]);
  });

  test(
    'แท็บติดตาม — มีทะเบียนบัญชี: ติดตามอยู่ 3 + แนะนำสูงสุด 4 ตามลำดับเว็บ',
    () async {
      final c = _container(_newRepo());
      await _loaded(c);
      await c
          .read(feedControllerProvider.notifier)
          .selectTab(FeedTab.following);

      final state = c.read(feedControllerProvider);
      expect(state.followedAccounts.map((a) => a.handle), [
        'noon.mochi',
        'maew.vetnote',
        'rescue.bkk',
      ]);
      expect(state.suggestedAccounts.map((a) => a.handle), [
        'guy.oldcat',
        'muk.ari',
        'somjeed.daily',
        'pim.kittenhouse',
      ]);
    },
  );

  test(
    'ติดตามจากแนะนำ — ย้ายบัญชีไปฝั่งติดตามแล้ว อัปเดตโพสต์ของบัญชีด้วย',
    () async {
      final c = _container(_newRepo());
      await _loaded(c);
      final notifier = c.read(feedControllerProvider.notifier);
      await notifier.selectTab(FeedTab.following);

      final guy = c
          .read(feedControllerProvider)
          .suggestedAccounts
          .firstWhere((a) => a.handle == 'guy.oldcat');
      expect(await notifier.toggleFollowUser(guy), isNull);

      final state = c.read(feedControllerProvider);
      expect(
        state.followedAccounts.any((a) => a.handle == 'guy.oldcat'),
        isTrue,
      );
      expect(
        state.suggestedAccounts.any((a) => a.handle == 'guy.oldcat'),
        isFalse,
      );
    },
  );

  test(
    'ติดตามจากแนะนำแล้วเน็ตหลุด — บัญชีกลับไปอยู่ฝั่งแนะนำเหมือนเดิม',
    () async {
      final repo = _newRepo();
      final c = _container(repo);
      await _loaded(c);
      final notifier = c.read(feedControllerProvider.notifier);
      await notifier.selectTab(FeedTab.following);

      final guy = c
          .read(feedControllerProvider)
          .suggestedAccounts
          .firstWhere((a) => a.handle == 'guy.oldcat');
      repo.failWrites = true;
      expect(await notifier.toggleFollowUser(guy), isA<NetworkFailure>());

      final state = c.read(feedControllerProvider);
      expect(
        state.suggestedAccounts.any((a) => a.handle == 'guy.oldcat'),
        isTrue,
      );
      expect(
        state.followedAccounts.any((a) => a.handle == 'guy.oldcat'),
        isFalse,
      );
    },
  );

  test('แท็บบันทึกไว้ — เห็นโพสต์ที่เซฟไว้ 2 โพสต์', () async {
    final c = _container(_newRepo());
    await _loaded(c);
    await c.read(feedControllerProvider.notifier).selectTab(FeedTab.saved);

    expect(c.read(feedControllerProvider).posts.map((p) => p.id), ['p2', 'p4']);
  });

  test(
    'กดไลก์ — เปลี่ยนทันทีก่อนเซิร์ฟเวอร์ตอบ (optimistic) และไลก์ซ้ำคืนค่าเดิม',
    () async {
      final c = _container(_newRepo());
      await _loaded(c);
      final notifier = c.read(feedControllerProvider.notifier);
      final p2 = c
          .read(feedControllerProvider)
          .posts
          .firstWhere((p) => p.id == 'p2');

      final pending = notifier.toggleLike(p2);
      final during = c
          .read(feedControllerProvider)
          .posts
          .firstWhere((p) => p.id == 'p2');
      expect(during.isLiked, isTrue);
      expect(during.likeCount, 543);

      expect(await pending, isNull);
      final after = c
          .read(feedControllerProvider)
          .posts
          .firstWhere((p) => p.id == 'p2');
      expect(after.likeCount, 543);

      await notifier.toggleLike(after);
      expect(
        c
            .read(feedControllerProvider)
            .posts
            .firstWhere((p) => p.id == 'p2')
            .likeCount,
        542,
      );
    },
  );

  test(
    'กดไลก์แล้วเน็ตหลุด — ย้อนกลับค่าเดิมและคืน Failure ให้แจ้งผู้ใช้',
    () async {
      final repo = _newRepo();
      final c = _container(repo);
      await _loaded(c);
      final p2 = c
          .read(feedControllerProvider)
          .posts
          .firstWhere((p) => p.id == 'p2');

      repo.failWrites = true;
      final failure = await c
          .read(feedControllerProvider.notifier)
          .toggleLike(p2);

      expect(failure, isA<NetworkFailure>());
      expect(
        c.read(feedControllerProvider).posts.firstWhere((p) => p.id == 'p2'),
        p2,
      );
    },
  );

  test('ติดตามบัญชี — ทุกโพสต์ของบัญชีนั้นเปลี่ยนสถานะพร้อมกัน', () async {
    final c = _container(_newRepo());
    await _loaded(c);
    final guy = c
        .read(feedControllerProvider)
        .posts
        .firstWhere((p) => p.id == 'p3');

    await c.read(feedControllerProvider.notifier).toggleFollow(guy);

    final updated = c
        .read(feedControllerProvider)
        .posts
        .firstWhere((p) => p.id == 'p3');
    expect(updated.isFollowingAuthor, isTrue);
  });

  test('ซ่อนโพสต์ — หายจากฟีดทันที และกลับมาถ้าเซิร์ฟเวอร์ล้มเหลว', () async {
    final repo = _newRepo();
    final c = _container(repo);
    await _loaded(c);
    final notifier = c.read(feedControllerProvider.notifier);
    final p4 = c
        .read(feedControllerProvider)
        .posts
        .firstWhere((p) => p.id == 'p4');

    expect(await notifier.hide(p4), isNull);
    expect(
      c.read(feedControllerProvider).posts.any((p) => p.id == 'p4'),
      isFalse,
    );

    final p5 = c
        .read(feedControllerProvider)
        .posts
        .firstWhere((p) => p.id == 'p5');
    repo.failWrites = true;
    expect(await notifier.hide(p5), isA<NetworkFailure>());
    expect(
      c.read(feedControllerProvider).posts.any((p) => p.id == 'p5'),
      isTrue,
    );
  });

  test('ซ่อนโพสต์จากบัญชี — โพสต์ของบัญชีนั้นหายหมด แต่ยังติดตามอยู่ และย้อนกลับถ้าล้มเหลว', () async {
    final repo = _newRepo();
    final c = _container(repo);
    await _loaded(c);
    final notifier = c.read(feedControllerProvider.notifier);
    final p2 = c
        .read(feedControllerProvider)
        .posts
        .firstWhere((p) => p.id == 'p2');

    expect(await notifier.hideAuthor(p2), isNull);
    final state = c.read(feedControllerProvider);
    expect(state.posts.any((p) => p.author.handle == 'maew.vetnote'), isFalse);

    await notifier.refresh();
    expect(
      c
          .read(feedControllerProvider)
          .posts
          .any((p) => p.author.handle == 'maew.vetnote'),
      isFalse,
    );

    final p5 = c
        .read(feedControllerProvider)
        .posts
        .firstWhere((p) => p.id == 'p5');
    repo.failWrites = true;
    expect(await notifier.hideAuthor(p5), isA<NetworkFailure>());
    expect(
      c.read(feedControllerProvider).posts.any((p) => p.id == 'p5'),
      isTrue,
    );
  });

  test(
    'โหลดไม่สำเร็จ — สถานะ error พร้อมข้อความ แล้วกดลองใหม่หายได้',
    () async {
      var fail = true;
      final repo = _FailingReads(_newRepo(), () => fail);
      final c = ProviderContainer(
        overrides: [feedRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(c.dispose);

      final state = await _loaded(c);
      expect(state.status, FeedStatus.error);
      expect(state.errorMessage, isNotEmpty);

      fail = false;
      await c.read(feedControllerProvider.notifier).retry();
      expect(c.read(feedControllerProvider).status, FeedStatus.ready);
    },
  );

  test('สลับแท็บเร็ว ๆ — ผลของแท็บเก่าที่ตอบช้าไม่ทับแท็บปัจจุบัน', () async {
    final c = _container(_newRepo());
    await _loaded(c);
    final notifier = c.read(feedControllerProvider.notifier);

    final first = notifier.selectTab(FeedTab.following);
    final second = notifier.selectTab(FeedTab.saved);
    await Future.wait([first, second]);

    final state = c.read(feedControllerProvider);
    expect(state.tab, FeedTab.saved);
    expect(state.posts.map((p) => p.id), ['p2', 'p4']);
  });
}

class _FailingReads extends _FlakyRepository {
  _FailingReads(super.inner, this._shouldFail);

  final bool Function() _shouldFail;

  @override
  Future<FeedPage> getPosts({
    required FeedTab tab,
    int cursor = 0,
    int limit = 5,
  }) {
    if (_shouldFail()) throw const NetworkFailure();
    return super.getPosts(tab: tab, cursor: cursor, limit: limit);
  }
}

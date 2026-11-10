import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/feed_tab.dart';
import '../../domain/entities/feed_user.dart';
import '../../domain/entities/post.dart';
import 'feed_providers.dart';

enum FeedStatus { loading, ready, error }

class FeedState {
  const FeedState({
    this.tab = FeedTab.all,
    this.status = FeedStatus.loading,
    this.posts = const [],
    this.accounts = const [],
    this.nextCursor,
    this.loadingMore = false,
    this.errorMessage,
  });

  final FeedTab tab;
  final FeedStatus status;
  final List<Post> posts;

  /// ทะเบียนบัญชีพร้อมสถานะติดตาม — ใช้วาดแท็บ "ติดตาม"
  final List<FeedUser> accounts;
  final int? nextCursor;
  final bool loadingMore;
  final String? errorMessage;

  List<FeedUser> get followedAccounts =>
      accounts.where((a) => a.isFollowing).toList();

  /// บัญชีแนะนำในแท็บติดตาม — ยังไม่ได้ติดตาม สูงสุด 4 บัญชีตามเว็บ
  List<FeedUser> get suggestedAccounts =>
      accounts.where((a) => !a.isFollowing && a.id != 'me').take(4).toList();

  FeedState copyWith({
    FeedTab? tab,
    FeedStatus? status,
    List<Post>? posts,
    List<FeedUser>? accounts,
    Object? nextCursor = _keep,
    bool? loadingMore,
    String? errorMessage,
  }) {
    return FeedState(
      tab: tab ?? this.tab,
      status: status ?? this.status,
      posts: posts ?? this.posts,
      accounts: accounts ?? this.accounts,
      nextCursor: identical(nextCursor, _keep)
          ? this.nextCursor
          : nextCursor as int?,
      loadingMore: loadingMore ?? this.loadingMore,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

const _keep = Object();

final feedControllerProvider = NotifierProvider<FeedController, FeedState>(
  FeedController.new,
);

/// จัดการสถานะฟีด: โหลด/แบ่งหน้า/สลับแท็บ และการกดไลก์-เซฟ-ติดตามแบบ optimistic
/// (UI เปลี่ยนทันที ถ้า API ล้มเหลวจะย้อนกลับและคืน [Failure] ให้หน้าจอแจ้งผู้ใช้)
class FeedController extends Notifier<FeedState> {
  /// ใช้ทิ้งผลของคำขอเก่าที่ตอบกลับมาช้ากว่าคำขอใหม่ (เช่น สลับแท็บเร็ว ๆ)
  int _requestId = 0;

  @override
  FeedState build() {
    Future.microtask(() => _load(reset: true));
    return const FeedState();
  }

  Future<void> selectTab(FeedTab tab) async {
    if (tab == state.tab) return;
    state = FeedState(tab: tab);
    await _load(reset: true);
  }

  Future<void> retry() async {
    state = FeedState(tab: state.tab);
    await _load(reset: true);
  }

  /// ดึงลงเพื่อรีเฟรช — คง posts เดิมไว้จนกว่าข้อมูลใหม่จะมา
  Future<void> refresh() => _load(reset: true, keepVisible: true);

  Future<void> loadMore() async {
    final canLoad =
        state.nextCursor != null &&
        !state.loadingMore &&
        state.status == FeedStatus.ready;
    if (!canLoad) return;
    state = state.copyWith(loadingMore: true);
    await _load(reset: false);
  }

  Future<void> _load({required bool reset, bool keepVisible = false}) async {
    final id = ++_requestId;
    final tab = state.tab;
    try {
      final pageFuture = ref.read(getFeedPageProvider)(
        tab: tab,
        cursor: reset ? 0 : (state.nextCursor ?? 0),
      );
      // แท็บติดตามต้องมีทะเบียนบัญชีเพื่อวาดแถว "กำลังติดตาม" + "แนะนำให้ติดตาม"
      final accountsFuture = tab == FeedTab.following
          ? ref.read(getAccountsProvider)()
          : Future<List<FeedUser>>.value(state.accounts);
      final (page, accounts) = await (pageFuture, accountsFuture).wait;
      if (!ref.mounted || id != _requestId) return;
      state = state.copyWith(
        status: FeedStatus.ready,
        posts: reset ? page.posts : [...state.posts, ...page.posts],
        accounts: accounts,
        nextCursor: page.nextCursor,
        loadingMore: false,
      );
    } on Failure catch (f) {
      if (!ref.mounted || id != _requestId) return;
      if (reset && !keepVisible) {
        state = state.copyWith(
          status: FeedStatus.error,
          errorMessage: f.message,
        );
      } else {
        state = state.copyWith(loadingMore: false);
      }
    }
  }

  void _replace(Post updated) {
    state = state.copyWith(
      posts: [for (final p in state.posts) p.id == updated.id ? updated : p],
    );
  }

  Future<Failure?> toggleLike(Post post) async {
    final liked = !post.isLiked;
    _replace(
      post.copyWith(
        isLiked: liked,
        likeCount: post.likeCount + (liked ? 1 : -1),
      ),
    );
    try {
      final server = await ref.read(toggleLikeProvider)(post.id);
      if (ref.mounted) _replace(server);
      return null;
    } on Failure catch (f) {
      if (ref.mounted) _replace(post);
      return f;
    }
  }

  Future<Failure?> toggleSave(Post post) async {
    _replace(post.copyWith(isSaved: !post.isSaved));
    try {
      final server = await ref.read(toggleSaveProvider)(post.id);
      if (ref.mounted) _replace(server);
      return null;
    } on Failure catch (f) {
      if (ref.mounted) _replace(post);
      return f;
    }
  }

  Future<Failure?> toggleFollow(Post post) =>
      _setFollowing(post.author.id, !post.isFollowingAuthor);

  /// กดติดตามจากแถว "แนะนำให้ติดตาม" (ไม่มีโพสต์เป็นตัวอ้าง)
  Future<Failure?> toggleFollowUser(FeedUser user) =>
      _setFollowing(user.id, !user.isFollowing);

  /// เปลี่ยนสถานะติดตามของบัญชี — อัปเดตทุกโพสต์ของบัญชีนั้นและทะเบียน accounts
  /// พร้อมกัน ถ้า API ล้มเหลวย้อนทั้ง state เดิมกลับ
  Future<Failure?> _setFollowing(String userId, bool following) async {
    final before = state;
    state = state.copyWith(
      posts: [
        for (final p in before.posts)
          p.author.id == userId ? p.copyWith(isFollowingAuthor: following) : p,
      ],
      accounts: [
        for (final a in before.accounts)
          a.id == userId ? a.copyWith(isFollowing: following) : a,
      ],
    );
    try {
      await ref.read(toggleFollowProvider)(userId);
      return null;
    } on Failure catch (f) {
      if (ref.mounted) state = before;
      return f;
    }
  }

  /// ซ่อนโพสต์ (ไม่สนใจ/ซ่อนจากบัญชีนี้) — เอาออกจากหน้าจอทันที
  Future<Failure?> hide(Post post) =>
      _remove(post, ref.read(hidePostProvider).call);

  /// ซ่อนทุกโพสต์ของบัญชีนี้ แต่ยังติดตามอยู่ (ตามเว็บ)
  Future<Failure?> hideAuthor(Post post) async {
    final before = state.posts;
    state = state.copyWith(
      posts: before.where((p) => p.author.id != post.author.id).toList(),
    );
    try {
      await ref.read(hideAccountPostsProvider)(post.author.id);
      return null;
    } on Failure catch (f) {
      if (ref.mounted) state = state.copyWith(posts: before);
      return f;
    }
  }

  Future<Failure?> delete(Post post) =>
      _remove(post, ref.read(deletePostProvider).call);

  Future<Failure?> _remove(
    Post post,
    Future<void> Function(String) action,
  ) async {
    final before = state.posts;
    state = state.copyWith(
      posts: before.where((p) => p.id != post.id).toList(),
    );
    try {
      await action(post.id);
      return null;
    } on Failure catch (f) {
      if (ref.mounted) state = state.copyWith(posts: before);
      return f;
    }
  }

  Future<Failure?> report(Post post, String reason) async {
    try {
      await ref.read(reportPostProvider)(post.id, reason);
      return null;
    } on Failure catch (f) {
      return f;
    }
  }
}

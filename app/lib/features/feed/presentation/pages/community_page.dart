import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/error_view.dart';
import '../../domain/entities/feed_tab.dart';
import '../../domain/entities/feed_user.dart';
import '../../domain/entities/post.dart';
import '../providers/feed_controller.dart';
import '../providers/feed_providers.dart';
import '../widgets/feed_header.dart';
import '../widgets/post_card.dart';
import '../widgets/post_card_skeleton.dart';
import '../widgets/post_menu_sheet.dart';
import '../widgets/story_row.dart';

class CommunityPage extends ConsumerStatefulWidget {
  const CommunityPage({super.key});

  @override
  ConsumerState<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends ConsumerState<CommunityPage> {
  final _scroll = ScrollController();

  /// โพสต์ที่เปิดดูจากกริดแท็บ "บันทึกไว้" (null = โชว์กริด)
  String? _openSavedPostId;

  Timer? _toastTimer;
  String? _toastMessage;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  void _maybeLoadMore() {
    if (_scroll.position.extentAfter < 600) {
      ref.read(feedControllerProvider.notifier).loadMore();
    }
  }

  /// toast เม็ดยาสีน้ำตาลเหนือแท็บล่าง หายเองใน 1.8 วินาที (ตามเว็บ)
  void _toast(String message) {
    _toastTimer?.cancel();
    setState(() => _toastMessage = message);
    _toastTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _toastMessage = null);
    });
  }

  void _comingSoon(String feature) =>
      _toast('$feature — กำลังพัฒนา จะมาในเฟสถัดไป');

  Future<void> _run(Future<Failure?> Function() action) async {
    final failure = await action();
    if (failure != null && mounted) _toast(failure.message);
  }

  Future<void> _toggleFollow(Post post) async {
    final wasFollowing = post.isFollowingAuthor;
    final failure = await ref
        .read(feedControllerProvider.notifier)
        .toggleFollow(post);
    if (!mounted) return;
    final handle = post.author.handle;
    _toast(
      failure?.message ??
          (wasFollowing ? 'เลิกติดตาม $handle' : 'ติดตาม $handle แล้ว'),
    );
  }

  Future<void> _toggleSave(Post post) async {
    final wasSaved = post.isSaved;
    final failure = await ref
        .read(feedControllerProvider.notifier)
        .toggleSave(post);
    if (!mounted) return;
    _toast(
      failure?.message ??
          (wasSaved
              ? 'นำออกจากรายการที่บันทึกไว้'
              : 'บันทึกแล้ว · ดูได้ที่แท็บบันทึกไว้'),
    );
  }

  Future<void> _openMenu(Post post) async {
    final result = await showPostMenuSheet(context, post);
    if (result == null || !mounted) return;
    final controller = ref.read(feedControllerProvider.notifier);
    switch (result.action) {
      case PostMenuAction.notInterested:
        final f = await controller.hide(post);
        if (mounted) _toast(f?.message ?? 'ซ่อนโพสต์แล้ว จะแสดงแบบนี้น้อยลง');
      case PostMenuAction.hideAuthor:
        final f = await controller.hideAuthor(post);
        if (mounted) {
          _toast(f?.message ?? 'ซ่อนโพสต์จาก ${post.author.handle} แล้ว');
        }
      case PostMenuAction.copyLink:
        await Clipboard.setData(
          ClipboardData(text: 'https://แมว.live/p/${post.id}'),
        );
        if (mounted) _toast('คัดลอกลิงก์แล้ว');
      case PostMenuAction.report:
        final f = await controller.report(post, result.reason ?? '');
        if (f == null) await controller.hide(post);
        if (mounted) _toast(f?.message ?? 'ขอบคุณที่รายงาน ทีมงานจะตรวจสอบ');
      case PostMenuAction.delete:
        final f = await controller.delete(post);
        if (mounted) _toast(f?.message ?? 'ลบโพสต์แล้ว');
    }
  }

  void _selectTab(FeedTab tab) {
    if (_openSavedPostId != null) setState(() => _openSavedPostId = null);
    ref.read(feedControllerProvider.notifier).selectTab(tab);
  }

  /// กดติดตามจากแถว "แนะนำให้ติดตาม" — เว็บโชว์ toast `ติดตาม <handle> แล้ว`
  Future<void> _followUser(FeedUser user) async {
    final failure = await ref
        .read(feedControllerProvider.notifier)
        .toggleFollowUser(user);
    if (!mounted) return;
    _toast(failure?.message ?? 'ติดตาม ${user.handle} แล้ว');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(feedControllerProvider);
    final controller = ref.read(feedControllerProvider.notifier);

    final feed = SafeArea(
      bottom: false,
      child: Column(
        children: [
          FeedHeader(
            tab: state.tab,
            onTabChanged: _selectTab,
            onComingSoon: _comingSoon,
          ),
          Expanded(
            child: switch (state.status) {
              FeedStatus.loading => ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
                itemBuilder: (_, _) => const PostCardSkeleton(),
              ),
              FeedStatus.error => ErrorView(
                title: 'โหลดฟีดไม่สำเร็จ',
                message:
                    state.errorMessage ??
                    'ตรวจสัญญาณอินเทอร์เน็ตแล้วลองใหม่อีกครั้ง',
                onRetry: controller.retry,
              ),
              FeedStatus.ready => RefreshIndicator(
                color: AppColors.muted,
                onRefresh: controller.refresh,
                child: _FeedList(
                  state: state,
                  scroll: _scroll,
                  openSavedPostId: _openSavedPostId,
                  onOpenSavedPost: (id) =>
                      setState(() => _openSavedPostId = id),
                  onCloseSavedPost: () =>
                      setState(() => _openSavedPostId = null),
                  onFollowUser: _followUser,
                  onToggleLike: (p) => _run(() => controller.toggleLike(p)),
                  onToggleSave: _toggleSave,
                  onToggleFollow: _toggleFollow,
                  onOpenMenu: _openMenu,
                  onComingSoon: _comingSoon,
                ),
              ),
            },
          ),
        ],
      ),
    );

    return Stack(
      children: [
        feed,
        if (_toastMessage != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: IgnorePointer(
              child: Center(child: _ToastPill(message: _toastMessage!)),
            ),
          ),
      ],
    );
  }
}

/// ข้อความแจ้งสั้น ๆ รูปเม็ดยา — สี/ขนาดตามเว็บ (role=status)
class _ToastPill extends StatelessWidget {
  const _ToastPill({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xD94A3428),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            height: 1.5,
            fontWeight: FontWeight.w500,
            color: Colors.white,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}

class _FeedList extends ConsumerWidget {
  const _FeedList({
    required this.state,
    required this.scroll,
    required this.openSavedPostId,
    required this.onOpenSavedPost,
    required this.onCloseSavedPost,
    required this.onFollowUser,
    required this.onToggleLike,
    required this.onToggleSave,
    required this.onToggleFollow,
    required this.onOpenMenu,
    required this.onComingSoon,
  });

  final FeedState state;
  final ScrollController scroll;
  final String? openSavedPostId;
  final ValueChanged<String> onOpenSavedPost;
  final VoidCallback onCloseSavedPost;
  final ValueChanged<FeedUser> onFollowUser;
  final ValueChanged<Post> onToggleLike;
  final ValueChanged<Post> onToggleSave;
  final ValueChanged<Post> onToggleFollow;
  final ValueChanged<Post> onOpenMenu;
  final ValueChanged<String> onComingSoon;

  PostCard _card(Post post) => PostCard(
    key: ValueKey(post.id),
    post: post,
    onToggleLike: onToggleLike,
    onToggleSave: onToggleSave,
    onToggleFollow: onToggleFollow,
    onOpenMenu: onOpenMenu,
    onComingSoon: onComingSoon,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (state.tab) {
      FeedTab.saved => _buildSaved(),
      FeedTab.following => _buildFollowing(),
      FeedTab.all => _buildAll(ref),
    };
  }

  Widget _buildAll(WidgetRef ref) {
    final stories = ref.watch(storyUsersProvider).value ?? const [];
    final posts = state.posts;
    if (posts.isEmpty) {
      return _emptyScroll('ยังไม่มีโพสต์ในหมวดนี้');
    }
    return ListView.builder(
      controller: scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      scrollCacheExtent: const ScrollCacheExtent.pixels(800),
      itemCount: 1 + posts.length + (state.loadingMore ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == 0) return StoryRow(users: [...stories]);
        final index = i - 1;
        if (index >= posts.length) return const PostCardSkeleton();
        return _card(posts[index]);
      },
    );
  }

  /// แท็บติดตามตามเว็บ: แถว "กำลังติดตาม n บัญชี" + โพสต์บัญชีที่ติดตาม
  /// + ส่วน "แนะนำให้ติดตาม" ท้ายรายการ
  Widget _buildFollowing() {
    final followed = state.followedAccounts;
    final suggested = state.suggestedAccounts;
    final posts = state.posts;
    return ListView(
      controller: scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      scrollCacheExtent: const ScrollCacheExtent.pixels(800),
      children: [
        _FollowingBar(
          accounts: followed,
          onTap: () => onComingSoon('รายชื่อบัญชีที่ติดตาม'),
        ),
        if (posts.isEmpty)
          _EmptyLine(
            followed.isEmpty
                ? 'ยังไม่ได้ติดตามใคร · ลองติดตามบัญชีด้านล่าง'
                : 'บัญชีที่คุณติดตามยังไม่มีโพสต์ในหมวดนี้',
          )
        else
          for (final post in posts) _card(post),
        if (state.loadingMore) const PostCardSkeleton(),
        if (suggested.isNotEmpty)
          _SuggestedAccounts(users: suggested, onFollow: onFollowUser),
      ],
    );
  }

  /// แท็บบันทึกไว้ตามเว็บ: กริดรูป 3 คอลัมน์ แตะเพื่อเปิดโพสต์เต็ม
  Widget _buildSaved() {
    final posts = state.posts;
    Post? opened;
    if (openSavedPostId != null) {
      for (final p in posts) {
        if (p.id == openSavedPostId) opened = p;
      }
    }
    if (opened != null) {
      return ListView(
        controller: scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        scrollCacheExtent: const ScrollCacheExtent.pixels(800),
        children: [
          _BackToSavedButton(onTap: onCloseSavedPost),
          _card(opened),
        ],
      );
    }
    if (posts.isEmpty) {
      return _emptyScroll(
        'ยังไม่มีโพสต์ที่บันทึกไว้ · กดไอคอนบุ๊กมาร์กใต้โพสต์เพื่อบันทึก',
      );
    }
    return CustomScrollView(
      controller: scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      scrollCacheExtent: const ScrollCacheExtent.pixels(800),
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  'บันทึกไว้ ${posts.length} โพสต์',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const Text(
                  'แตะเพื่อเปิดโพสต์',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ),
        SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, i) => _SavedTile(
              post: posts[i],
              onOpen: () => onOpenSavedPost(posts[i].id),
            ),
            childCount: posts.length,
          ),
        ),
      ],
    );
  }

  Widget _emptyScroll(String text) => ListView(
    controller: scroll,
    physics: const AlwaysScrollableScrollPhysics(),
    children: [_EmptyLine(text)],
  );
}

/// ข้อความว่างบรรทัดเดียวกึ่งกลาง — รูปแบบเดียวกับเว็บ (el)
class _EmptyLine extends StatelessWidget {
  const _EmptyLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 14,
          height: 1.5,
          color: AppColors.muted,
        ),
      ),
    );
  }
}

/// แถวลิงก์ "กำลังติดตาม n บัญชี · ดูทั้งหมด" เหนือฟีดแท็บติดตาม
class _FollowingBar extends StatelessWidget {
  const _FollowingBar({required this.accounts, required this.onTap});

  final List<FeedUser> accounts;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shown = accounts.take(3).toList();
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: AppColors.line)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: shown.isEmpty ? 0 : 30 + (shown.length - 1) * 20,
              height: 30,
              child: Stack(
                children: [
                  for (var i = 0; i < shown.length; i++)
                    Positioned(
                      left: i * 20.0,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: AppAvatar(
                          source: shown[i].avatar,
                          bg: shown[i].avatarBg,
                          size: 26,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'กำลังติดตาม ${accounts.length} บัญชี',
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
            ),
            const Row(
              children: [
                Text(
                  'ดูทั้งหมด ',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                Icon(LucideIcons.chevronRight, size: 15, color: AppColors.ink),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// ส่วน "แนะนำให้ติดตาม" ท้ายแท็บติดตาม — บัญชีที่ยังไม่ได้ติดตาม
class _SuggestedAccounts extends StatelessWidget {
  const _SuggestedAccounts({required this.users, required this.onFollow});

  final List<FeedUser> users;
  final ValueChanged<FeedUser> onFollow;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Text(
              'แนะนำให้ติดตาม',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
          for (final user in users)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  AppAvatar(source: user.avatar, bg: user.avatarBg, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      user.handle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => onFollow(user),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.btn,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.btnBorder,
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'ติดตาม',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// รูปย่อในกริดแท็บบันทึกไว้ — รูปแรกของโพสต์ แตะเพื่อเปิด
class _SavedTile extends StatelessWidget {
  const _SavedTile({required this.post, required this.onOpen});

  final Post post;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOpen,
      child: ColoredBox(
        color: AppColors.media,
        child: AppImage(
          source: post.media.first.url,
          semanticLabel: post.media.first.alt,
        ),
      ),
    );
  }
}

/// ปุ่ม "กลับไปที่บันทึกไว้" เหนือโพสต์ที่เปิดจากกริด
class _BackToSavedButton extends StatelessWidget {
  const _BackToSavedButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: AppColors.line)),
        ),
        child: const Row(
          children: [
            Icon(LucideIcons.arrowLeft, size: 18, color: AppColors.ink),
            SizedBox(width: 4),
            Text(
              'กลับไปที่บันทึกไว้',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_view.dart';
import '../../domain/entities/feed_tab.dart';
import '../../domain/entities/post.dart';
import '../providers/feed_controller.dart';
import '../providers/feed_providers.dart';
import '../widgets/feed_header.dart';
import '../widgets/post_card.dart';
import '../widgets/post_card_skeleton.dart';
import '../widgets/post_menu_sheet.dart';
import '../widgets/story_row.dart';

const _emptyText = {
  FeedTab.all: ('ยังไม่มีโพสต์', 'กลับมาดูใหม่ภายหลังนะ'),
  FeedTab.following: (
    'ยังไม่ได้ติดตามใคร',
    'ติดตามบัญชีที่ชอบเพื่อดูโพสต์ของเขาที่นี่',
  ),
  FeedTab.saved: (
    'ยังไม่มีโพสต์ที่บันทึก',
    'กดปุ่มบันทึกบนโพสต์เพื่อเก็บไว้ดูภายหลัง',
  ),
};

class CommunityPage extends ConsumerStatefulWidget {
  const CommunityPage({super.key});

  @override
  ConsumerState<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends ConsumerState<CommunityPage> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _maybeLoadMore() {
    if (_scroll.position.extentAfter < 600) {
      ref.read(feedControllerProvider.notifier).loadMore();
    }
  }

  void _toast(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  void _comingSoon(String feature) =>
      _toast('$feature — กำลังพัฒนา จะมาในเฟสถัดไป');

  Future<void> _run(Future<Failure?> Function() action) async {
    final failure = await action();
    if (failure != null && mounted) _toast(failure.message);
  }

  Future<void> _openMenu(Post post) async {
    final action = await showPostMenuSheet(context, isOwnPost: post.isOwn);
    if (action == null || !mounted) return;
    final controller = ref.read(feedControllerProvider.notifier);
    switch (action) {
      case PostMenuAction.notInterested || PostMenuAction.hideAuthor:
        await _run(() => controller.hide(post));
      case PostMenuAction.copyLink:
        await Clipboard.setData(
          ClipboardData(text: 'https://แมว.live/p/${post.id}'),
        );
        _toast('คัดลอกลิงก์แล้ว');
      case PostMenuAction.report:
        await _askReportReason(post);
      case PostMenuAction.delete:
        await _confirmDelete(post);
    }
  }

  Future<void> _askReportReason(Post post) async {
    const reasons = {
      'spam': 'สแปมหรือโฆษณา',
      'inappropriate': 'เนื้อหาไม่เหมาะสม',
      'animal_abuse': 'ทารุณสัตว์',
    };
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text(
          'รายงานโพสต์',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        children: [
          for (final e in reasons.entries)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, e.key),
              child: Text(e.value, style: const TextStyle(fontSize: 16)),
            ),
        ],
      ),
    );
    if (reason == null || !mounted) return;
    await _run(
      () => ref.read(feedControllerProvider.notifier).report(post, reason),
    );
    if (mounted) _toast('ส่งรายงานแล้ว ขอบคุณที่ช่วยดูแลชุมชน');
  }

  Future<void> _confirmDelete(Post post) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบโพสต์'),
        content: const Text('ลบโพสต์นี้ถาวร ไม่สามารถกู้คืนได้'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบ', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await _run(() => ref.read(feedControllerProvider.notifier).delete(post));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(feedControllerProvider);
    final controller = ref.read(feedControllerProvider.notifier);

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          FeedHeader(
            tab: state.tab,
            onTabChanged: controller.selectTab,
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
                  onToggleLike: (p) => _run(() => controller.toggleLike(p)),
                  onToggleSave: (p) => _run(() => controller.toggleSave(p)),
                  onToggleFollow: (p) => _run(() => controller.toggleFollow(p)),
                  onOpenMenu: _openMenu,
                  onComingSoon: _comingSoon,
                ),
              ),
            },
          ),
        ],
      ),
    );
  }
}

class _FeedList extends ConsumerWidget {
  const _FeedList({
    required this.state,
    required this.scroll,
    required this.onToggleLike,
    required this.onToggleSave,
    required this.onToggleFollow,
    required this.onOpenMenu,
    required this.onComingSoon,
  });

  final FeedState state;
  final ScrollController scroll;
  final ValueChanged<Post> onToggleLike;
  final ValueChanged<Post> onToggleSave;
  final ValueChanged<Post> onToggleFollow;
  final ValueChanged<Post> onOpenMenu;
  final ValueChanged<String> onComingSoon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showStories = state.tab == FeedTab.all;
    final stories = showStories
        ? ref.watch(storyUsersProvider).value ?? const []
        : const [];
    final posts = state.posts;

    if (posts.isEmpty) {
      final (title, detail) = _emptyText[state.tab]!;
      return ListView(
        controller: scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          const Center(child: Text('🐈', style: TextStyle(fontSize: 48))),
          const SizedBox(height: 16),
          Center(
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              detail,
              style: const TextStyle(fontSize: 14, color: AppColors.muted),
            ),
          ),
        ],
      );
    }

    final headerCount = showStories ? 1 : 0;
    return ListView.builder(
      controller: scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: headerCount + posts.length + (state.loadingMore ? 1 : 0),
      itemBuilder: (context, i) {
        if (i < headerCount) return StoryRow(users: [...stories]);
        final index = i - headerCount;
        if (index >= posts.length) return const PostCardSkeleton();
        final post = posts[index];
        return PostCard(
          key: ValueKey(post.id),
          post: post,
          onToggleLike: onToggleLike,
          onToggleSave: onToggleSave,
          onToggleFollow: onToggleFollow,
          onOpenMenu: onOpenMenu,
          onComingSoon: onComingSoon,
        );
      },
    );
  }
}

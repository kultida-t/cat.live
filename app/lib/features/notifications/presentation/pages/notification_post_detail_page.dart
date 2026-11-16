import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/config/app_locale.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/toast_pill.dart';
import '../../../feed/domain/entities/post.dart';
import '../../../feed/presentation/providers/feed_controller.dart';
import '../../../feed/presentation/providers/feed_providers.dart';
import '../../../feed/presentation/widgets/comments_sheet.dart';
import '../../../feed/presentation/widgets/post_card.dart';
import '../../../feed/presentation/widgets/post_card_skeleton.dart';
import '../../../feed/presentation/widgets/post_menu_sheet.dart';
import '../../../feed/presentation/widgets/share_sheet.dart';

/// หน้าแสดงโพสต์รูปแบบเดียวกับหน้าฟีด (/notifications/post/:id)
/// ถ้า [openComments] เป็น true จะเด้งชีตความคิดเห็นขึ้นมาอัตโนมัติ
class NotificationPostDetailPage extends ConsumerStatefulWidget {
  const NotificationPostDetailPage({
    super.key,
    required this.postId,
    this.openComments = false,
  });

  final String postId;
  final bool openComments;

  @override
  ConsumerState<NotificationPostDetailPage> createState() =>
      _NotificationPostDetailPageState();
}

class _NotificationPostDetailPageState
    extends ConsumerState<NotificationPostDetailPage>
    with ToastMixin {
  bool _didAutoOpenComments = false;

  @override
  void dispose() {
    disposeToast();
    super.dispose();
  }

  Future<void> _run(Future<Failure?> Function() action) async {
    final failure = await action();
    if (failure != null && mounted) showToast(failure.message);
  }

  void _maybeOpenComments(Post post) {
    if (!widget.openComments || _didAutoOpenComments) return;
    _didAutoOpenComments = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showCommentsSheet(context, post);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEn = ref.watch(appLocaleProvider) == 'en';
    final feedState = ref.watch(feedControllerProvider);
    final feedCtrl = ref.read(feedControllerProvider.notifier);

    // ใช้โพสต์จาก feedState ก่อนถ้ามี เพื่อซิงก์ยอดไลก์/เซฟ/คอมเมนต์กับหน้าฟีดทันที
    final fromFeed = feedState.posts
        .where((p) => p.id == widget.postId)
        .firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.page,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _Header(isEn: isEn, onBack: () => context.pop()),
                Expanded(
                  child: fromFeed != null
                      ? _buildFeedPostView(fromFeed, feedCtrl)
                      : ref
                            .watch(postProvider(widget.postId))
                            .when(
                              loading: () => ListView(
                                padding: const EdgeInsets.only(top: 8),
                                children: const [PostCardSkeleton()],
                              ),
                              error: (error, _) => ErrorView(
                                message: error is Failure
                                    ? error.message
                                    : (isEn
                                          ? 'Could not load post'
                                          : 'โหลดโพสต์ไม่สำเร็จ'),
                                actionLabel: isEn ? 'Try again' : 'ลองใหม่',
                                onRetry: () =>
                                    ref.invalidate(postProvider(widget.postId)),
                              ),
                              data: (post) =>
                                  _buildFeedPostView(post, feedCtrl),
                            ),
                ),
              ],
            ),
          ),
          if (toastMessage != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 32,
              child: IgnorePointer(
                child: Center(child: ToastPill(message: toastMessage!)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeedPostView(Post post, FeedController feedCtrl) {
    _maybeOpenComments(post);
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        PostCard(
          key: ValueKey(post.id),
          post: post,
          onToggleLike: (p) => _run(() => feedCtrl.toggleLike(p)),
          onToggleSave: (p) => _run(() => feedCtrl.toggleSave(p)),
          onToggleFollow: (p) => _run(() => feedCtrl.toggleFollow(p)),
          onOpenMenu: (p) => showPostMenuSheet(context, p),
          onOpenComments: (p) => showCommentsSheet(context, p),
          onShare: (p) => showShareSheet(context, p),
          onComingSoon: (f) => showToast('$f — กำลังพัฒนา จะมาในเฟสถัดไป'),
          onOpenTreats: (p) => context.push(
            '/treats?to=${Uri.encodeQueryComponent(p.author.id)}',
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.isEn, required this.onBack});

  final bool isEn;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 12, 8),
      decoration: const BoxDecoration(
        color: AppColors.page,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: isEn ? 'Back' : 'ย้อนกลับ',
            excludeSemantics: true,
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(14),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  LucideIcons.chevronLeft,
                  size: 24,
                  color: AppColors.text,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              isEn ? 'Post' : 'โพสต์',
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

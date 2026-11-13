import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/toast_pill.dart';
import '../../../feed/domain/entities/post.dart';
import '../../../feed/presentation/providers/comments_controller.dart';
import '../../../feed/presentation/widgets/comments_sheet.dart';
import '../../../feed/presentation/widgets/post_menu_sheet.dart';
import '../../../feed/presentation/widgets/share_sheet.dart';
import '../providers/home_controller.dart';
import '../widgets/hero_photo_sheet.dart';
import '../widgets/home_header.dart';
import '../widgets/home_hero_banner.dart';
import '../widgets/home_post_preview_card.dart';
import '../widgets/home_updates_skeleton.dart';
import '../widgets/quick_actions_row.dart';

/// หน้าแรก (/) — เทียบตรงจากเว็บต้นแบบ www.แมว.live
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with ToastMixin {
  bool _wasActive = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // เมื่อสลับกลับมาจากแท็บฟีดให้ซิงก์โพสต์ล่าสุดเงียบ ๆ
    final active = TickerMode.valuesOf(context).enabled;
    if (active && !_wasActive) {
      ref.read(homeControllerProvider.notifier).refresh();
    }
    _wasActive = active;
  }

  @override
  void dispose() {
    disposeToast();
    super.dispose();
  }

  void _comingSoon(String feature) =>
      showToast('$feature — กำลังพัฒนา จะมาในเฟสถัดไป');

  Future<void> _run(Future<Failure?> Function() action) async {
    final failure = await action();
    if (failure != null && mounted) showToast(failure.message);
  }

  Future<void> _toggleSave(Post post) async {
    final wasSaved = post.isSaved;
    final failure = await ref
        .read(homeControllerProvider.notifier)
        .toggleSave(post);
    if (!mounted) return;
    showToast(
      failure?.message ??
          (wasSaved
              ? 'นำออกจากรายการที่บันทึกไว้'
              : 'บันทึกแล้ว · ดูได้ที่แท็บบันทึกไว้'),
    );
  }

  Future<void> _openMenu(Post post) async {
    final result = await showPostMenuSheet(context, post);
    if (result == null || !mounted) return;
    final controller = ref.read(homeControllerProvider.notifier);
    switch (result.action) {
      case PostMenuAction.notInterested:
        final f = await controller.hide(post);
        if (mounted) {
          showToast(f?.message ?? 'ซ่อนโพสต์แล้ว จะแสดงแบบนี้น้อยลง');
        }
      case PostMenuAction.hideAuthor:
        final f = await controller.hideAuthor(post);
        if (mounted) {
          showToast(f?.message ?? 'ซ่อนโพสต์จาก ${post.author.handle} แล้ว');
        }
      case PostMenuAction.copyLink:
        await Clipboard.setData(
          ClipboardData(text: AppConfig.postUrl(post.id)),
        );
        if (mounted) showToast('คัดลอกลิงก์แล้ว');
      case PostMenuAction.report:
        final f = await controller.report(post, result.reason ?? '');
        if (f == null) await controller.hide(post);
        if (mounted) showToast(f?.message ?? 'ขอบคุณที่รายงาน ทีมงานจะตรวจสอบ');
      case PostMenuAction.delete:
        final f = await controller.delete(post);
        if (mounted) showToast(f?.message ?? 'ลบโพสต์แล้ว');
    }
  }

  Future<void> _openComments(Post post) async {
    final sub = ref.listenManual<CommentsState>(
      commentsControllerProvider(post.id),
      (prev, next) {
        if (prev?.status == CommentsStatus.ready &&
            next.status == CommentsStatus.ready &&
            next.comments.length != prev!.comments.length) {
          ref
              .read(homeControllerProvider.notifier)
              .bumpCommentCount(
                post.id,
                by: next.comments.length - prev.comments.length,
              );
        }
      },
    );
    try {
      await showCommentsSheet(context, post);
    } finally {
      sub.close();
      if (mounted) {
        await ref.read(homeControllerProvider.notifier).refresh();
      }
    }
  }

  void _openShare(Post post) {
    showShareSheet(context, post);
  }

  void _openHeroPicker() {
    showHeroPhotoSheet(context, onMessage: showToast);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeControllerProvider);
    final controller = ref.read(homeControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.ink,
          backgroundColor: Colors.white,
          onRefresh: controller.refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: HomeHeader(
                  onComingSoon: _comingSoon,
                  onOpenMenu: () => context.push('/menu'),
                  onOpenSearch: () => context.push('/search'),
                  onOpenMessages: () => context.push('/messages'),
                ),
              ),
              SliverToBoxAdapter(
                child: HomeHeroBanner(
                  photo: state.activeHeroPhoto,
                  isCustomSelected: state.isCustomSelected,
                  onPhotoTap: state.isCustomSelected
                      ? _openHeroPicker
                      : controller.nextSlide,
                  onOpenPicker: _openHeroPicker,
                ),
              ),
              const SliverToBoxAdapter(child: QuickActionsRow()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'อัปเดตจากชุมชน',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                      Semantics(
                        button: true,
                        label: 'ดูทั้งหมด',
                        excludeSemantics: true,
                        child: InkWell(
                          onTap: () => context.go('/community'),
                          borderRadius: BorderRadius.circular(10),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              minWidth: 44,
                              minHeight: 44,
                            ),
                            child: const Align(
                              alignment: Alignment.centerRight,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'ดูทั้งหมด',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                    SizedBox(width: 2),
                                    Icon(
                                      LucideIcons.chevronRight,
                                      size: 16,
                                      color: AppColors.ink,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ..._buildUpdatesSlivers(state, controller),
              const SliverToBoxAdapter(child: SizedBox(height: 28)),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildUpdatesSlivers(
    HomeState state,
    HomeController controller,
  ) {
    switch (state.updatesStatus) {
      case HomeUpdatesStatus.loading:
        return const [SliverToBoxAdapter(child: HomeUpdatesSkeleton())];
      case HomeUpdatesStatus.error:
        return [
          SliverToBoxAdapter(
            child: ErrorView(
              message: state.errorMessage ?? 'โหลดอัปเดตจากชุมชนไม่สำเร็จ',
              onRetry: controller.retry,
            ),
          ),
        ];
      case HomeUpdatesStatus.ready:
        if (state.posts.isEmpty) {
          return const [SliverToBoxAdapter(child: _EmptyUpdatesCard())];
        }
        return [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.separated(
              itemCount: state.posts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final post = state.posts[i];
                return HomePostPreviewCard(
                  post: post,
                  onOpenFeed: () => context.go('/community'),
                  onToggleLike: (p) => _run(() => controller.toggleLike(p)),
                  onToggleSave: _toggleSave,
                  onOpenComments: _openComments,
                  onShare: _openShare,
                  onOpenMenu: _openMenu,
                  onComingSoon: _comingSoon,
                  onOpenTreats: (p) => context.push(
                    '/treats?to=${Uri.encodeQueryComponent(p.author.id)}',
                  ),
                );
              },
            ),
          ),
        ];
    }
  }
}

class _EmptyUpdatesCard extends StatelessWidget {
  const _EmptyUpdatesCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.line),
        ),
        child: const Column(
          children: [
            Text(
              'ยังไม่มีอัปเดตจากชุมชน',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'ลองไปดูโพสต์ทั้งหมดหรือแบ่งปันเรื่องราวน้องแมวในฟีด',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

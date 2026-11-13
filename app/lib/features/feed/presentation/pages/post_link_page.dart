import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/format/compact_count.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/app_video.dart';
import '../../../../core/widgets/error_view.dart';
import '../../domain/entities/post.dart';
import '../providers/feed_providers.dart';

/// หน้าลิงก์โพสต์ `/p/:id` — หน้าที่คนเปิดจากลิงก์ที่ถูกคัดลอก/แชร์ออกไป
/// แสดงรูปแรก ยอดไลก์/คอมเมนต์ และแคปชัน พร้อมปุ่มเข้าแอปกับเลี้ยงขนม (ตามเว็บ)
class PostLinkPage extends ConsumerWidget {
  const PostLinkPage({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final post = ref.watch(postProvider(postId));
    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: post.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.muted,
            ),
          ),
          error: (error, _) => error is NotFoundFailure
              ? ErrorView(
                  emoji: '🐈',
                  title: 'ไม่พบโพสต์นี้',
                  message: 'โพสต์อาจถูกลบแล้ว หรือลิงก์ไม่ถูกต้อง',
                  actionLabel: 'ไปที่ฟีด',
                  onRetry: () => context.go('/community'),
                )
              : ErrorView(
                  message: error is Failure ? error.message : 'ลองใหม่อีกครั้ง',
                  onRetry: () => ref.invalidate(postProvider(postId)),
                ),
          data: (post) => _Content(post: post),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.post});

  final Post post;

  void _treat(BuildContext context) {
    final to = Uri.encodeQueryComponent(post.author.id);
    context.push('/treats?to=$to');
  }

  @override
  Widget build(BuildContext context) {
    final first = post.media.first;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: SizedBox(
                height: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (context.canPop())
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Semantics(
                          button: true,
                          label: 'ย้อนกลับ',
                          excludeSemantics: true,
                          child: InkWell(
                            onTap: () => context.pop(),
                            borderRadius: BorderRadius.circular(12),
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
                      ),
                    Image.asset(
                      'assets/brand/maew-logo.png',
                      width: 123,
                      height: 36,
                      semanticLabel: 'แมว.live',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        AppAvatar(
                          source: post.author.avatar,
                          bg: post.author.avatarBg,
                          size: 40,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.author.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.text,
                                ),
                              ),
                              Text(
                                '${post.categoryLabel} · ${post.postedAgoText}',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  AspectRatio(
                    aspectRatio: 1,
                    child: first.isVideo
                        ? AppVideo(source: first.url, semanticLabel: first.alt)
                        : AppImage(source: first.url, semanticLabel: first.alt),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DefaultTextStyle(
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.heart,
                                size: 20,
                                color: AppColors.text,
                              ),
                              const SizedBox(width: 6),
                              Text(compactCount(post.likeCount)),
                              const SizedBox(width: 16),
                              const Icon(
                                LucideIcons.messageCircle,
                                size: 20,
                                color: AppColors.text,
                              ),
                              const SizedBox(width: 6),
                              Text(compactCount(post.commentCount)),
                              const Spacer(),
                              if (post.media.length > 1)
                                Text(
                                  '+${post.media.length - 1} รูป',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.muted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          post.caption,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.625,
                            color: AppColors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => context.go('/community'),
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.btn,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.btnBorder, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x59A0643C),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                      spreadRadius: -5,
                    ),
                  ],
                ),
                child: const Text(
                  'ดูโพสต์นี้ในแอป แมว.live',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (!post.isOwn)
              GestureDetector(
                onTap: () => _treat(context),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.line2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        LucideIcons.gift,
                        size: 20,
                        color: AppColors.text,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'เลี้ยงขนม ${post.author.displayName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/format/compact_count.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/app_video.dart';
import '../../../../core/widgets/fill_icon.dart';
import '../../../feed/domain/entities/post.dart';

/// การ์ดโพสต์แบบย่อในส่วน "อัปเดตจากชุมชน" บนหน้าแรก — ตรงกับเว็บจริง www.แมว.live
class HomePostPreviewCard extends StatelessWidget {
  const HomePostPreviewCard({
    super.key,
    required this.post,
    required this.onOpenFeed,
    required this.onToggleLike,
    required this.onToggleSave,
    required this.onOpenComments,
    required this.onShare,
    required this.onOpenMenu,
    required this.onComingSoon,
    this.onOpenTreats,
  });

  final Post post;
  final VoidCallback onOpenFeed;
  final ValueChanged<Post> onToggleLike;
  final ValueChanged<Post> onToggleSave;
  final ValueChanged<Post> onOpenComments;
  final ValueChanged<Post> onShare;
  final ValueChanged<Post> onOpenMenu;
  final ValueChanged<String> onComingSoon;
  final ValueChanged<Post>? onOpenTreats;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F4A3428),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PreviewHeader(post: post, onOpenMenu: () => onOpenMenu(post)),
          if (post.caption.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              post.caption,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.text,
              ),
            ),
          ],
          if (post.media.isNotEmpty) ...[
            const SizedBox(height: 10),
            _PreviewMedia(media: post.media, onTap: onOpenFeed),
          ],
          const SizedBox(height: 4),
          _PreviewActions(
            post: post,
            onToggleLike: () => onToggleLike(post),
            onToggleSave: () => onToggleSave(post),
            onOpenComments: () => onOpenComments(post),
            onShare: () => onShare(post),
            onComingSoon: onComingSoon,
            onOpenTreats: onOpenTreats == null
                ? null
                : () => onOpenTreats!(post),
          ),
        ],
      ),
    );
  }
}

class _PreviewHeader extends StatelessWidget {
  const _PreviewHeader({required this.post, required this.onOpenMenu});

  final Post post;
  final VoidCallback onOpenMenu;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppAvatar(
          source: post.author.avatar,
          bg: post.author.avatarBg,
          size: 36,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: post.author.displayName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                TextSpan(
                  text: ' · ${post.postedAgoText}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Semantics(
          button: true,
          label: 'ตัวเลือกโพสต์',
          excludeSemantics: true,
          child: InkWell(
            onTap: onOpenMenu,
            borderRadius: BorderRadius.circular(12),
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                LucideIcons.ellipsis,
                size: 20,
                color: AppColors.muted,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PreviewMedia extends StatelessWidget {
  const _PreviewMedia({required this.media, required this.onTap});

  final List<PostMedia> media;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final preview = media.take(2).toList();
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Material(
        color: AppColors.media,
        child: InkWell(
          onTap: onTap,
          child: preview.length == 1
              ? AspectRatio(
                  aspectRatio: 4 / 3,
                  child: _MediaTile(item: preview.first),
                )
              : SizedBox(
                  height: 149,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 16,
                        child: SizedBox.expand(
                          child: _MediaTile(item: preview[0]),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        flex: 10,
                        child: SizedBox.expand(
                          child: _MediaTile(item: preview[1]),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _MediaTile extends StatelessWidget {
  const _MediaTile({required this.item});

  final PostMedia item;

  @override
  Widget build(BuildContext context) {
    if (item.isVideo) {
      return AppVideo(source: item.url, semanticLabel: item.alt);
    }
    return AppImage(source: item.url, semanticLabel: item.alt);
  }
}

class _PreviewActions extends StatelessWidget {
  const _PreviewActions({
    required this.post,
    required this.onToggleLike,
    required this.onToggleSave,
    required this.onOpenComments,
    required this.onShare,
    required this.onComingSoon,
    this.onOpenTreats,
  });

  final Post post;
  final VoidCallback onToggleLike;
  final VoidCallback onToggleSave;
  final VoidCallback onOpenComments;
  final VoidCallback onShare;
  final ValueChanged<String> onComingSoon;
  final VoidCallback? onOpenTreats;

  @override
  Widget build(BuildContext context) {
    final likeColor = post.isLiked ? AppColors.heart : AppColors.text;
    return Row(
      children: [
        _ActionButton(
          label: post.isLiked ? 'เลิกถูกใจ' : 'ถูกใจ',
          count: post.likeCount,
          onTap: onToggleLike,
          icon: FillIcon(
            shape: FillIconShape.heart,
            color: likeColor,
            filled: post.isLiked,
            size: 22,
          ),
        ),
        _ActionButton(
          label: 'ความคิดเห็น ${post.commentCount} รายการ',
          count: post.commentCount,
          onTap: onOpenComments,
          icon: const Icon(
            LucideIcons.messageCircle,
            size: 22,
            color: AppColors.text,
          ),
        ),
        if (!post.isOwn)
          _ActionButton(
            label: 'เลี้ยงขนม ${post.author.displayName}',
            onTap: onOpenTreats ?? () => onComingSoon('เลี้ยงขนม'),
            icon: const Icon(LucideIcons.gift, size: 22, color: AppColors.text),
          ),
        _ActionButton(
          label: 'แชร์',
          count: post.shareCount,
          onTap: onShare,
          icon: const Icon(LucideIcons.send, size: 22, color: AppColors.text),
        ),
        const Spacer(),
        _ActionButton(
          label: post.isSaved ? 'นำออกจากบันทึก' : 'บันทึกโพสต์',
          onTap: onToggleSave,
          icon: FillIcon(
            shape: FillIconShape.bookmark,
            color: AppColors.text,
            filled: post.isSaved,
            size: 22,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.count = 0,
  });

  final String label;
  final Widget icon;
  final VoidCallback onTap;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                if (count > 0) ...[
                  const SizedBox(width: 4),
                  Text(
                    compactCount(count),
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

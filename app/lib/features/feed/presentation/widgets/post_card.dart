import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/format/compact_count.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/app_video.dart';
import '../../../../core/widgets/fill_icon.dart';
import '../../domain/entities/post.dart';

/// การ์ดโพสต์ฟีด — layout/สี/ขนาดตามเว็บ prototype (www.แมว.live)
class PostCard extends StatefulWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.onToggleLike,
    required this.onToggleSave,
    required this.onToggleFollow,
    required this.onOpenMenu,
    required this.onOpenComments,
    required this.onShare,
    required this.onComingSoon,
    this.onOpenTreats,
  });

  final Post post;
  final ValueChanged<Post> onToggleLike;
  final ValueChanged<Post> onToggleSave;
  final ValueChanged<Post> onToggleFollow;
  final ValueChanged<Post> onOpenMenu;
  final ValueChanged<Post> onOpenComments;
  final ValueChanged<Post> onShare;
  final ValueChanged<String> onComingSoon;
  final ValueChanged<Post>? onOpenTreats;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final _pageController = PageController();
  int _mediaIndex = 0;
  bool _precached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // อุ่นแคชรูปของโพสต์ล่วงหน้า ลดอาการกระตุกตอนเลื่อนฟีดถึงการ์ด
    if (_precached) return;
    _precached = true;
    for (final media in widget.post.media) {
      precacheImage(AppImage.providerOf(media.url), context);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(
            post: post,
            onToggleFollow: () => widget.onToggleFollow(post),
            onOpenMenu: () => widget.onOpenMenu(post),
          ),
          _Media(
            post: post,
            controller: _pageController,
            index: _mediaIndex,
            onChanged: (i) => setState(() => _mediaIndex = i),
          ),
          if (post.type == PostType.lostCat)
            _LostCatBar(onTap: () => widget.onComingSoon('แจ้งเบาะแส')),
          _Actions(
            post: post,
            onToggleLike: () => widget.onToggleLike(post),
            onToggleSave: () => widget.onToggleSave(post),
            onOpenComments: () => widget.onOpenComments(post),
            onShare: () => widget.onShare(post),
            onComingSoon: widget.onComingSoon,
            onOpenTreats: widget.onOpenTreats == null
                ? null
                : () => widget.onOpenTreats!(post),
          ),
          _Body(post: post, onOpenComments: () => widget.onOpenComments(post)),
        ],
      ),
    );
  }
}

/// แถบประกาศแมวหายใต้รูปโพสต์ — สี/ข้อความตามเว็บ (เห็นน้องไหม? → แจ้งเบาะแส)
class _LostCatBar extends StatelessWidget {
  const _LostCatBar({required this.onTap});

  final VoidCallback onTap;

  static const _ink = Color(0xFF963721);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFDE6DF),
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: const Row(
            children: [
              Icon(LucideIcons.siren, size: 18, color: _ink),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ประกาศแมวหาย · เห็นน้องไหม?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _ink,
                  ),
                ),
              ),
              Text(
                'แจ้งเบาะแส ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                ),
              ),
              Icon(LucideIcons.chevronRight, size: 16, color: _ink),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.post,
    required this.onToggleFollow,
    required this.onOpenMenu,
  });

  final Post post;
  final VoidCallback onToggleFollow;
  final VoidCallback onOpenMenu;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          AppAvatar(
            source: post.author.avatar,
            bg: post.author.avatarBg,
            size: 36,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.author.handle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (post.subtitle != null)
                  Row(
                    children: [
                      if (post.subtitleHasPin) ...[
                        const Icon(
                          LucideIcons.mapPin,
                          size: 12,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Flexible(
                        child: Text(
                          post.subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          _FollowButton(
            following: post.isFollowingAuthor,
            onTap: onToggleFollow,
          ),
          Semantics(
            button: true,
            label: 'ตัวเลือกเพิ่มเติม',
            child: IconButton(
              onPressed: onOpenMenu,
              icon: const Icon(
                LucideIcons.ellipsis,
                size: 24,
                color: AppColors.text,
              ),
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}

class _FollowButton extends StatelessWidget {
  const _FollowButton({required this.following, required this.onTap});

  final bool following;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: following ? AppColors.btnFollowing : AppColors.btn,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: following ? AppColors.line2 : AppColors.btnBorder,
            width: following ? 1 : 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (following) ...[
              const Icon(LucideIcons.check, size: 14, color: AppColors.text),
              const SizedBox(width: 6),
            ],
            Text(
              following ? 'ติดตามแล้ว' : 'ติดตาม',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: following ? AppColors.text : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Media extends StatelessWidget {
  const _Media({
    required this.post,
    required this.controller,
    required this.index,
    required this.onChanged,
  });

  final Post post;
  final PageController controller;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final count = post.media.length;
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: AppColors.media,
            child: PageView.builder(
              controller: controller,
              itemCount: count,
              onPageChanged: onChanged,
              itemBuilder: (_, i) => post.media[i].isVideo
                  ? AppVideo(
                      source: post.media[i].url,
                      semanticLabel: 'วิดีโอที่ ${i + 1} จาก $count',
                    )
                  : AppImage(
                      source: post.media[i].url,
                      semanticLabel: post.media[i].alt,
                    ),
            ),
          ),
          if (count > 1) ...[
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xB34A3428),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${index + 1}/$count',
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < count; i++)
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == index
                            ? Colors.white
                            : const Color(0x8CFFFFFF),
                        boxShadow: const [
                          BoxShadow(color: Color(0x66000000), blurRadius: 2),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
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
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 6, right: 6),
      child: Row(
        children: [
          _ActionButton(
            label: 'ถูกใจ',
            count: post.likeCount,
            onTap: onToggleLike,
            icon: FillIcon(
              shape: FillIconShape.heart,
              color: likeColor,
              filled: post.isLiked,
            ),
          ),
          _ActionButton(
            label: 'ความคิดเห็น ${post.commentCount} รายการ',
            count: post.commentCount,
            onTap: onOpenComments,
            icon: const Icon(
              LucideIcons.messageCircle,
              size: 24,
              color: AppColors.text,
            ),
          ),
          _ActionButton(
            label: 'แชร์',
            count: post.shareCount,
            onTap: onShare,
            icon: const Icon(LucideIcons.send, size: 24, color: AppColors.text),
          ),
          _ActionButton(
            label: 'บันทึก',
            onTap: onToggleSave,
            icon: FillIcon(
              shape: FillIconShape.bookmark,
              color: AppColors.text,
              filled: post.isSaved,
            ),
          ),
          const Spacer(),
          if (!post.isOwn)
            _ActionButton(
              label: 'เลี้ยงขนม ${post.author.displayName}',
              onTap: onOpenTreats ?? () => onComingSoon('เลี้ยงขนม'),
              icon: const Icon(
                LucideIcons.gift,
                size: 24,
                color: AppColors.text,
              ),
            ),
        ],
      ),
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
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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

class _Body extends StatelessWidget {
  const _Body({required this.post, required this.onOpenComments});

  final Post post;
  final VoidCallback onOpenComments;

  static const _body = TextStyle(
    fontSize: 14,
    height: 1.5,
    color: AppColors.text,
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.likeCount > 0 && post.likedBy.avatars.isNotEmpty)
            Row(
              children: [
                SizedBox(
                  width: 22.0 + (post.likedBy.avatars.length - 1) * 14,
                  height: 22,
                  child: Stack(
                    children: [
                      for (var i = 0; i < post.likedBy.avatars.length; i++)
                        Positioned(
                          left: i * 14.0,
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: AppAvatar(
                              source: post.likedBy.avatars[i].url,
                              bg: post.likedBy.avatars[i].bg,
                              size: 22,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: post.likedBy.handle,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const TextSpan(text: ' และคนอื่น ๆ ถูกใจ'),
                      ],
                    ),
                    style: _body,
                  ),
                ),
              ],
            ),
          if (post.likeCount > 0 && post.likedBy.avatars.isNotEmpty)
            const SizedBox(height: 4),
          _handleAndText(post.author.handle, post.caption),
          for (final c in post.previewComments) ...[
            const SizedBox(height: 4),
            _handleAndText(c.authorHandle, c.body),
          ],
          if (post.commentCount > 0) ...[
            const SizedBox(height: 4),
            GestureDetector(
              onTap: onOpenComments,
              child: Text(
                'ดูความคิดเห็นทั้ง ${post.commentCount} รายการ',
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.muted,
                ),
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            post.postedAgoText,
            style: const TextStyle(
              fontSize: 11,
              height: 1.5,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _handleAndText(String handle, String text) => Text.rich(
    TextSpan(
      children: [
        TextSpan(
          text: handle,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        TextSpan(text: ' $text'),
      ],
    ),
    style: _body,
  );
}

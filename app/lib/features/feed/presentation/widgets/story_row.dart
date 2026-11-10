import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../domain/entities/feed_user.dart';

/// แถวสตอรี่เหนือฟีด — วงแหวนฟ้า = ยังไม่ได้ดู, เทา = ดูแล้ว
class StoryRow extends StatelessWidget {
  const StoryRow({super.key, required this.users});

  final List<FeedUser> users;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.page,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final user in users) ...[
              _Story(user: user),
              if (user != users.last) const SizedBox(width: 14),
            ],
          ],
        ),
      ),
    );
  }
}

class _Story extends StatelessWidget {
  const _Story({required this.user});

  final FeedUser user;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 68,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: user.hasUnseenStory
                    ? const [AppColors.ringUnseenFrom, AppColors.ringUnseenTo]
                    : const [AppColors.unchecked, AppColors.unchecked],
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: AppAvatar(
                source: user.avatar,
                bg: user.avatarBg,
                size: 56,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            user.handle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11.5,
              height: 1.4,
              color: AppColors.text2,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_image.dart';
import '../../domain/entities/search_post.dart';
import '../l10n/search_l10n.dart';

/// การ์ดผลลัพธ์โพสต์ในหน้าค้นหา — ตรงตามเว็บต้นแบบ www.แมว.live/search
class SearchPostCard extends StatelessWidget {
  const SearchPostCard({
    super.key,
    required this.post,
    required this.l10n,
    required this.onTap,
  });

  final SearchPost post;
  final SearchL10n l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final categoryText = l10n.postCategoryLabel(
      post.category,
      post.categoryLabel,
    );
    return Semantics(
      button: true,
      label: '$categoryText ${post.caption}',
      excludeSemantics: true,
      child: Material(
        color: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.thumbnailUrl.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 76,
                      height: 76,
                      child: AppImage(
                        source: post.thumbnailUrl,
                        semanticLabel: post.thumbnailAlt,
                        cacheWidth: 228,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        post.caption,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.35,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${post.authorName} · ${post.timeText}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
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

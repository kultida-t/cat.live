import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// โครงโหลดการ์ดโพสต์ — ใช้แทน spinner ตามมาตรฐานแอป
class PostCardSkeleton extends StatelessWidget {
  const PostCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    Widget bar(double w, double h) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: AppColors.soft,
        borderRadius: BorderRadius.circular(4),
      ),
    );

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.soft,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      bar(112, 14),
                      const SizedBox(height: 6),
                      bar(64, 12),
                    ],
                  ),
                ),
                Container(
                  width: 80,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.soft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
          const AspectRatio(
            aspectRatio: 1,
            child: ColoredBox(color: AppColors.media),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [bar(240, 14), const SizedBox(height: 8), bar(160, 14)],
            ),
          ),
        ],
      ),
    );
  }
}

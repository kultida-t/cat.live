import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// โครงโหลดจำลอง (Skeleton) ของหน้าเมนูหลัก
class MenuSkeleton extends StatelessWidget {
  const MenuSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
      children: [
        _box(width: 80, height: 14),
        const SizedBox(height: 12),
        for (var i = 0; i < 8; i++) ...[
          _box(height: 54, radius: 14),
          const SizedBox(height: 6),
        ],
      ],
    );
  }

  Widget _box({double? width, required double height, double radius = 8}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.soft,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

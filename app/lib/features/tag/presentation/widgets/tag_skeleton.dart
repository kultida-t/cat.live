import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// โครงร่างกำลังโหลด (Skeleton) ของหน้า แมว.live Tag
class TagSkeleton extends StatelessWidget {
  const TagSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
      children: [
        Center(child: _box(width: 96, height: 14, radius: 7)),
        const SizedBox(height: 14),
        Center(child: _box(width: 210, height: 28, radius: 10)),
        const SizedBox(height: 8),
        Center(child: _box(width: 170, height: 28, radius: 10)),
        const SizedBox(height: 28),
        Center(child: _box(width: 170, height: 170, radius: 85)),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            5,
            (_) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _box(width: 36, height: 36, radius: 18),
            ),
          ),
        ),
        const SizedBox(height: 28),
        _box(width: double.infinity, height: 220, radius: 24),
        const SizedBox(height: 18),
        _box(width: double.infinity, height: 130, radius: 22),
      ],
    );
  }

  Widget _box({
    required double width,
    required double height,
    required double radius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.line,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

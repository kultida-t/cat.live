import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// โครงร่างโหลด (Skeleton) ของหน้าค้นหา
class SearchSkeleton extends StatelessWidget {
  const SearchSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: Row(
            children: [
              for (final width in [72.0, 78.0, 68.0, 68.0, 74.0]) ...[
                _Box(width: width, height: 36, radius: 999),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        const _Box(width: 110, height: 18, radius: 8),
        const SizedBox(height: 10),
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Box(width: 76, height: 36, radius: 999),
            _Box(width: 82, height: 36, radius: 999),
            _Box(width: 72, height: 36, radius: 999),
            _Box(width: 96, height: 36, radius: 999),
            _Box(width: 80, height: 36, radius: 999),
          ],
        ),
        const SizedBox(height: 20),
        const _Box(width: 100, height: 18, radius: 8),
        const SizedBox(height: 12),
        for (var i = 0; i < 4; i++) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line),
            ),
            child: const Row(
              children: [
                _Box(width: 76, height: 76, radius: 12),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Box(width: 64, height: 12, radius: 6),
                      SizedBox(height: 8),
                      _Box(width: double.infinity, height: 14, radius: 6),
                      SizedBox(height: 6),
                      _Box(width: 180, height: 14, radius: 6),
                      SizedBox(height: 8),
                      _Box(width: 110, height: 12, radius: 6),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.width, required this.height, required this.radius});

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
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

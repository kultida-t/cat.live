import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// โครงร่างกำลังโหลดของหน้าใกล้ฉัน
class NearbySkeleton extends StatelessWidget {
  const NearbySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(
              4,
              (i) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _Box(width: 78, height: 34, radius: 999),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const AspectRatio(
            aspectRatio: 16 / 8,
            child: _Box(width: double.infinity, height: double.infinity, radius: 20),
          ),
          const SizedBox(height: 14),
          const _Box(width: 220, height: 18, radius: 8),
          const SizedBox(height: 16),
          const _Box(width: 140, height: 20, radius: 8),
          const SizedBox(height: 10),
          const _Box(width: double.infinity, height: 220, radius: 18),
        ],
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({
    required this.width,
    required this.height,
    required this.radius,
  });

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

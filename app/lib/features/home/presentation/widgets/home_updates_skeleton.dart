import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// โครงกระดูกขณะโหลดการ์ดอัปเดตจากชุมชนบนหน้าแรก
class HomeUpdatesSkeleton extends StatelessWidget {
  const HomeUpdatesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: const [
          _SkeletonCard(),
          SizedBox(height: 12),
          _SkeletonCard(),
        ],
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              _Block(width: 36, height: 36, radius: 18),
              SizedBox(width: 10),
              _Block(width: 140, height: 14, radius: 7),
            ],
          ),
          const SizedBox(height: 12),
          const _Block(width: double.infinity, height: 14, radius: 7),
          const SizedBox(height: 8),
          const _Block(width: 210, height: 14, radius: 7),
          const SizedBox(height: 12),
          const AspectRatio(
            aspectRatio: 4 / 3,
            child: _Block(width: double.infinity, height: 200, radius: 14),
          ),
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({
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

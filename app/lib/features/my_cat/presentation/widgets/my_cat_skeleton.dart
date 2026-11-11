import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// โครงกระดูกขณะโหลดหน้าแมวและฉัน (ไม่ใช้ spinner)
class MyCatSkeleton extends StatelessWidget {
  const MyCatSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // แถวสลับโปรไฟล์จำลอง
        Row(
          children: const [
            _Box(width: 78, height: 38, radius: 19),
            SizedBox(width: 8),
            _Box(width: 84, height: 38, radius: 19),
            SizedBox(width: 8),
            _Box(width: 96, height: 38, radius: 19),
          ],
        ),
        const SizedBox(height: 18),
        // รูปโปรไฟล์ + สถิติ
        Row(
          children: [
            const _Box(width: 84, height: 84, radius: 42),
            const SizedBox(width: 16),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  _Box(width: 44, height: 34, radius: 8),
                  _Box(width: 56, height: 34, radius: 8),
                  _Box(width: 44, height: 34, radius: 8),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const _Box(width: 120, height: 18, radius: 9),
        const SizedBox(height: 8),
        const _Box(width: 220, height: 14, radius: 7),
        const SizedBox(height: 16),
        const _Box(width: double.infinity, height: 52, radius: 16),
        const SizedBox(height: 12),
        Row(
          children: const [
            Expanded(
              child: _Box(width: double.infinity, height: 60, radius: 16),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _Box(width: double.infinity, height: 60, radius: 16),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _Box(width: double.infinity, height: 60, radius: 16),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _Box(width: double.infinity, height: 60, radius: 16),
            ),
          ],
        ),
        const SizedBox(height: 18),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
          children: const [
            _Box(width: double.infinity, height: double.infinity, radius: 0),
            _Box(width: double.infinity, height: double.infinity, radius: 0),
            _Box(width: double.infinity, height: double.infinity, radius: 0),
          ],
        ),
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

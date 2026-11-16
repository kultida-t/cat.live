import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// โครงร่างระหว่างโหลดของหน้าตั้งค่าและศูนย์ช่วยเหลือ (/settings)
class SettingsSkeleton extends StatelessWidget {
  const SettingsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        _box(height: 74, radius: 18),
        const SizedBox(height: 18),
        _box(height: 14, width: 120, radius: 7),
        const SizedBox(height: 10),
        _box(height: 120, radius: 18),
        const SizedBox(height: 18),
        _box(height: 14, width: 100, radius: 7),
        const SizedBox(height: 10),
        _box(height: 180, radius: 18),
        const SizedBox(height: 18),
        _box(height: 14, width: 140, radius: 7),
        const SizedBox(height: 10),
        _box(height: 132, radius: 18),
      ],
    );
  }

  Widget _box({required double height, double? width, required double radius}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.soft,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

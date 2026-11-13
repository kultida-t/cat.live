import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// โครงร่างระหว่างโหลดข้อมูลหน้าเลี้ยงขนมแมว
class TreatsSkeleton extends StatelessWidget {
  const TreatsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bar(140, 18),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    5,
                    (_) => Column(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: const BoxDecoration(
                            color: AppColors.soft,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _bar(48, 10),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 270, width: double.infinity, color: AppColors.soft),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [_bar(170, 20), _bar(54, 22)],
                ),
                const SizedBox(height: 14),
                Row(
                  children: List.generate(
                    4,
                    (i) => Expanded(
                      child: Container(
                        height: 56,
                        margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                        decoration: BoxDecoration(
                          color: AppColors.soft,
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _bar(double.infinity, 44, radius: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar(double width, double height, {double radius = 8}) {
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

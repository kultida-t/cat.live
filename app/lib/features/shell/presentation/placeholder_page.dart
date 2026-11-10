import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// หน้าจอที่ยังไม่ได้พอร์ต — แสดงสรุปว่าจอนี้จะมีอะไร
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({
    super.key,
    required this.title,
    required this.subtitle,
    this.notes = const [],
  });

  final String title;
  final String subtitle;
  final List<String> notes;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 16, color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          _Box(
            color: Colors.white,
            radius: 16,
            child: const Text(
              'หน้าจอนี้อยู่ระหว่างพอร์ตจากเว็บ prototype — โครงสร้างแอปพร้อมแล้ว '
              'จะทยอยใส่เนื้อหาจริงทีละจอตาม design-spec',
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: AppColors.text2,
              ),
            ),
          ),
          for (final note in notes) ...[
            const SizedBox(height: 16),
            _Box(
              color: AppColors.soft,
              radius: 12,
              child: Text(
                note,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.text2,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.color, required this.radius, required this.child});

  final Color color;
  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.line),
      ),
      child: child,
    );
  }
}

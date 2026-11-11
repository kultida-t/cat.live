import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_locale.dart';
import '../../../core/theme/app_colors.dart';

/// หน้าจอที่ยังไม่ได้พอร์ต — แสดงสรุปว่าจอนี้จะมีอะไร (รองรับสลับ ไทย / EN)
class PlaceholderPage extends ConsumerWidget {
  const PlaceholderPage({
    super.key,
    required this.title,
    required this.subtitle,
    this.notes = const [],
    this.enTitle,
    this.enSubtitle,
    this.enNotes = const [],
    this.showBack = false,
  });

  final String title;
  final String subtitle;
  final List<String> notes;
  final String? enTitle;
  final String? enSubtitle;
  final List<String> enNotes;
  final bool showBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEn = ref.watch(appLocaleProvider) == 'en';
    final effectiveTitle = isEn ? (enTitle ?? title) : title;
    final effectiveSubtitle = isEn ? (enSubtitle ?? subtitle) : subtitle;
    final effectiveNotes = isEn && enNotes.isNotEmpty ? enNotes : notes;

    final content = SafeArea(
      top: !showBack,
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!showBack) ...[
            Text(
              effectiveTitle,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            effectiveSubtitle,
            style: const TextStyle(fontSize: 16, color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          _Box(
            color: Colors.white,
            radius: 16,
            child: Text(
              isEn
                  ? 'This screen is being ported from the web prototype — the app shell is ready and full content is arriving screen by screen.'
                  : 'หน้าจอนี้อยู่ระหว่างพอร์ตจากเว็บ prototype — โครงสร้างแอปพร้อมแล้ว '
                        'จะทยอยใส่เนื้อหาจริงทีละจอตาม design-spec',
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                color: AppColors.text2,
              ),
            ),
          ),
          for (final note in effectiveNotes) ...[
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
    if (!showBack) return content;
    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: AppBar(
        backgroundColor: AppColors.page,
        surfaceTintColor: Colors.transparent,
        leading: Semantics(
          button: true,
          label: isEn ? 'Back' : 'ย้อนกลับ',
          child: IconButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/my-cat');
              }
            },
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          ),
        ),
        title: Text(
          effectiveTitle,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
      ),
      body: content,
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

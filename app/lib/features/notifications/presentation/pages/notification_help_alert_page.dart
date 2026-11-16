import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/config/app_locale.dart';
import '../../../../core/theme/app_colors.dart';

/// หน้ารายละเอียดประกาศแมวหายใกล้คุณ (/notifications/help)
/// กด < กลับหน้าการแจ้งเตือน หรือกดไปหน้าช่วยเหลือทั้งหมดได้
class NotificationHelpAlertPage extends ConsumerWidget {
  const NotificationHelpAlertPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEn = ref.watch(appLocaleProvider) == 'en';

    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: Column(
          children: [
            _Header(isEn: isEn, onBack: () => context.pop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.quickHelpBg,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: AppColors.quickHelpBorder,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    LucideIcons.triangleAlert,
                                    size: 14,
                                    color: AppColors.quickHelpInk,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    isEn ? 'Lost Cat Alert' : 'ประกาศแมวหาย',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.quickHelpInk,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Text(
                              isEn ? '1h ago' : '1 ชม. ที่แล้ว',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          isEn
                              ? 'Orange cat with blue collar spotted near Ari Soi 4'
                              : 'พบแมวส้มปลอกคอสีฟ้าแถวอารีย์ ซอย 4',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isEn
                              ? 'Reported within 3 km of your current area. If you recognize this cat or have any sightings, please submit a tip on the Help board.'
                              : 'แจ้งเตือนในรัศมี 3 กม. จากพื้นที่ของคุณ หากพบเห็นหรือคุ้นหน้าน้องแมวตัวนี้ สามารถกดไปแจ้งเบาะแสในหน้าช่วยเหลือได้ทันที',
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: AppColors.text2,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Row(
                          children: [
                            Icon(
                              LucideIcons.mapPin,
                              size: 16,
                              color: AppColors.muted,
                            ),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'อารีย์ ซอย 4 · รัศมี 3 กม.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.muted,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () {
                              context.pop();
                              context.go('/help');
                            },
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 46),
                              backgroundColor: AppColors.btn,
                              foregroundColor: AppColors.ink,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(
                                  color: AppColors.btnBorder,
                                ),
                              ),
                            ),
                            child: Text(
                              isEn
                                  ? 'Open Help Board'
                                  : 'ไปที่หน้าช่วยเหลือเพื่อแจ้งเบาะแส',
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.isEn, required this.onBack});

  final bool isEn;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 12, 8),
      decoration: const BoxDecoration(
        color: AppColors.page,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: isEn ? 'Back' : 'ย้อนกลับ',
            excludeSemantics: true,
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(14),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  LucideIcons.chevronLeft,
                  size: 24,
                  color: AppColors.text,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              isEn ? 'Nearby Alert' : 'ประกาศใกล้คุณ',
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

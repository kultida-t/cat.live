import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/config/pet_species_config.dart';
import '../../../../core/router/auth_routes.dart';
import '../../../../core/theme/app_colors.dart';

/// ชีตชวนเข้าสู่ระบบเมื่อผู้ใช้ในโหมดผู้เยี่ยมชม (Guest) แตะฟีเจอร์ที่ต้องอ้างอิงตัวตน
/// `returnTo` = ปลายทางหลังล็อกอินสำเร็จ (AUTH-02) — ถ้าไม่ส่งจะกลับหน้าที่เปิดชีตอยู่
Future<void> showGuestAuthSheet(
  BuildContext context, {
  required PetSpeciesConfig species,
  required bool isEn,
  String? actionName,
  String? returnTo,
}) {
  final featureLabel = actionName ?? (isEn ? 'this feature' : 'ฟีเจอร์นี้');
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line2,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: Image.asset(
                'assets/brand/maew-logo.png',
                height: 42,
                semanticLabel: species.brandName(isEn),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isEn
                  ? 'Sign in to use $featureLabel'
                  : 'เข้าสู่ระบบเพื่อใช้งาน\n$featureLabel',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.page,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                children: [
                  _BenefitRow(
                    icon: LucideIcons.heartHandshake,
                    text: isEn
                        ? 'Save ${species.petNoun(true).toLowerCase()} profiles & health records'
                        : 'บันทึกโปรไฟล์และสมุดสุขภาพ${species.petNoun(false)}',
                  ),
                  const SizedBox(height: 8),
                  _BenefitRow(
                    icon: LucideIcons.bellRing,
                    text: isEn
                        ? 'Get missing-pet & vaccine reminders'
                        : 'รับแจ้งเตือนวัคซีนและประกาศสัตว์เลี้ยงหาย',
                  ),
                  const SizedBox(height: 8),
                  _BenefitRow(
                    icon: LucideIcons.messageSquareHeart,
                    text: isEn
                        ? 'Post, comment & chat with the community'
                        : 'โพสต์ แสดงความเห็น และแชทกับชุมชน',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.push(
                  loginLocation(
                    returnTo: returnTo ?? currentAppLocation(context),
                    register: true,
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.ownerTeal,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                isEn ? 'Sign in / Register' : 'เข้าสู่ระบบ / สมัครสมาชิก',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                isEn ? 'Continue browsing as Guest' : 'ดูต่อแบบผู้เยี่ยมชม',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.ownerTeal),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
        ),
      ],
    );
  }
}

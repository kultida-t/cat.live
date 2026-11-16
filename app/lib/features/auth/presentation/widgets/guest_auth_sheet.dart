import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/config/pet_species_config.dart';
import '../../../../core/theme/app_colors.dart';

/// ชีตแจ้งเตือนเมื่อผู้ใช้ในโหมดผู้เยี่ยมชม (Guest) แตะฟีเจอร์ที่ต้องเข้าสู่ระบบก่อน
Future<void> showGuestAuthSheet(
  BuildContext context, {
  required PetSpeciesConfig species,
  required bool isEn,
  String? actionName,
}) {
  final actionText = actionName ?? (isEn ? 'this feature' : 'ฟีเจอร์นี้');
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
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
            const SizedBox(height: 16),
            const Icon(
              LucideIcons.lock,
              size: 32,
              color: AppColors.ownerTeal,
            ),
            const SizedBox(height: 10),
            Text(
              isEn
                  ? 'Sign in to use $actionText'
                  : 'เข้าสู่ระบบเพื่อใช้งาน $actionText',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isEn
                  ? 'You are currently in Guest Mode on ${species.brandName(true)}. Sign in with Phone/OTP, Apple, Google, or LINE.'
                  : 'คุณกำลังใช้งานแบบผู้เยี่ยมชมบน ${species.brandName(false)} เข้าสู่ระบบด้วยเบอร์โทร/OTP, Apple, Google หรือ LINE ได้ทันที',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.muted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.push('/login');
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
            const SizedBox(height: 8),
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

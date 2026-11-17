import 'package:flutter/material.dart';

import '../../../../core/config/pet_species_config.dart';
import '../../../../core/theme/app_colors.dart';

/// การ์ดกลางจอสำหรับหน้าที่ผู้เยี่ยมชม (Guest) เข้าไม่ได้ — ใช้กันคนหลุดเข้าทาง deep link
/// มีโลโก้ ข้อความอธิบาย และปุ่มพาไปเข้าสู่ระบบ/สมัครสมาชิก
class GuestLockedView extends StatelessWidget {
  const GuestLockedView({
    super.key,
    required this.species,
    required this.isEn,
    required this.title,
    required this.subtitle,
    required this.onSignInTap,
  });

  final PetSpeciesConfig species;
  final bool isEn;
  final String title;
  final String subtitle;
  final VoidCallback onSignInTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/brand/maew-logo.png',
                height: 42,
                semanticLabel: species.brandName(isEn),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.muted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onSignInTap,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

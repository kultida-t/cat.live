import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

/// แถบด้านบนหน้าแมวและฉัน — พื้น #FFFBF5 ไม่มีขอบล่าง, ปุ่มซ้าย "สร้าง" ปุ่มขวา "ตั้งค่า"
class MyCatHeader extends StatelessWidget {
  const MyCatHeader({
    super.key,
    required this.title,
    required this.onCreateTap,
    required this.onSettingsTap,
    this.isEn = false,
  });

  final String title;
  final VoidCallback onCreateTap;
  final VoidCallback onSettingsTap;
  final bool isEn;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.page,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
        child: Row(
          children: [
            _HeaderIconButton(
              label: isEn
                  ? 'Create · upload a photo or video'
                  : 'สร้าง · อัปโหลดรูปหรือวิดีโอ',
              icon: LucideIcons.plus,
              onTap: onCreateTap,
            ),
            Expanded(
              child: Center(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              ),
            ),
            _HeaderIconButton(
              label: isEn ? 'Settings' : 'ตั้งค่า',
              icon: LucideIcons.settings,
              onTap: onSettingsTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(child: Icon(icon, size: 24, color: AppColors.text)),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

/// หัวหน้าแรก: เมนู + ค้นหา + โลโก้ + แจ้งเตือน + ข้อความ (พื้น #FFFBF5 ไม่มีขอบล่าง)
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, required this.onComingSoon});

  final ValueChanged<String> onComingSoon;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.page,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
        child: Row(
          children: [
            _HeaderButton(
              label: 'เปิดเมนู',
              icon: LucideIcons.menu,
              onTap: () => onComingSoon('เมนู'),
            ),
            _HeaderButton(
              label: 'ค้นหา',
              icon: LucideIcons.search,
              onTap: () => onComingSoon('ค้นหา'),
            ),
            Expanded(
              child: Center(
                child: Image.asset(
                  'assets/brand/maew-logo.png',
                  width: 123,
                  height: 36,
                  semanticLabel: 'แมว.live',
                ),
              ),
            ),
            _HeaderButton(
              label: 'การแจ้งเตือน 3 รายการใหม่',
              icon: LucideIcons.bell,
              dotRight: 10,
              onTap: () => onComingSoon('การแจ้งเตือน'),
            ),
            _HeaderButton(
              label: 'ข้อความ 3 รายการยังไม่อ่าน',
              icon: LucideIcons.messageCircleHeart,
              dotRight: 8,
              onTap: () => onComingSoon('ข้อความ'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.dotRight,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final double? dotRight;

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
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, size: 24, color: AppColors.text),
              if (dotRight != null)
                Positioned(
                  top: 10,
                  right: dotRight,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.heart,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
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

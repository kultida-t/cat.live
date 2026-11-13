import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/feed_tab.dart';

/// หัวหน้าฟีด: แถบไอคอน + โลโก้ + แท็บ ทั้งหมด/ติดตาม/บันทึกไว้
class FeedHeader extends StatelessWidget {
  const FeedHeader({
    super.key,
    required this.tab,
    required this.onTabChanged,
    required this.onComingSoon,
    required this.onCreatePost,
    this.onOpenMenu,
  });

  final FeedTab tab;
  final ValueChanged<FeedTab> onTabChanged;
  final ValueChanged<String> onComingSoon;
  final VoidCallback onCreatePost;
  final VoidCallback? onOpenMenu;

  static const _labels = {
    FeedTab.all: 'ทั้งหมด',
    FeedTab.following: 'ติดตาม',
    FeedTab.saved: 'บันทึกไว้',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
          child: Row(
            children: [
              _HeaderButton(
                label: 'เปิดเมนู',
                icon: LucideIcons.menu,
                onTap: onOpenMenu ?? () => onComingSoon('เมนู'),
              ),
              _HeaderButton(
                label: 'สร้างโพสต์ รูปหรือวิดีโอ',
                icon: LucideIcons.squarePlus,
                onTap: onCreatePost,
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
        Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.line)),
          ),
          child: Row(
            children: [
              for (final t in FeedTab.values)
                Expanded(
                  child: _TabButton(
                    label: _labels[t]!,
                    active: t == tab,
                    onTap: () => onTabChanged(t),
                  ),
                ),
            ],
          ),
        ),
      ],
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
        borderRadius: BorderRadius.circular(12),
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

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? AppColors.text : AppColors.muted,
                ),
              ),
              if (active)
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 0,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(999),
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

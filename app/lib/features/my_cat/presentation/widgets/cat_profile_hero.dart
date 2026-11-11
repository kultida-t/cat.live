import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../domain/entities/my_cat_data.dart';
import 'my_cat_l10n.dart';

/// ส่วนบนโปรไฟล์แมว: รูป 84px + สถิติ 3 ช่อง + ชื่อ/สายพันธุ์ + ปุ่มสมุดสุขภาพและ 4 ปุ่มย่อย
class CatProfileHero extends StatelessWidget {
  const CatProfileHero({
    super.key,
    required this.cat,
    required this.onOpenHealth,
    required this.onOpenCatId,
    required this.onOpenTracker,
    required this.onShare,
    required this.onEdit,
    this.isEn = false,
  });

  final CatProfile cat;
  final VoidCallback onOpenHealth;
  final VoidCallback onOpenCatId;
  final VoidCallback onOpenTracker;
  final VoidCallback onShare;
  final VoidCallback onEdit;
  final bool isEn;

  Color? get _trackerDotColor {
    return switch (cat.trackerStatus) {
      CatTrackerStatus.safe => AppColors.statusSafe,
      CatTrackerStatus.outOfZone => AppColors.heart,
      CatTrackerStatus.noCollar => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GradientAvatar(
                source: cat.avatarSource,
                bg: cat.avatarBg,
                size: 84,
                gradientColors: const [
                  AppColors.catRingStart,
                  AppColors.catRingMid,
                  AppColors.catRingEnd,
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _CatStat(
                        value: MyCatL10n.age(cat.ageLabel, isEn),
                        label: isEn ? 'Age' : 'อายุ',
                      ),
                    ),
                    Expanded(
                      child: _CatStat(
                        value: cat.weightText,
                        label: isEn ? 'Weight kg' : 'น้ำหนัก กก.',
                      ),
                    ),
                    Expanded(
                      child: _CatStat(
                        value: '${cat.recordCount}',
                        label: isEn ? 'Saved' : 'บันทึก',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            MyCatL10n.catName(cat.name, isEn),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            MyCatL10n.catSummary(cat, isEn),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            isEn
                ? '@${cat.publicId} · adopted ${cat.adoptedYear}'
                : '@${cat.publicId} · รับเลี้ยงตั้งแต่ ${cat.adoptedYear}',
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 14),
          // ปุ่มเด่นเต็มความกว้าง: สมุดสุขภาพ
          Semantics(
            button: true,
            label: 'สมุดสุขภาพ',
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.btn,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.btnBorder, width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x28A0643C),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onOpenHealth,
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 52,
                    width: double.infinity,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          LucideIcons.heartPulse,
                          size: 20,
                          color: AppColors.text,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isEn ? 'Health book' : 'สมุดสุขภาพ',
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionTile(
                  label: 'Cat ID',
                  semanticLabel: 'Cat ID ของ ${cat.name}',
                  icon: LucideIcons.idCard,
                  onTap: onOpenCatId,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionTile(
                  label: isEn ? 'Find' : 'ตามหา',
                  semanticLabel: isEn
                      ? 'Find ${MyCatL10n.catName(cat.name, true)} · ${MyCatL10n.trackerLabel(cat.trackerStatus, cat.trackerLabel, true)}'
                      : 'ตามหา ${cat.name} · ${cat.trackerLabel}',
                  icon: LucideIcons.mapPin,
                  statusDotColor: _trackerDotColor,
                  onTap: onOpenTracker,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionTile(
                  label: isEn ? 'Share' : 'แชร์',
                  semanticLabel: 'แชร์โปรไฟล์ ${cat.name}',
                  icon: LucideIcons.share2,
                  onTap: onShare,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionTile(
                  label: isEn ? 'Edit' : 'แก้ไข',
                  semanticLabel: 'แก้ไขโปรไฟล์ ${cat.name}',
                  icon: LucideIcons.notebookPen,
                  onTap: onEdit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CatStat extends StatelessWidget {
  const _CatStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.label,
    required this.semanticLabel,
    required this.icon,
    required this.onTap,
    this.statusDotColor,
  });

  final String label;
  final String semanticLabel;
  final IconData icon;
  final VoidCallback onTap;
  final Color? statusDotColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D4A3428),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 60,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Icon(icon, size: 20, color: AppColors.text),
                        if (statusDotColor != null)
                          Positioned(
                            top: -2,
                            right: -4,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: statusDotColor,
                                border: Border.all(
                                  color: AppColors.card,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

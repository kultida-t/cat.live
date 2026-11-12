import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/nearby_data.dart';
import 'nearby_l10n.dart';

/// แถบปุ่มหมวดหมู่เลื่อนข้างพร้อมเฟดจางขอบขวา (ไม่มีปุ่มลูกศรทับแถบ)
class NearbyCategoryChips extends StatelessWidget {
  const NearbyCategoryChips({
    super.key,
    required this.selectedCategory,
    required this.isEn,
    required this.onToggleCategory,
  });

  final NearbyCategory? selectedCategory;
  final bool isEn;
  final ValueChanged<NearbyCategory> onToggleCategory;

  IconData _iconFor(NearbyCategory category) {
    return switch (category) {
      NearbyCategory.cafe => LucideIcons.coffee,
      NearbyCategory.clinic => LucideIcons.hospital,
      NearbyCategory.shop => LucideIcons.shoppingBag,
      NearbyCategory.announcements => LucideIcons.megaphone,
      NearbyCategory.grooming => LucideIcons.scissors,
      NearbyCategory.boarding => LucideIcons.bedDouble,
    };
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Colors.white, Colors.white, Colors.transparent],
          stops: [0.0, 0.9, 1.0],
        ).createShader(bounds),
        blendMode: BlendMode.dstIn,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: NearbyCategory.values.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final category = NearbyCategory.values[index];
            final isActive = selectedCategory == category;
            return Semantics(
              button: true,
              toggled: isActive,
              child: InkWell(
                key: Key('nearby-chip-${category.name}'),
                onTap: () => onToggleCategory(category),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.btn : AppColors.card,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isActive ? AppColors.btnBorder : AppColors.line,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _iconFor(category),
                        size: 15,
                        color: isActive ? AppColors.ink : AppColors.text,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        NearbyL10n.categoryLabel(category, isEn),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isActive ? AppColors.ink : AppColors.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

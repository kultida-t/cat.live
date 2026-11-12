import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import 'help_l10n.dart';

/// ชีตตั้งค่าช่วยเหลือ — รัศมีประกาศ (2/5/10 กม.) + แจ้งเตือนประกาศใหม่ใกล้ฉัน
Future<void> showHelpFilterSheet({
  required BuildContext context,
  required int radiusKm,
  required bool notifyNearbyPosts,
  required bool isEn,
  required ValueChanged<int> onSelectRadius,
  required ValueChanged<bool> onToggleNotify,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.sheetBarrier,
    builder: (sheetCtx) {
      var currentRadius = radiusKm;
      var currentNotify = notifyNearbyPosts;

      return StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(ctx).viewPadding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.line2,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      HelpL10n.filterSheetTitle(isEn),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2C1810),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(sheetCtx),
                    icon: const Icon(LucideIcons.x, size: 20),
                    color: AppColors.text,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                HelpL10n.radiusTitle(isEn),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final km in [2, 5, 10]) ...[
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setModalState(() => currentRadius = km);
                          onSelectRadius(km);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: currentRadius == km
                                ? AppColors.btn
                                : AppColors.card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: currentRadius == km
                                  ? AppColors.btnBorder
                                  : AppColors.line2,
                              width: currentRadius == km ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            isEn ? '$km km' : '$km กม.',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: currentRadius == km
                                  ? AppColors.text
                                  : AppColors.muted,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (km != 10) const SizedBox(width: 8),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              Material(
                type: MaterialType.transparency,
                child: SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    HelpL10n.notifyNearbyTitle(isEn),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2C1810),
                    ),
                  ),
                  subtitle: Text(
                    HelpL10n.notifyNearbySub(isEn),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                  value: currentNotify,
                  activeTrackColor: const Color(0xFF3D2314),
                  onChanged: (v) {
                    setModalState(() => currentNotify = v);
                    onToggleNotify(v);
                  },
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(sheetCtx),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.btn,
                    foregroundColor: AppColors.text,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.btnBorder),
                    ),
                  ),
                  child: Text(
                    HelpL10n.doneButton(isEn),
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
      );
    },
  );
}

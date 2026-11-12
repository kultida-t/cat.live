import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/nearby_data.dart';
import 'nearby_l10n.dart';

/// แผ่นตั้งค่าใกล้ฉัน: เลือกพื้นที่, รัศมีค้นหา (1/3/5 กม.) และสวิตช์แสดงประกาศแมวบนแผนที่
Future<void> showNearbySettingsSheet({
  required BuildContext context,
  required NearbyAreaId selectedArea,
  required int radiusKm,
  required bool showAnnouncementsOnMap,
  required bool isEn,
  required ValueChanged<NearbyAreaId> onSelectArea,
  required ValueChanged<int> onSelectRadius,
  required ValueChanged<bool> onToggleShowAnnouncements,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    barrierColor: AppColors.sheetBarrier,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _NearbySettingsSheetBody(
      initialArea: selectedArea,
      initialRadius: radiusKm,
      initialShowAnnouncements: showAnnouncementsOnMap,
      isEn: isEn,
      onSelectArea: onSelectArea,
      onSelectRadius: onSelectRadius,
      onToggleShowAnnouncements: onToggleShowAnnouncements,
    ),
  );
}

class _NearbySettingsSheetBody extends StatefulWidget {
  const _NearbySettingsSheetBody({
    required this.initialArea,
    required this.initialRadius,
    required this.initialShowAnnouncements,
    required this.isEn,
    required this.onSelectArea,
    required this.onSelectRadius,
    required this.onToggleShowAnnouncements,
  });

  final NearbyAreaId initialArea;
  final int initialRadius;
  final bool initialShowAnnouncements;
  final bool isEn;
  final ValueChanged<NearbyAreaId> onSelectArea;
  final ValueChanged<int> onSelectRadius;
  final ValueChanged<bool> onToggleShowAnnouncements;

  @override
  State<_NearbySettingsSheetBody> createState() =>
      _NearbySettingsSheetBodyState();
}

class _NearbySettingsSheetBodyState extends State<_NearbySettingsSheetBody> {
  late NearbyAreaId _area = widget.initialArea;
  late int _radius = widget.initialRadius;
  late bool _showAnnouncements = widget.initialShowAnnouncements;

  @override
  Widget build(BuildContext context) {
    final isEn = widget.isEn;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
                    NearbyL10n.settingsLabel(isEn),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  customBorder: const CircleBorder(),
                  child: const SizedBox(
                    width: 34,
                    height: 34,
                    child: Icon(
                      LucideIcons.x,
                      size: 18,
                      color: AppColors.muted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              NearbyL10n.settingsAreaHeader(isEn),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: NearbyAreaId.values.map((area) {
                final active = _area == area;
                final isMyLoc = area == NearbyAreaId.myLocation;
                final label = isMyLoc
                    ? (isEn ? 'My location' : 'ตำแหน่งของฉัน')
                    : NearbyL10n.areaOptionLabel(area, isEn);
                return InkWell(
                  onTap: () {
                    setState(() => _area = area);
                    widget.onSelectArea(area);
                  },
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: active ? AppColors.btn : AppColors.card,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: active ? AppColors.btnBorder : AppColors.line,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isMyLoc) ...[
                          Icon(
                            LucideIcons.locateFixed,
                            size: 14,
                            color: active ? AppColors.ink : AppColors.text,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: active ? AppColors.ink : AppColors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            Text(
              NearbyL10n.settingsRadiusHeader(isEn),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [1, 3, 5].map((km) {
                final active = _radius == km;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: km == 5 ? 0 : 8),
                    child: InkWell(
                      key: Key('nearby-settings-radius-$km'),
                      onTap: () {
                        setState(() => _radius = km);
                        widget.onSelectRadius(km);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: active ? AppColors.btn : AppColors.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: active
                                ? AppColors.btnBorder
                                : AppColors.line,
                          ),
                        ),
                        child: Text(
                          NearbyL10n.radiusOption(km, isEn),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: active ? AppColors.ink : AppColors.text,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        NearbyL10n.settingsShowAnnouncementsTitle(isEn),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        NearbyL10n.settingsShowAnnouncementsSub(isEn),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Switch.adaptive(
                  key: const Key('nearby-settings-announcements-switch'),
                  value: _showAnnouncements,
                  activeTrackColor: AppColors.text,
                  onChanged: (val) {
                    setState(() => _showAnnouncements = val);
                    widget.onToggleShowAnnouncements(val);
                  },
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.btn,
                  foregroundColor: AppColors.ink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppColors.btnBorder),
                  ),
                ),
                child: Text(
                  NearbyL10n.doneBtn(isEn),
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
  }
}

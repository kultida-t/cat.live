import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/nearby_data.dart';
import 'nearby_l10n.dart';

/// ส่วนหัวหน้าใกล้ฉัน: โลโก้ + ปุ่มตั้งค่า, หัวข้อ, ตัวเลือกพื้นที่/รัศมี และช่องค้นหา
class NearbyHeader extends StatelessWidget {
  const NearbyHeader({
    super.key,
    required this.selectedArea,
    required this.hasRealLocation,
    required this.radiusKm,
    required this.searchController,
    required this.isEn,
    required this.onOpenSettings,
    required this.onSelectArea,
    required this.onCycleRadius,
    required this.onSearchChanged,
  });

  final NearbyAreaId selectedArea;
  final bool hasRealLocation;
  final int radiusKm;
  final TextEditingController searchController;
  final bool isEn;
  final VoidCallback onOpenSettings;
  final ValueChanged<NearbyAreaId> onSelectArea;
  final VoidCallback onCycleRadius;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.page,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SizedBox(width: 44, height: 44),
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
                Semantics(
                  button: true,
                  label: NearbyL10n.settingsLabel(isEn),
                  child: InkWell(
                    onTap: onOpenSettings,
                    borderRadius: BorderRadius.circular(12),
                    child: const SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(
                        LucideIcons.settings2,
                        size: 24,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              NearbyL10n.title(isEn),
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                height: 1.2,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _AreaDropdownButton(
                  selectedArea: selectedArea,
                  hasRealLocation: hasRealLocation,
                  isEn: isEn,
                  onSelectArea: onSelectArea,
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 1,
                  height: 20,
                  color: AppColors.line2,
                ),
                InkWell(
                  key: const Key('nearby-radius-cycle'),
                  onTap: onCycleRadius,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          NearbyL10n.radiusPill(radiusKm, isEn),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          LucideIcons.chevronDown,
                          size: 16,
                          color: AppColors.muted,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(minHeight: 44),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line2),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.search,
                    size: 20,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      key: const Key('nearby-search-input'),
                      controller: searchController,
                      onChanged: onSearchChanged,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.text,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: NearbyL10n.searchHint(isEn),
                        hintStyle: const TextStyle(
                          fontSize: 15,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  ),
                  if (searchController.text.isNotEmpty)
                    InkWell(
                      onTap: () {
                        searchController.clear();
                        onSearchChanged('');
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          LucideIcons.x,
                          size: 16,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AreaDropdownButton extends StatefulWidget {
  const _AreaDropdownButton({
    required this.selectedArea,
    required this.hasRealLocation,
    required this.isEn,
    required this.onSelectArea,
  });

  final NearbyAreaId selectedArea;
  final bool hasRealLocation;
  final bool isEn;
  final ValueChanged<NearbyAreaId> onSelectArea;

  @override
  State<_AreaDropdownButton> createState() => _AreaDropdownButtonState();
}

class _AreaDropdownButtonState extends State<_AreaDropdownButton> {
  final GlobalKey _triggerKey = GlobalKey();
  bool _isOpen = false;

  Future<void> _openAreaMenu() async {
    final renderBox =
        _triggerKey.currentContext?.findRenderObject() as RenderBox?;
    final topOffset = renderBox != null
        ? renderBox.localToGlobal(Offset.zero).dy + renderBox.size.height + 6
        : 140.0;

    setState(() => _isOpen = true);
    final picked = await showGeneralDialog<NearbyAreaId>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'area-menu',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 140),
      pageBuilder: (ctx, _, _) {
        return Stack(
          children: [
            Positioned(
              top: topOffset,
              left: 16,
              right: 16,
              child: Material(
                color: AppColors.card,
                elevation: 10,
                shadowColor: const Color(0x284A3428),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAreaRow(
                        ctx,
                        NearbyAreaId.myLocation,
                        isMyLocation: true,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
                        child: Text(
                          NearbyL10n.otherAreasSubheader(widget.isEn),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                      _buildAreaRow(ctx, NearbyAreaId.ari),
                      _buildAreaRow(ctx, NearbyAreaId.thonglor),
                      _buildAreaRow(ctx, NearbyAreaId.latPhrao71),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    if (mounted) {
      setState(() => _isOpen = false);
      if (picked != null) {
        widget.onSelectArea(picked);
      }
    }
  }

  Widget _buildAreaRow(
    BuildContext ctx,
    NearbyAreaId area, {
    bool isMyLocation = false,
  }) {
    final isSelected = widget.selectedArea == area;
    final bgColor = !isSelected
        ? Colors.transparent
        : (isMyLocation ? AppColors.nearbyAreaSelectedBg : AppColors.soft);
    return InkWell(
      onTap: () => Navigator.of(ctx).pop(area),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              isMyLocation ? LucideIcons.locateFixed : LucideIcons.mapPin,
              size: 18,
              color: isMyLocation ? AppColors.trackerSafeTeal : AppColors.muted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    NearbyL10n.areaOptionLabel(area, widget.isEn),
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: isMyLocation || isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    NearbyL10n.areaSubtitle(area, widget.isEn),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const Key('nearby-area-menu'),
      onTap: _openAreaMenu,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        key: _triggerKey,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.selectedArea == NearbyAreaId.myLocation
                  ? LucideIcons.locateFixed
                  : LucideIcons.mapPin,
              size: 18,
              color: AppColors.ink,
            ),
            const SizedBox(width: 6),
            Text(
              NearbyL10n.areaTriggerLabel(
                widget.selectedArea,
                widget.isEn,
                hasRealLocation: widget.hasRealLocation,
              ),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              _isOpen ? LucideIcons.chevronUp : LucideIcons.chevronDown,
              size: 16,
              color: AppColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/my_cat_data.dart';
import 'cat_tracker_sheet.dart';
import 'my_cat_l10n.dart';

/// แผงตั้งค่าอุปกรณ์ (?device=1 หรือกดปุ่มเฟืองขวาบน)
class CatTrackerDevicePanel extends StatefulWidget {
  const CatTrackerDevicePanel({
    super.key,
    required this.cats,
    required this.selectedTagCatId,
    required this.backTargetName,
    required this.isEn,
    required this.onBackToTracker,
    required this.onSelectTagCat,
    required this.onUpdateDevice,
    required this.onBuyTagForCat,
    required this.onNotify,
  });

  final List<CatProfile> cats;
  final String? selectedTagCatId;
  final String? backTargetName;
  final bool isEn;
  final VoidCallback onBackToTracker;
  final ValueChanged<String?> onSelectTagCat;
  final void Function(String catId, CatTrackerDevice Function(CatTrackerDevice))
  onUpdateDevice;
  final ValueChanged<CatProfile> onBuyTagForCat;
  final ValueChanged<String> onNotify;

  @override
  State<CatTrackerDevicePanel> createState() => _CatTrackerDevicePanelState();
}

class _CatTrackerDevicePanelState extends State<CatTrackerDevicePanel> {
  bool _addExpanded = false;
  String? _selectedAddCatId;
  bool _confirmDisconnect = false;

  @override
  void didUpdateWidget(covariant CatTrackerDevicePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedTagCatId != oldWidget.selectedTagCatId) {
      _confirmDisconnect = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final taggedCats = widget.cats
        .where((c) => c.trackerInfo.hasTag && c.trackerInfo.device != null)
        .toList();

    final detailCat = widget.selectedTagCatId == null
        ? null
        : taggedCats.where((c) => c.id == widget.selectedTagCatId).firstOrNull;

    if (detailCat != null) {
      return _DeviceTagDetailView(
        cat: detailCat,
        device: detailCat.trackerInfo.device!,
        isEn: widget.isEn,
        confirmDisconnect: _confirmDisconnect,
        onBack: () => widget.onSelectTagCat(null),
        onUpdateDevice: (updater) =>
            widget.onUpdateDevice(detailCat.id, updater),
        onRequestDisconnect: () => setState(() => _confirmDisconnect = true),
        onCancelDisconnect: () => setState(() => _confirmDisconnect = false),
        onConfirmDisconnect: () {
          setState(() => _confirmDisconnect = false);
          widget.onNotify(
            widget.isEn
                ? 'Disconnected (demo)'
                : 'ยกเลิกการเชื่อมต่อแล้ว (จำลอง)',
          );
        },
        onNotify: widget.onNotify,
      );
    }

    final backTarget = widget.backTargetName != null
        ? MyCatL10n.catName(widget.backTargetName!, widget.isEn)
        : (widget.isEn ? 'My cats' : 'แมวของฉัน');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Semantics(
              button: true,
              label: widget.isEn
                  ? 'Back to $backTarget'
                  : 'กลับไปที่$backTarget',
              child: InkWell(
                onTap: widget.onBackToTracker,
                borderRadius: BorderRadius.circular(14),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    LucideIcons.chevronLeft,
                    size: 22,
                    color: AppColors.text,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                widget.isEn ? 'Device settings' : 'ตั้งค่าอุปกรณ์',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // การ์ดแท็กของฉัน (ตามเว็บจริง: หัวข้อสีเข้ม ไม่มีเส้นคั่นระหว่างแถว มีไอคอนหัวแมว + แบต)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.soft,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isEn
                    ? 'My tags · ${taggedCats.length} pcs'
                    : 'แท็กของฉัน · ${taggedCats.length} ชิ้น',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),
              for (final cat in taggedCats)
                _MyTagListRow(
                  cat: cat,
                  isEn: widget.isEn,
                  onTap: () => widget.onSelectTagCat(cat.id),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // การ์ดเพิ่มอุปกรณ์ (Accordion)
        _AddDeviceAccordionCard(
          cats: widget.cats,
          expanded: _addExpanded,
          selectedCatId: _selectedAddCatId,
          isEn: widget.isEn,
          onToggleExpanded: () => setState(() => _addExpanded = !_addExpanded),
          onSelectCat: (catId) => setState(() => _selectedAddCatId = catId),
          onBuyTag: () {
            final target = widget.cats
                .where((c) => c.id == _selectedAddCatId)
                .firstOrNull;
            if (target != null) widget.onBuyTagForCat(target);
          },
        ),
      ],
    );
  }
}

class _MyTagListRow extends StatelessWidget {
  const _MyTagListRow({
    required this.cat,
    required this.isEn,
    required this.onTap,
  });

  final CatProfile cat;
  final bool isEn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final info = cat.trackerInfo;
    final device = info.device!;
    final name = MyCatL10n.catName(cat.name, isEn);
    final lowBattery = info.batteryPercent <= 25;
    final batteryColor = lowBattery ? AppColors.danger : AppColors.muted;

    return Semantics(
      button: true,
      excludeSemantics: true,
      label: isEn
          ? 'Tag ${device.tagNumber}, $name, battery ${info.batteryPercent}%'
          : 'แท็ก ${device.tagNumber} $name แบต ${info.batteryPercent}%',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: _CollarCatTagSvg(
                  colorHex: device.collarColorHex,
                  tagNumber: device.tagNumber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
              ),
              Icon(
                lowBattery ? LucideIcons.batteryLow : LucideIcons.batteryMedium,
                size: 18,
                color: batteryColor,
              ),
              const SizedBox(width: 4),
              Text(
                '${info.batteryPercent}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: batteryColor,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                LucideIcons.chevronRight,
                size: 20,
                color: AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CollarCatTagSvg extends StatelessWidget {
  const _CollarCatTagSvg({required this.colorHex, required this.tagNumber});

  final int colorHex;
  final int tagNumber;

  @override
  Widget build(BuildContext context) {
    final hex =
        '#${(colorHex & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
    final id = 'tag$tagNumber';
    final svg =
        '''
<svg xmlns="http://www.w3.org/2000/svg" width="40" height="40" viewBox="0 0 160 160">
  <defs>
    <linearGradient id="$id-g" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#FFFFFF" stop-opacity="0.25"/>
      <stop offset="50%" stop-color="#FFFFFF" stop-opacity="0"/>
      <stop offset="100%" stop-color="#000000" stop-opacity="0.18"/>
    </linearGradient>
    <radialGradient id="$id-f" cx="42%" cy="36%" r="65%">
      <stop offset="0%" stop-color="#FFFFFF"/>
      <stop offset="100%" stop-color="#E9F1EF"/>
    </radialGradient>
  </defs>
  <rect x="0" y="14" width="160" height="30" fill="$hex" stroke="#000000" stroke-opacity="0.1"/>
  <rect x="0" y="14" width="160" height="30" fill="url(#$id-g)"/>
  <path d="M0 18 H160 M0 40 H160" stroke="#FFFFFF" stroke-opacity="0.45" stroke-dasharray="3 3" fill="none"/>
  <path d="M36 62 L40 34 Q42 28 48 32 L64 44 Q80 40 96 44 L112 32 Q118 28 120 34 L124 62 Q130 78 126 96 Q118 130 80 132 Q42 130 34 96 Q30 78 36 62 Z" fill="$hex" stroke="#000000" stroke-opacity="0.1"/>
  <path d="M36 62 L40 34 Q42 28 48 32 L64 44 Q80 40 96 44 L112 32 Q118 28 120 34 L124 62 Q130 78 126 96 Q118 130 80 132 Q42 130 34 96 Q30 78 36 62 Z" fill="url(#$id-g)"/>
  <path d="M44 70 Q40 84 44 98 Q54 124 80 125 Q106 124 116 98 Q120 84 116 70" fill="none" stroke="#FFFFFF" stroke-opacity="0.5" stroke-dasharray="3 3"/>
  <ellipse cx="80" cy="88" rx="30" ry="27" fill="url(#$id-f)" stroke="#D3E3E0"/>
  <ellipse cx="70" cy="78" rx="12" ry="5" fill="#FFFFFF" opacity="0.9" transform="rotate(-18 70 78)"/>
  <circle cx="80" cy="90" r="6" fill="#4A9E97"/>
  <circle cx="80" cy="90" r="2.4" fill="#F7FBFA"/>
</svg>
''';
    return SvgPicture.string(svg, width: 40, height: 40, fit: BoxFit.cover);
  }
}

class _AddDeviceAccordionCard extends StatelessWidget {
  const _AddDeviceAccordionCard({
    required this.cats,
    required this.expanded,
    required this.selectedCatId,
    required this.isEn,
    required this.onToggleExpanded,
    required this.onSelectCat,
    required this.onBuyTag,
  });

  final List<CatProfile> cats;
  final bool expanded;
  final String? selectedCatId;
  final bool isEn;
  final VoidCallback onToggleExpanded;
  final ValueChanged<String> onSelectCat;
  final VoidCallback onBuyTag;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.soft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: expanded,
            label: isEn ? 'Add device' : 'เพิ่มอุปกรณ์',
            child: InkWell(
              onTap: onToggleExpanded,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: AppColors.trackerSafeTeal,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.plus,
                        size: 19,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEn ? 'Add device' : 'เพิ่มอุปกรณ์',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            isEn
                                ? 'Pick a cat, then buy or link a tag'
                                : 'เลือกน้อง แล้วซื้อหรือเชื่อมแท็ก',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: expanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: const Icon(
                        LucideIcons.chevronRight,
                        size: 18,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (expanded) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, thickness: 1, color: AppColors.line2),
            const SizedBox(height: 12),
            Text(
              isEn ? 'Which cat is it for' : 'ใส่ให้น้องตัวไหน',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 8),
            for (final cat in cats) ...[
              _AddDeviceCatRadioRow(
                cat: cat,
                selected: selectedCatId == cat.id,
                isEn: isEn,
                onTap: () => onSelectCat(cat.id),
              ),
              const SizedBox(height: 6),
            ],
            if (selectedCatId != null) ...[
              const SizedBox(height: 8),
              Semantics(
                button: true,
                label: isEn ? 'Buy a tag' : 'ซื้อแท็ก',
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.trackerSafeTealLight,
                        AppColors.trackerSafeTeal,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onBuyTag,
                      borderRadius: BorderRadius.circular(999),
                      child: SizedBox(
                        height: 44,
                        child: Center(
                          child: Text(
                            isEn ? 'Buy a tag' : 'ซื้อแท็ก',
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _AddDeviceCatRadioRow extends StatelessWidget {
  const _AddDeviceCatRadioRow({
    required this.cat,
    required this.selected,
    required this.isEn,
    required this.onTap,
  });

  final CatProfile cat;
  final bool selected;
  final bool isEn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = MyCatL10n.catName(cat.name, isEn);
    final device = cat.trackerInfo.device;
    final hasTag = cat.trackerInfo.hasTag && device != null;
    final tagStatus = hasTag
        ? (isEn
              ? 'Linked to tag ${device.tagNumber}'
              : 'เชื่อมกับแท็ก ${device.tagNumber}')
        : (isEn ? 'No tag yet' : 'ยังไม่มีแท็ก');

    return Semantics(
      button: true,
      selected: selected,
      label: '$name, $tagStatus',
      child: Material(
        color: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected ? AppColors.trackerSafeTeal : AppColors.line,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                      Text(
                        tagStatus,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: hasTag
                              ? AppColors.muted
                              : AppColors.trackerSafeTeal,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? AppColors.trackerSafeTeal
                          : AppColors.line2,
                      width: 2,
                    ),
                    color: selected
                        ? AppColors.trackerSafeTeal
                        : Colors.transparent,
                  ),
                  child: selected
                      ? const Center(
                          child: CircleAvatar(
                            radius: 4,
                            backgroundColor: Colors.white,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeviceTagDetailView extends StatelessWidget {
  const _DeviceTagDetailView({
    required this.cat,
    required this.device,
    required this.isEn,
    required this.confirmDisconnect,
    required this.onBack,
    required this.onUpdateDevice,
    required this.onRequestDisconnect,
    required this.onCancelDisconnect,
    required this.onConfirmDisconnect,
    required this.onNotify,
  });

  final CatProfile cat;
  final CatTrackerDevice device;
  final bool isEn;
  final bool confirmDisconnect;
  final VoidCallback onBack;
  final ValueChanged<CatTrackerDevice Function(CatTrackerDevice)>
  onUpdateDevice;
  final VoidCallback onRequestDisconnect;
  final VoidCallback onCancelDisconnect;
  final VoidCallback onConfirmDisconnect;
  final ValueChanged<String> onNotify;

  @override
  Widget build(BuildContext context) {
    final info = cat.trackerInfo;
    final catName = MyCatL10n.catName(cat.name, isEn);
    final lowBattery = info.batteryPercent <= 25;
    final batteryColor = lowBattery ? AppColors.danger : AppColors.muted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // หัวหน้ารายละเอียดแท็ก
        Row(
          children: [
            Semantics(
              button: true,
              label: isEn ? 'Back to device list' : 'กลับไปตั้งค่าอุปกรณ์',
              child: InkWell(
                onTap: onBack,
                borderRadius: BorderRadius.circular(14),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    LucideIcons.chevronLeft,
                    size: 22,
                    color: AppColors.text,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                isEn
                    ? 'Tag ${device.tagNumber} · $catName'
                    : 'แท็ก ${device.tagNumber} · $catName',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // การ์ดเดียวรวม 9 บล็อกย่อยตรงตามเว็บจริง
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.soft,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1) หัวแท็ก + แบตเตอรี่
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'แมว.live Tag',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          isEn
                              ? "On $catName's collar"
                              : 'ใส่อยู่ที่ปลอกคอของ$catName',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    lowBattery
                        ? LucideIcons.batteryLow
                        : LucideIcons.batteryMedium,
                    size: 18,
                    color: batteryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${info.batteryPercent}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: batteryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 2) แถบสถานะสัญญาณ
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.signal,
                      size: 16,
                      color: device.signalGood
                          ? AppColors.statusSafe
                          : AppColors.danger,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isEn
                            ? '4G · ${device.signalGood ? 'good signal' : 'weak signal'} · last synced ${device.lastSyncedEn}'
                            : '4G · ${device.signalGood ? 'สัญญาณดี' : 'สัญญาณอ่อน'} · ซิงก์ล่าสุด ${device.lastSyncedTh}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.text2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const _BlockDivider(),
              // 3) ความถี่ในการอัปเดตตำแหน่ง
              Text(
                isEn
                    ? 'Location update frequency'
                    : 'ความถี่ในการอัปเดตตำแหน่ง',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final freq in TrackerUpdateFrequency.values) ...[
                    if (freq != TrackerUpdateFrequency.batterySaver)
                      const SizedBox(width: 6),
                    Expanded(
                      child: _DeviceChoiceChip(
                        label: isEn ? freq.enLabel : freq.thLabel,
                        selected: device.frequency == freq,
                        onTap: () =>
                            onUpdateDevice((d) => d.copyWith(frequency: freq)),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(
                isEn ? device.frequency.enSummary : device.frequency.thSummary,
                style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
              ),
              const _BlockDivider(),
              // 4) ระดับเสียงปลอกคอ
              Text(
                isEn ? 'Collar volume' : 'ระดับเสียงปลอกคอ',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final vol in TrackerCollarVolume.values) ...[
                    if (vol != TrackerCollarVolume.quiet)
                      const SizedBox(width: 6),
                    Expanded(
                      child: _DeviceChoiceChip(
                        label: isEn ? vol.enLabel : vol.thLabel,
                        selected: device.volume == vol,
                        onTap: () =>
                            onUpdateDevice((d) => d.copyWith(volume: vol)),
                      ),
                    ),
                  ],
                ],
              ),
              const _BlockDivider(),
              // 5) ไฟ LED ตอนกลางคืน
              _DeviceToggleRow(
                icon: LucideIcons.lightbulb,
                title: isEn ? 'Night LED' : 'ไฟ LED ตอนกลางคืน',
                subtitle: isEn
                    ? 'Helps you see your cat in the dark'
                    : 'ช่วยให้มองเห็นแมวในที่มืด',
                value: device.nightLed,
                onChanged: (v) =>
                    onUpdateDevice((d) => d.copyWith(nightLed: v)),
              ),
              const _BlockDivider(),
              // 6) ประหยัดแบตเมื่ออยู่บ้าน
              _DeviceToggleRow(
                icon: LucideIcons.wifi,
                title: isEn
                    ? 'Save battery at home'
                    : 'ประหยัดแบตเมื่ออยู่บ้าน',
                subtitle: isEn
                    ? 'Sends location less often on home Wi-Fi'
                    : 'ลดการส่งตำแหน่งเมื่อเชื่อม Wi-Fi บ้าน',
                value: device.saveBatteryAtHome,
                onChanged: (v) =>
                    onUpdateDevice((d) => d.copyWith(saveBatteryAtHome: v)),
              ),
              const _BlockDivider(),
              // 7) แจ้งเตือนแบตเหลือน้อย
              _DeviceToggleRow(
                icon: LucideIcons.batteryLow,
                title: isEn ? 'Low battery alert' : 'แจ้งเตือนแบตเหลือน้อย',
                subtitle: isEn
                    ? 'When battery is below 20%'
                    : 'เมื่อแบตต่ำกว่า 20%',
                value: device.lowBatteryAlert,
                onChanged: (v) =>
                    onUpdateDevice((d) => d.copyWith(lowBatteryAlert: v)),
              ),
              const _BlockDivider(),
              // 8) เฟิร์มแวร์ & หมายเลขเครื่อง
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEn
                              ? 'Firmware ${device.firmwareVersion}'
                              : 'เฟิร์มแวร์ ${device.firmwareVersion}',
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isEn
                              ? 'Serial ${device.serialCode}'
                              : 'หมายเลขเครื่อง ${device.serialCode}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Semantics(
                    button: true,
                    label: isEn ? 'Check for updates' : 'ตรวจสอบอัปเดต',
                    child: OutlinedButton.icon(
                      onPressed: () {
                        if (device.hasFirmwareUpdate) {
                          onNotify(
                            isEn
                                ? 'Updating to ${device.latestFirmwareVersion} (demo)'
                                : 'กำลังอัปเดตเป็น ${device.latestFirmwareVersion} (จำลอง)',
                          );
                        } else {
                          onNotify(
                            isEn
                                ? 'Already up to date'
                                : 'เป็นเวอร์ชันล่าสุดแล้ว',
                          );
                        }
                      },
                      icon: const Icon(LucideIcons.refreshCw, size: 14),
                      label: Text(
                        isEn ? 'Check for updates' : 'ตรวจสอบอัปเดต',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        backgroundColor: AppColors.card,
                        foregroundColor: AppColors.text,
                        side: const BorderSide(color: AppColors.line2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const _BlockDivider(),
              // 9) ยกเลิกการเชื่อมต่ออุปกรณ์
              if (!confirmDisconnect)
                Semantics(
                  button: true,
                  label: isEn
                      ? 'Disconnect device'
                      : 'ยกเลิกการเชื่อมต่ออุปกรณ์',
                  child: InkWell(
                    onTap: onRequestDisconnect,
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 44,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            LucideIcons.unlink,
                            size: 18,
                            color: AppColors.danger,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              isEn
                                  ? 'Disconnect device'
                                  : 'ยกเลิกการเชื่อมต่ออุปกรณ์',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.danger,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.trackerLostBgOn,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.trackerLostBtnBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        isEn
                            ? "Disconnect $catName's collar? You won't see the location until you reconnect"
                            : 'ยกเลิกการเชื่อมต่อปลอกคอกับ$catName? จะไม่เห็นตำแหน่งจนกว่าจะเชื่อมใหม่',
                        style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.4,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: onCancelDisconnect,
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 44),
                                backgroundColor: AppColors.card,
                                foregroundColor: AppColors.text,
                                side: const BorderSide(color: AppColors.line2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                isEn ? 'No' : 'ไม่ใช่',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton(
                              onPressed: onConfirmDisconnect,
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(0, 44),
                                backgroundColor: AppColors.danger,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                isEn ? 'Disconnect' : 'ยกเลิกการเชื่อมต่อ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BlockDivider extends StatelessWidget {
  const _BlockDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Divider(height: 1, thickness: 1, color: AppColors.line),
    );
  }
}

class _DeviceChoiceChip extends StatelessWidget {
  const _DeviceChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? AppColors.btn : AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? AppColors.btnBorder : AppColors.line2,
            width: 1.5,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 44,
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.ink : AppColors.text,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeviceToggleRow extends StatelessWidget {
  const _DeviceToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.ink),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        TrackerPillSwitch(value: value, label: title, onChanged: onChanged),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../domain/entities/my_cat_data.dart';
import 'my_cat_l10n.dart';

/// รายการแมวทั้งหมดในชีตล่างของหน้า /my-cat/tracker
class CatTrackerCatsListContent extends StatelessWidget {
  const CatTrackerCatsListContent({
    super.key,
    required this.cats,
    required this.isEn,
    required this.onSelectCat,
  });

  final List<CatProfile> cats;
  final bool isEn;
  final ValueChanged<CatProfile> onSelectCat;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isEn ? 'My cats' : 'แมวของฉัน',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < cats.length; i++) ...[
          if (i > 0)
            const Divider(height: 1, thickness: 1, color: AppColors.line),
          _CatTrackerListRow(
            cat: cats[i],
            isEn: isEn,
            onTap: () => onSelectCat(cats[i]),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          isEn
              ? 'Works on iPhone and Android with the แมว.live app · sample data'
              : 'ใช้ได้ทั้ง iPhone และ Android ผ่านแอป แมว.live · ข้อมูลตัวอย่าง',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
      ],
    );
  }
}

class _CatTrackerListRow extends StatelessWidget {
  const _CatTrackerListRow({
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
    final name = MyCatL10n.catName(cat.name, isEn);
    final hasTag = info.hasTag;
    final isOutOfZone = cat.trackerStatus == CatTrackerStatus.outOfZone;
    final isLowBattery = info.batteryPercent <= 25;

    return Semantics(
      button: true,
      label: hasTag
          ? (isEn
                ? '$name, ${info.listSummaryEn}, battery ${info.batteryPercent}%'
                : '$name, ${info.listSummaryTh}, แบต ${info.batteryPercent}%')
          : (isEn
                ? '$name, no tag yet, tap to add'
                : '$name, ยังไม่มีแท็ก แตะเพื่อเพิ่ม'),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              _TrackerListAvatar(
                cat: cat,
                hasTag: hasTag,
                isOutOfZone: isOutOfZone,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                        if (hasTag)
                          Text(
                            isEn ? info.listSummaryEn : info.listSummaryTh,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: isOutOfZone
                                  ? AppColors.danger
                                  : AppColors.muted,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            hasTag
                                ? (isEn
                                      ? '${info.locationEn} · ${info.lastUpdatedEn}'
                                      : '${info.locationTh} · ${info.lastUpdatedTh}')
                                : (isEn
                                      ? 'No tag yet · tap to add'
                                      : 'ยังไม่มีแท็ก · แตะเพื่อเพิ่ม'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                        if (hasTag) ...[
                          const SizedBox(width: 8),
                          Icon(
                            isLowBattery
                                ? LucideIcons.batteryLow
                                : LucideIcons.batteryMedium,
                            size: 18,
                            color: isLowBattery
                                ? AppColors.danger
                                : AppColors.muted,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${info.batteryPercent}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isLowBattery
                                  ? AppColors.danger
                                  : AppColors.muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrackerListAvatar extends StatelessWidget {
  const _TrackerListAvatar({
    required this.cat,
    required this.hasTag,
    required this.isOutOfZone,
  });

  final CatProfile cat;
  final bool hasTag;
  final bool isOutOfZone;

  @override
  Widget build(BuildContext context) {
    Widget avatar = AppAvatar(
      source: cat.avatarSource,
      bg: cat.avatarBg,
      size: 48,
    );
    if (!hasTag) {
      avatar = Opacity(
        opacity: 0.6,
        child: ColorFiltered(
          colorFilter: const ColorFilter.matrix(<double>[
            0.2126,
            0.7152,
            0.0722,
            0,
            0,
            0.2126,
            0.7152,
            0.0722,
            0,
            0,
            0.2126,
            0.7152,
            0.0722,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
          ]),
          child: avatar,
        ),
      );
    }

    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          if (hasTag)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: isOutOfZone ? AppColors.heart : AppColors.statusSafe,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.card, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// แผงรายละเอียดแมวเมื่อเลือกจากแผนที่หรือรายการ
class CatTrackerCatDetailContent extends StatelessWidget {
  const CatTrackerCatDetailContent({
    super.key,
    required this.cat,
    required this.isEn,
    required this.isPlayingSound,
    required this.onClose,
    required this.onToggleSound,
    required this.onDirections,
    required this.onChangeRadius,
    required this.onToggleAlertLeaveZone,
    required this.onToggleLostMode,
    required this.onToggleShowContact,
    required this.onToggleShareCommunity,
    required this.onPostMissing,
    required this.onInviteHelper,
    required this.onBuyTag,
    required this.onConnectCollar,
  });

  final CatProfile cat;
  final bool isEn;
  final bool isPlayingSound;
  final VoidCallback onClose;
  final VoidCallback onToggleSound;
  final VoidCallback onDirections;
  final ValueChanged<int> onChangeRadius;
  final ValueChanged<bool> onToggleAlertLeaveZone;
  final ValueChanged<bool> onToggleLostMode;
  final ValueChanged<bool> onToggleShowContact;
  final ValueChanged<bool> onToggleShareCommunity;
  final VoidCallback onPostMissing;
  final VoidCallback onInviteHelper;
  final VoidCallback onBuyTag;
  final VoidCallback onConnectCollar;

  @override
  Widget build(BuildContext context) {
    if (!cat.trackerInfo.hasTag) {
      return _NoTagCatDetail(
        cat: cat,
        isEn: isEn,
        onClose: onClose,
        onBuyTag: onBuyTag,
        onConnectCollar: onConnectCollar,
      );
    }

    final info = cat.trackerInfo;
    final name = MyCatL10n.catName(cat.name, isEn);
    final isOutOfZone = cat.trackerStatus == CatTrackerStatus.outOfZone;
    final isNow = info.detailTimeTh == 'ตอนนี้';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ),
            _SheetCloseButton(isEn: isEn, onTap: onClose),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          isOutOfZone
              ? (isEn
                    ? 'Out of zone · ${info.distanceMeters} m from home'
                    : 'ออกนอกเขต · ห่างบ้าน ${info.distanceMeters} ม.')
              : (isEn ? 'In the safe zone' : 'อยู่ในเขตปลอดภัย'),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isOutOfZone ? AppColors.danger : AppColors.text,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                isEn ? info.locationEn : info.locationTh,
                style: const TextStyle(fontSize: 14, color: AppColors.text2),
              ),
            ),
            Text(
              isEn ? info.detailTimeEn : info.detailTimeTh,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isNow ? AppColors.statusSafe : AppColors.muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // 2 ปุ่มหลัก: เล่นเสียง & นำทาง
        Row(
          children: [
            Expanded(
              child: _PlaySoundActionCard(
                isEn: isEn,
                isPlaying: isPlayingSound,
                onTap: onToggleSound,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _DirectionsActionCard(
                isEn: isEn,
                distanceMeters: info.distanceMeters,
                onTap: onDirections,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // เส้นทางวันนี้
        _TodayRouteCard(stops: info.routeStops, isEn: isEn),
        const SizedBox(height: 12),
        // เขตปลอดภัยรอบบ้าน
        _SafeZoneCard(
          catName: name,
          radiusMeters: info.safeZoneRadiusMeters,
          alertOnLeaveZone: info.alertOnLeaveZone,
          isEn: isEn,
          onChangeRadius: onChangeRadius,
          onToggleAlert: onToggleAlertLeaveZone,
        ),
        const SizedBox(height: 12),
        // ถ้าแมวหาย
        _LostModeCard(
          catName: name,
          info: info,
          isEn: isEn,
          onToggleLostMode: onToggleLostMode,
          onToggleShowContact: onToggleShowContact,
          onToggleShareCommunity: onToggleShareCommunity,
          onPostMissing: onPostMissing,
        ),
        const SizedBox(height: 12),
        // คนที่ช่วยติดตาม
        _HelpersCard(
          caregivers: cat.caregivers,
          isEn: isEn,
          onInviteHelper: onInviteHelper,
        ),
      ],
    );
  }
}

class _SheetCloseButton extends StatelessWidget {
  const _SheetCloseButton({required this.isEn, required this.onTap});

  final bool isEn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: isEn ? 'Close' : 'ปิด',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.soft,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.x, size: 19, color: AppColors.text),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaySoundActionCard extends StatefulWidget {
  const _PlaySoundActionCard({
    required this.isEn,
    required this.isPlaying,
    required this.onTap,
  });

  final bool isEn;
  final bool isPlaying;
  final VoidCallback onTap;

  @override
  State<_PlaySoundActionCard> createState() => _PlaySoundActionCardState();
}

class _PlaySoundActionCardState extends State<_PlaySoundActionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  @override
  void initState() {
    super.initState();
    if (widget.isPlaying) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _PlaySoundActionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.isPlaying && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEn ? 'Play sound' : 'เล่นเสียง';
    final sub = widget.isPlaying
        ? (widget.isEn ? 'Playing sound…' : 'กำลังส่งเสียง…')
        : (widget.isEn ? 'Tap to chime' : 'แตะเพื่อเรียก');

    return Semantics(
      button: true,
      toggled: widget.isPlaying,
      label: title,
      child: Material(
        color: AppColors.soft,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, child) => Transform.scale(
                    scale: widget.isPlaying ? 1.0 + (_pulse.value * 0.12) : 1.0,
                    child: Opacity(
                      opacity: widget.isPlaying
                          ? 0.72 + (_pulse.value * 0.28)
                          : 1.0,
                      child: child,
                    ),
                  ),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.quickAiIcon,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.volume2,
                      size: 19,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        sub,
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
        ),
      ),
    );
  }
}

class _DirectionsActionCard extends StatelessWidget {
  const _DirectionsActionCard({
    required this.isEn,
    required this.distanceMeters,
    required this.onTap,
  });

  final bool isEn;
  final int distanceMeters;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = isEn ? 'Directions' : 'นำทาง';
    final sub = distanceMeters == 0
        ? (isEn ? 'Nearby' : 'ใกล้ ๆ')
        : (isEn ? 'Walk $distanceMeters m' : 'เดิน $distanceMeters ม.');

    return Semantics(
      button: true,
      label: title,
      child: Material(
        color: AppColors.soft,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.statusSafe,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.navigation,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        sub,
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
        ),
      ),
    );
  }
}

class _TodayRouteCard extends StatelessWidget {
  const _TodayRouteCard({required this.stops, required this.isEn});

  final List<TrackerRouteStop> stops;
  final bool isEn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.soft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEn ? "Today's route" : 'เส้นทางวันนี้',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < stops.length; i++)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: i == 0
                            ? AppColors.ink
                            : AppColors.trackerTimelineInactive,
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (i < stops.length - 1)
                      Container(width: 2, height: 22, color: AppColors.line2),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: i < stops.length - 1 ? 10 : 0,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            isEn ? stops[i].placeEn : stops[i].placeTh,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: i == 0
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: i == 0 ? AppColors.text : AppColors.text2,
                            ),
                          ),
                        ),
                        Text(
                          isEn ? stops[i].timeEn : stops[i].timeTh,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _SafeZoneCard extends StatelessWidget {
  const _SafeZoneCard({
    required this.catName,
    required this.radiusMeters,
    required this.alertOnLeaveZone,
    required this.isEn,
    required this.onChangeRadius,
    required this.onToggleAlert,
  });

  final String catName;
  final int radiusMeters;
  final bool alertOnLeaveZone;
  final bool isEn;
  final ValueChanged<int> onChangeRadius;
  final ValueChanged<bool> onToggleAlert;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.soft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEn ? 'Safe zone around home' : 'เขตปลอดภัยรอบบ้าน',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final r in const [50, 100, 200]) ...[
                if (r != 50) const SizedBox(width: 8),
                Expanded(
                  child: _RadiusRadioButton(
                    label: isEn ? '$r m' : '$r ม.',
                    selected: radiusMeters == r,
                    onTap: () => onChangeRadius(r),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 1, color: AppColors.line2),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(LucideIcons.bell, size: 18, color: AppColors.ink),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isEn
                      ? 'Alert when $catName leaves safe zone'
                      : 'แจ้งเตือนเมื่อ$catNameออกนอกเขต',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.text,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TrackerPillSwitch(
                value: alertOnLeaveZone,
                label: isEn
                    ? 'Alert when $catName leaves safe zone'
                    : 'แจ้งเตือนเมื่อ$catNameออกนอกเขต',
                onChanged: onToggleAlert,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RadiusRadioButton extends StatelessWidget {
  const _RadiusRadioButton({
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
                style: TextStyle(
                  fontSize: 14,
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

class _LostModeCard extends StatelessWidget {
  const _LostModeCard({
    required this.catName,
    required this.info,
    required this.isEn,
    required this.onToggleLostMode,
    required this.onToggleShowContact,
    required this.onToggleShareCommunity,
    required this.onPostMissing,
  });

  final String catName;
  final CatTrackerInfo info;
  final bool isEn;
  final ValueChanged<bool> onToggleLostMode;
  final ValueChanged<bool> onToggleShowContact;
  final ValueChanged<bool> onToggleShareCommunity;
  final VoidCallback onPostMissing;

  @override
  Widget build(BuildContext context) {
    final lostOn = info.lostMode;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: lostOn ? AppColors.trackerLostBgOn : AppColors.soft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isEn ? 'If your cat goes missing' : 'ถ้าแมวหาย',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                LucideIcons.shieldAlert,
                size: 20,
                color: lostOn ? AppColors.danger : AppColors.trackerLostIconOff,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEn ? 'Lost mode' : 'โหมดแมวหาย',
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isEn
                          ? 'Updates location more often and alerts whenever $catName moves'
                          : 'อัปเดตตำแหน่งถี่ขึ้น และแจ้งเตือนทุกครั้งที่$catNameขยับ',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TrackerPillSwitch(
                value: lostOn,
                label: isEn ? 'Lost mode' : 'โหมดแมวหาย',
                activeColor: AppColors.danger,
                onChanged: onToggleLostMode,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 1, color: AppColors.line2),
          const SizedBox(height: 10),
          _LostSubToggleRow(
            title: isEn ? 'Show contact number' : 'แสดงเบอร์ติดต่อ',
            subtitle: isEn
                ? 'People who scan the Cat ID will see ${info.contactPhone}'
                : 'คนที่สแกน Cat ID จะเห็น ${info.contactPhone}',
            value: info.showContactNumber,
            onChanged: onToggleShowContact,
          ),
          const SizedBox(height: 10),
          _LostSubToggleRow(
            title: isEn
                ? 'Let the community help search'
                : 'ให้คนในชุมชนช่วยหา',
            subtitle: isEn
                ? 'Show approximate location on the Help page'
                : 'แสดงตำแหน่งคร่าว ๆ ในหน้าช่วยเหลือ',
            value: info.shareWithCommunity,
            onChanged: onToggleShareCommunity,
          ),
          const SizedBox(height: 12),
          Semantics(
            button: true,
            label: isEn
                ? 'Post missing alert for $catName'
                : 'ประกาศตามหา$catName',
            child: OutlinedButton.icon(
              onPressed: onPostMissing,
              icon: const Icon(LucideIcons.megaphone, size: 17),
              label: Text(
                isEn
                    ? 'Post missing alert for $catName'
                    : 'ประกาศตามหา$catName',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 46),
                backgroundColor: lostOn ? AppColors.danger : AppColors.card,
                foregroundColor: lostOn
                    ? Colors.white
                    : AppColors.trackerLostBtnInk,
                side: BorderSide(
                  color: lostOn
                      ? AppColors.danger
                      : AppColors.trackerLostBtnBorder,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LostSubToggleRow extends StatelessWidget {
  const _LostSubToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
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

class _HelpersCard extends StatelessWidget {
  const _HelpersCard({
    required this.caregivers,
    required this.isEn,
    required this.onInviteHelper,
  });

  final List<CatCaregiver> caregivers;
  final bool isEn;
  final VoidCallback onInviteHelper;

  @override
  Widget build(BuildContext context) {
    final names = caregivers
        .map((c) => MyCatL10n.caregiverName(c.name, isEn))
        .join(' · ');

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 2),
      decoration: BoxDecoration(
        color: AppColors.soft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isEn ? 'Helpers' : 'คนที่ช่วยติดตาม',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                height: 36,
                width: caregivers.isEmpty
                    ? 0
                    : 36 + (caregivers.length - 1) * 26.0,
                child: Stack(
                  children: [
                    for (var i = 0; i < caregivers.length; i++)
                      Positioned(
                        left: i * 26.0,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.card, width: 2),
                          ),
                          child: AppAvatar(
                            source: caregivers[i].avatarSource,
                            bg: caregivers[i].avatarBg,
                            size: 32,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (names.isNotEmpty) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    names,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text2,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 1, color: AppColors.line2),
          Semantics(
            button: true,
            label: isEn ? 'Add a helper' : 'เพิ่มคนช่วยติดตาม',
            child: InkWell(
              onTap: onInviteHelper,
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 48,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      LucideIcons.userPlus,
                      size: 18,
                      color: AppColors.ink,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isEn ? 'Add a helper' : 'เพิ่มคนช่วยติดตาม',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoTagCatDetail extends StatelessWidget {
  const _NoTagCatDetail({
    required this.cat,
    required this.isEn,
    required this.onClose,
    required this.onBuyTag,
    required this.onConnectCollar,
  });

  final CatProfile cat;
  final bool isEn;
  final VoidCallback onClose;
  final VoidCallback onBuyTag;
  final VoidCallback onConnectCollar;

  @override
  Widget build(BuildContext context) {
    final name = MyCatL10n.catName(cat.name, isEn);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ),
            _SheetCloseButton(isEn: isEn, onTap: onClose),
          ],
        ),
        const SizedBox(height: 16),
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.card, width: 4),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x264A3428),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: AppAvatar(
              source: cat.avatarSource,
              bg: cat.avatarBg,
              size: 72,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          isEn
              ? "$name doesn't have a แมว.live Tag yet"
              : '$nameยังไม่มี แมว.live Tag',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isEn
              ? "Attach a tag to the collar and check $name's latest location right here. Works on both iPhone and Android"
              : 'ติดแท็กไว้กับปลอกคอ แล้วดูตำแหน่งล่าสุดของ$nameได้ในหน้านี้ ใช้ได้ทั้ง iPhone และ Android',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            height: 1.45,
            color: AppColors.text2,
          ),
        ),
        const SizedBox(height: 20),
        Semantics(
          button: true,
          label: isEn ? 'View แมว.live Tag · ฿990' : 'ดู แมว.live Tag · ฿990',
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
                onTap: onBuyTag,
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 48,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          LucideIcons.shoppingBag,
                          size: 18,
                          color: AppColors.text,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            isEn
                                ? 'View แมว.live Tag · ฿990'
                                : 'ดู แมว.live Tag · ฿990',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Semantics(
            button: true,
            label: isEn
                ? 'Already have a collar? Connect'
                : 'มีปลอกคออยู่แล้ว เชื่อมต่อ',
            child: TextButton(
              onPressed: onConnectCollar,
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 44),
                foregroundColor: AppColors.ink,
              ),
              child: Text(
                isEn
                    ? 'Already have a collar? Connect >'
                    : 'มีปลอกคออยู่แล้ว เชื่อมต่อ >',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isEn
              ? 'Tracking plan ฿59/mo · sample pricing'
              : 'ค่าบริการติดตาม ฿59/เดือน · ราคาตัวอย่าง',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
        ),
      ],
    );
  }
}

/// สวิตช์ทรงเม็ดยาขนาด 48×28px ตรงตามต้นแบบเว็บ
class TrackerPillSwitch extends StatelessWidget {
  const TrackerPillSwitch({
    super.key,
    required this.value,
    required this.label,
    required this.onChanged,
    this.activeColor = AppColors.ink,
  });

  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      label: label,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 48,
            height: 28,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: value ? activeColor : AppColors.line2,
              borderRadius: BorderRadius.circular(999),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_image.dart';
import '../../domain/entities/my_cat_data.dart';
import '../providers/my_cat_controller.dart';
import 'my_cat_l10n.dart';

/// แถบ 4 แท็บของแมว (รูปภาพ / ดูแลวันนี้ / สุขภาพ / ผู้ดูแล) และเนื้อหาภายในแท็บ
class CatTabsSection extends StatelessWidget {
  const CatTabsSection({
    super.key,
    required this.cat,
    required this.activeTab,
    required this.onSelectTab,
    required this.onPhotoTap,
    required this.onToggleCareTask,
    required this.onFindClinic,
    required this.onOpenAllHealth,
    required this.onCaregiverAvatarTap,
    required this.onInviteCaregiver,
    this.isEn = false,
  });

  final CatProfile cat;
  final MyCatContentTab activeTab;
  final ValueChanged<MyCatContentTab> onSelectTab;
  final ValueChanged<int> onPhotoTap;
  final ValueChanged<String> onToggleCareTask;
  final VoidCallback onFindClinic;
  final VoidCallback onOpenAllHealth;
  final ValueChanged<CatCaregiver> onCaregiverAvatarTap;
  final VoidCallback onInviteCaregiver;
  final bool isEn;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TabBar(activeTab: activeTab, onSelectTab: onSelectTab, isEn: isEn),
        switch (activeTab) {
          MyCatContentTab.photos => _PhotosGrid(
            catName: cat.name,
            photos: cat.photos,
            onTap: onPhotoTap,
          ),
          MyCatContentTab.careToday => _CareTodayList(
            cat: cat,
            onToggle: onToggleCareTask,
            isEn: isEn,
          ),
          MyCatContentTab.health => _HealthTabBody(
            cat: cat,
            onFindClinic: onFindClinic,
            onOpenAllHealth: onOpenAllHealth,
            isEn: isEn,
          ),
          MyCatContentTab.caregivers => _CaregiversTabBody(
            caregivers: cat.caregivers,
            onAvatarTap: onCaregiverAvatarTap,
            onInvite: onInviteCaregiver,
            isEn: isEn,
          ),
        },
      ],
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.activeTab,
    required this.onSelectTab,
    this.isEn = false,
  });

  final MyCatContentTab activeTab;
  final ValueChanged<MyCatContentTab> onSelectTab;
  final bool isEn;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        tab: MyCatContentTab.photos,
        label: isEn ? 'Photos' : 'รูปภาพ',
        icon: LucideIcons.images,
      ),
      (
        tab: MyCatContentTab.careToday,
        label: isEn ? "Today's care" : 'ดูแลวันนี้',
        icon: LucideIcons.listChecks,
      ),
      (
        tab: MyCatContentTab.health,
        label: isEn ? 'Health' : 'สุขภาพ',
        icon: LucideIcons.heartPulse,
      ),
      (
        tab: MyCatContentTab.caregivers,
        label: isEn ? 'Caregiver' : 'ผู้ดูแล',
        icon: LucideIcons.users,
      ),
    ];

    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(
          top: BorderSide(color: AppColors.line),
          bottom: BorderSide(color: AppColors.line),
        ),
      ),
      child: Row(
        children: [
          for (final item in items)
            Expanded(
              child: _TabButton(
                label: item.label,
                icon: item.icon,
                selected: activeTab == item.tab,
                onTap: () => onSelectTab(item.tab),
              ),
            ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: selected ? AppColors.ink : AppColors.muted,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? AppColors.text : AppColors.muted,
                  ),
                ),
              ],
            ),
            if (selected)
              Positioned(
                bottom: 0,
                child: Container(
                  width: 58,
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
    );
  }
}

class _PhotosGrid extends StatelessWidget {
  const _PhotosGrid({
    required this.catName,
    required this.photos,
    required this.onTap,
  });

  final String catName;
  final List<CatPhotoItem> photos;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            children: [
              const Icon(LucideIcons.camera, size: 32, color: AppColors.muted),
              const SizedBox(height: 8),
              Text(
                'ยังไม่มีรูปภาพของ$catName',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'กดปุ่ม + มุมซ้ายบนเพื่อเพิ่มรูปเข้าอัลบั้ม',
                style: TextStyle(fontSize: 13, color: AppColors.muted),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 2, bottom: 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        return Semantics(
          button: true,
          label: 'เปิดรูปที่ ${index + 1} ของ$catName',
          child: GestureDetector(
            onTap: () => onTap(index),
            child: AppImage(source: photo.imageSource, cacheWidth: 360),
          ),
        );
      },
    );
  }
}

class _CareTodayList extends StatelessWidget {
  const _CareTodayList({
    required this.cat,
    required this.onToggle,
    this.isEn = false,
  });

  final CatProfile cat;
  final ValueChanged<String> onToggle;
  final bool isEn;

  @override
  Widget build(BuildContext context) {
    final total = cat.careTasks.length;
    final done = cat.completedCareCount;
    final ratio = total == 0 ? 0.0 : (done / total).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isEn ? "Today's care" : 'การดูแลวันนี้',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              ),
              Text(
                isEn ? 'Done $done/$total' : 'เสร็จ $done/$total',
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: AppColors.line,
              color: AppColors.careProgressFill,
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < cat.careTasks.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _CareTaskCard(
              task: cat.careTasks[i],
              isEn: isEn,
              onTap: () => onToggle(cat.careTasks[i].id),
            ),
          ],
        ],
      ),
    );
  }
}

({
  IconData icon,
  Color boxBg,
  Color iconColor,
  Color checkBg,
  Color checkBorder,
  Color checkInk,
})
_careVisualFor(String taskId) {
  return switch (taskId) {
    'care-food' => (
      icon: LucideIcons.utensils,
      boxBg: AppColors.careFoodBg,
      iconColor: AppColors.careFoodIcon,
      checkBg: AppColors.careFoodCheckBg,
      checkBorder: AppColors.careFoodCheckBorder,
      checkInk: AppColors.careFoodCheckInk,
    ),
    'care-water' => (
      icon: LucideIcons.droplet,
      boxBg: AppColors.careWaterBg,
      iconColor: AppColors.careWaterIcon,
      checkBg: AppColors.careWaterCheckBg,
      checkBorder: AppColors.careWaterCheckBorder,
      checkInk: AppColors.careWaterCheckInk,
    ),
    'care-litter' => (
      icon: LucideIcons.shovel,
      boxBg: AppColors.careLitterBg,
      iconColor: AppColors.careLitterIcon,
      checkBg: AppColors.careFoodCheckBg,
      checkBorder: AppColors.careFoodCheckBorder,
      checkInk: AppColors.careFoodCheckInk,
    ),
    'care-meds' => (
      icon: LucideIcons.pill,
      boxBg: AppColors.careMedsBg,
      iconColor: AppColors.careMedsIcon,
      checkBg: AppColors.careWaterCheckBg,
      checkBorder: AppColors.careWaterCheckBorder,
      checkInk: AppColors.careWaterCheckInk,
    ),
    _ => (
      icon: LucideIcons.scale,
      boxBg: AppColors.careWeightBg,
      iconColor: AppColors.careWeightIcon,
      checkBg: AppColors.careWeightBg,
      checkBorder: AppColors.quickFeedBorder,
      checkInk: AppColors.careWeightIcon,
    ),
  };
}

class _CareTaskCard extends StatelessWidget {
  const _CareTaskCard({
    required this.task,
    required this.onTap,
    this.isEn = false,
  });

  final CareTaskItem task;
  final VoidCallback onTap;
  final bool isEn;

  @override
  Widget build(BuildContext context) {
    final visual = _careVisualFor(task.id);
    final title = MyCatL10n.careTaskTitle(task, isEn);
    final subtitle = MyCatL10n.careTaskSubtitle(task, isEn);
    return Semantics(
      button: true,
      checked: task.isDone,
      label: '$title $subtitle',
      child: Material(
        color: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.line),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: visual.boxBg,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(visual.icon, size: 21, color: visual.iconColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: task.isDone ? visual.checkBg : AppColors.card,
                      border: Border.all(
                        color: task.isDone
                            ? visual.checkBorder
                            : AppColors.unchecked,
                        width: 2,
                      ),
                    ),
                    child: task.isDone
                        ? Icon(
                            LucideIcons.check,
                            size: 15,
                            color: visual.checkInk,
                          )
                        : null,
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

class _HealthTabBody extends StatelessWidget {
  const _HealthTabBody({
    required this.cat,
    required this.onFindClinic,
    required this.onOpenAllHealth,
    this.isEn = false,
  });

  final CatProfile cat;
  final VoidCallback onFindClinic;
  final VoidCallback onOpenAllHealth;
  final bool isEn;

  Color _dotColor(CatHealthHighlight item) {
    if (item.isAlert) return AppColors.healthDotVaccine;
    if (item.title.contains('Cat AI')) return AppColors.healthDotAi;
    return AppColors.healthDotCheckup;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (cat.healthReminderTitle.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.healthReminderBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.healthReminderBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      LucideIcons.clock,
                      size: 21,
                      color: AppColors.healthReminderClockInk,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            MyCatL10n.healthReminderTitle(
                              cat.healthReminderTitle,
                              isEn,
                            ),
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            MyCatL10n.healthReminderSubtitle(
                              cat.healthReminderSubtitle,
                              isEn,
                            ),
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.text2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: onFindClinic,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 38),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          isEn ? 'Find a clinic' : 'หาคลินิก',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.healthReminderBtnInk,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            isEn ? 'Latest log' : 'บันทึกล่าสุด',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < cat.healthHighlights.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(top: 5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _dotColor(cat.healthHighlights[i]),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          MyCatL10n.healthHighlightTitle(
                            cat.healthHighlights[i].title,
                            isEn,
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          MyCatL10n.healthHighlightDate(
                            cat.healthHighlights[i].dateLabel,
                            isEn,
                          ),
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
          ],
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: onOpenAllHealth,
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                foregroundColor: AppColors.ink,
                splashFactory: NoSplash.splashFactory,
                overlayColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isEn ? 'View full health book' : 'ดูสมุดสุขภาพทั้งหมด',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(LucideIcons.chevronRight, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CaregiversTabBody extends StatelessWidget {
  const _CaregiversTabBody({
    required this.caregivers,
    required this.onAvatarTap,
    required this.onInvite,
    this.isEn = false,
  });

  final List<CatCaregiver> caregivers;
  final ValueChanged<CatCaregiver> onAvatarTap;
  final VoidCallback onInvite;
  final bool isEn;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEn
                ? 'Household caregivers ${caregivers.length} people'
                : 'ผู้ดูแลในบ้าน ${caregivers.length} คน',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < caregivers.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: [
                  Semantics(
                    button: true,
                    label: isEn
                        ? 'Change photo of ${MyCatL10n.caregiverName(caregivers[i].name, true)}'
                        : 'เปลี่ยนรูปของ${caregivers[i].name}',
                    child: InkWell(
                      onTap: () => onAvatarTap(caregivers[i]),
                      customBorder: const CircleBorder(),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            AppAvatar(
                              source: caregivers[i].avatarSource,
                              bg: caregivers[i].avatarBg,
                              size: 48,
                            ),
                            Positioned(
                              bottom: -2,
                              right: -2,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.btn,
                                  border: Border.all(
                                    color: AppColors.card,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  LucideIcons.camera,
                                  size: 10,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          MyCatL10n.caregiverName(caregivers[i].name, isEn),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                        ),
                        Text(
                          MyCatL10n.caregiverRole(
                            caregivers[i].roleLabel,
                            isEn,
                          ),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onInvite,
              icon: const Icon(LucideIcons.userPlus, size: 16),
              label: Text(
                isEn ? 'Invite a caregiver' : 'ชวนผู้ดูแลเพิ่ม',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 44),
                backgroundColor: AppColors.btn,
                foregroundColor: AppColors.ink,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(
                    color: AppColors.btnBorder,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

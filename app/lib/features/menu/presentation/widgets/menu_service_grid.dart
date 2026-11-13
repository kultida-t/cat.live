import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/menu_data.dart';
import 'menu_l10n.dart';

/// ส่วน "บริการเสริม" บนหน้าเมนูหลัก — รายการแนวตั้งตรงตามเว็บจริง www.แมว.live
class MenuServiceGrid extends StatelessWidget {
  const MenuServiceGrid({
    super.key,
    required this.services,
    required this.isEn,
    required this.onSelectService,
  });

  final List<MenuExtraService> services;
  final bool isEn;
  final ValueChanged<MenuExtraService> onSelectService;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            MenuL10n.servicesHeading(isEn),
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.muted,
            ),
          ),
        ),
        for (final service in services)
          _ServiceRow(
            service: service,
            isEn: isEn,
            onTap: () => onSelectService(service),
          ),
      ],
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({
    required this.service,
    required this.isEn,
    required this.onTap,
  });

  final MenuExtraService service;
  final bool isEn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = MenuL10n.serviceTitle(service.action, isEn);
    final subtitle = MenuL10n.serviceSubtitle(service.action, isEn);
    final style = _styleFor(service.action);

    return Semantics(
      button: true,
      label: service.isComingSoon
          ? '$title ${MenuL10n.comingSoonBadge(isEn)}'
          : (subtitle == null ? title : '$title $subtitle'),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 58),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: style.bg,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(style.icon, size: 20, color: style.fg),
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
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                      if (subtitle != null)
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
                const SizedBox(width: 8),
                if (service.isComingSoon)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.healthWatchBg,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.healthWatchStroke),
                    ),
                    child: Text(
                      MenuL10n.comingSoonBadge(isEn),
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.healthWatchInk,
                      ),
                    ),
                  )
                else
                  const Icon(
                    LucideIcons.chevronRight,
                    size: 18,
                    color: AppColors.muted,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _ServiceStyle _styleFor(MenuServiceAction action) => switch (action) {
    MenuServiceAction.tag => const _ServiceStyle(
      icon: LucideIcons.shoppingBag,
      bg: AppColors.settingsIconBox,
      fg: AppColors.text,
    ),
    MenuServiceAction.treats => const _ServiceStyle(
      icon: LucideIcons.gift,
      bg: AppColors.careFoodBg,
      fg: AppColors.careFoodIcon,
    ),
    MenuServiceAction.memorial => const _ServiceStyle(
      icon: LucideIcons.flower2,
      bg: AppColors.careMedsBg,
      fg: AppColors.careMedsIcon,
    ),
    MenuServiceAction.memorialCremation => const _ServiceStyle(
      icon: LucideIcons.heartHandshake,
      bg: AppColors.healthAbnormalBg,
      fg: AppColors.heart,
    ),
    MenuServiceAction.memorialSite => const _ServiceStyle(
      icon: LucideIcons.sparkles,
      bg: AppColors.careWaterBg,
      fg: AppColors.careWaterIcon,
    ),
    MenuServiceAction.printCatId => const _ServiceStyle(
      icon: LucideIcons.idCard,
      bg: AppColors.careWeightBg,
      fg: AppColors.ownerTeal,
    ),
    MenuServiceAction.pedigree => const _ServiceStyle(
      icon: LucideIcons.award,
      bg: AppColors.careFoodBg,
      fg: AppColors.careFoodIcon,
    ),
    MenuServiceAction.insurance => const _ServiceStyle(
      icon: LucideIcons.umbrella,
      bg: AppColors.tile,
      fg: AppColors.healthVaccineBlue,
    ),
  };
}

class _ServiceStyle {
  const _ServiceStyle({required this.icon, required this.bg, required this.fg});

  final IconData icon;
  final Color bg;
  final Color fg;
}

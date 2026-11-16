import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../domain/entities/app_notification.dart';

/// แถวการแจ้งเตือน 1 รายการ
class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.item,
    required this.isEn,
    required this.onTap,
  });

  final AppNotification item;
  final bool isEn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = isEn ? item.titleEn : item.titleTh;
    final body = isEn ? item.bodyEn : item.bodyTh;
    final timeLabel = isEn ? item.timeLabelEn : item.timeLabelTh;
    final unread = !item.isRead;
    final statusText = isEn
        ? (unread ? 'Unread' : 'Read')
        : (unread ? 'ยังไม่อ่าน' : 'อ่านแล้ว');

    return Semantics(
      button: true,
      label: '$title, $body, $timeLabel, $statusText',
      excludeSemantics: true,
      child: Material(
        color: unread ? AppColors.heroStart : AppColors.card,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(minHeight: 68),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: unread ? AppColors.btnBorder : AppColors.line,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LeadingIcon(item: item),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.35,
                          fontWeight: unread
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: AppColors.text2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        timeLabel,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (unread) ...[
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.heart,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LeadingIcon extends StatelessWidget {
  const _LeadingIcon({required this.item});

  final AppNotification item;

  @override
  Widget build(BuildContext context) {
    final badge = _categoryBadge(item.category);
    if (item.actorAvatar != null && item.actorAvatar!.isNotEmpty) {
      return SizedBox(
        width: 46,
        height: 46,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AppAvatar(source: item.actorAvatar!, bg: item.actorBg, size: 44),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: badge.bg,
                  border: Border.all(color: AppColors.card, width: 1.5),
                ),
                child: Icon(badge.icon, size: 11, color: badge.fg),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(shape: BoxShape.circle, color: badge.bg),
      child: Icon(badge.icon, size: 20, color: badge.fg),
    );
  }

  ({IconData icon, Color bg, Color fg}) _categoryBadge(
    NotificationCategory category,
  ) {
    return switch (category) {
      NotificationCategory.community => (
        icon: LucideIcons.heart,
        bg: AppColors.quickHelpBg,
        fg: AppColors.heart,
      ),
      NotificationCategory.treats => (
        icon: LucideIcons.gift,
        bg: AppColors.btn,
        fg: AppColors.ink,
      ),
      NotificationCategory.help => (
        icon: LucideIcons.triangleAlert,
        bg: AppColors.quickHelpBg,
        fg: AppColors.quickHelpInk,
      ),
      NotificationCategory.care => (
        icon: LucideIcons.stethoscope,
        bg: AppColors.quickFeedBg,
        fg: AppColors.quickFeedInk,
      ),
      NotificationCategory.system => (
        icon: LucideIcons.sparkles,
        bg: AppColors.quickAiBg,
        fg: AppColors.quickAiInk,
      ),
    };
  }
}

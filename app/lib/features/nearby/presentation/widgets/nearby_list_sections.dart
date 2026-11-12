import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_image.dart';
import '../../domain/entities/nearby_data.dart';
import 'nearby_l10n.dart';

Future<void> _launchDirections(double lat, double lng) async {
  final uri = Uri.parse(
    'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
  );
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// แถบฉุกเฉิน 24 ชม. ด้านบนรายการสถานที่
class NearbyEmergencyBar extends StatelessWidget {
  const NearbyEmergencyBar({
    super.key,
    required this.place,
    required this.isEn,
    required this.onCallPhone,
  });

  final NearbyPlace place;
  final bool isEn;
  final ValueChanged<String> onCallPhone;

  @override
  Widget build(BuildContext context) {
    final dist = NearbyL10n.placeDistance(place.distanceKm, isEn: isEn);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(
            LucideIcons.siren,
            size: 16,
            color: AppColors.nearbyEmergencySiren,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: const TextStyle(fontSize: 13, color: AppColors.text2),
                children: [
                  TextSpan(
                    text: '${NearbyL10n.emergency24h(isEn)} ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: '${place.emergencyShortName(isEn)} · $dist'),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => onCallPhone(place.phone),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.phone,
                    size: 15,
                    color: AppColors.nearbyEmergencyCall,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    NearbyL10n.callBtn(isEn),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.nearbyEmergencyCall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ส่วน "สถานที่ใกล้คุณ" (ย่อ 3 รายการ / ดูทั้งหมด)
class NearbyPlacesSection extends StatelessWidget {
  const NearbyPlacesSection({
    super.key,
    required this.places,
    required this.bookmarkedIds,
    required this.isExpanded,
    required this.isFiltered,
    required this.isEn,
    required this.onToggleExpand,
    required this.onTapPlace,
    required this.onToggleBookmark,
    required this.onCallPhone,
  });

  final List<NearbyPlace> places;
  final Set<String> bookmarkedIds;
  final bool isExpanded;
  final bool isFiltered;
  final bool isEn;
  final VoidCallback onToggleExpand;
  final ValueChanged<NearbyPlace> onTapPlace;
  final ValueChanged<NearbyPlace> onToggleBookmark;
  final ValueChanged<String> onCallPhone;

  @override
  Widget build(BuildContext context) {
    final visible = isExpanded ? places : places.take(3).toList();
    final canExpand = places.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeaderRow(
            title: NearbyL10n.placesSectionTitle(
              count: places.length,
              isExpanded: isExpanded,
              isEn: isEn,
            ),
            canExpand: canExpand,
            isExpanded: isExpanded,
            isEn: isEn,
            toggleKey: const Key('nearby-places-toggle'),
            onToggleExpand: onToggleExpand,
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.line),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F4A3428),
                  blurRadius: 14,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                for (var i = 0; i < visible.length; i++) ...[
                  if (i > 0)
                    const Divider(height: 1, thickness: 1, color: AppColors.line),
                  _PlaceRow(
                    place: visible[i],
                    isSaved: bookmarkedIds.contains(visible[i].id),
                    isEn: isEn,
                    onTap: () => onTapPlace(visible[i]),
                    onToggleBookmark: () => onToggleBookmark(visible[i]),
                    onCallPhone: () => onCallPhone(visible[i].phone),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceRow extends StatelessWidget {
  const _PlaceRow({
    required this.place,
    required this.isSaved,
    required this.isEn,
    required this.onTap,
    required this.onToggleBookmark,
    required this.onCallPhone,
  });

  final NearbyPlace place;
  final bool isSaved;
  final bool isEn;
  final VoidCallback onTap;
  final VoidCallback onToggleBookmark;
  final VoidCallback onCallPhone;

  @override
  Widget build(BuildContext context) {
    final dist = NearbyL10n.placeDistance(place.distanceKm, isEn: isEn);
    return InkWell(
      key: Key('nearby-place-row-${place.id}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: AppImage(
                        source: place.imageSource,
                      ),
                    ),
                  ),
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Semantics(
                      button: true,
                      toggled: isSaved,
                      child: InkWell(
                        key: Key('nearby-bookmark-${place.id}'),
                        onTap: onToggleBookmark,
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x1A4A3428),
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Icon(
                            isSaved
                                ? Icons.bookmark_rounded
                                : LucideIcons.bookmark,
                            size: isSaved ? 15 : 13,
                            color: isSaved ? AppColors.text : AppColors.muted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name(isEn),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 15,
                        color: AppColors.nearbyStarStroke,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        place.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '(${place.reviewCount})',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.muted,
                        ),
                      ),
                      const Text(
                        ' · ',
                        style: TextStyle(fontSize: 12.5, color: AppColors.muted),
                      ),
                      Flexible(
                        child: Text(
                          dist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.muted,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (place.isOpen) ...[
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.nearbyOpenDot,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          place.statusText(isEn),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: place.isOpen
                                ? AppColors.nearbyOpenText
                                : AppColors.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: onCallPhone,
              customBorder: const CircleBorder(),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.soft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.phone,
                  size: 17,
                  color: AppColors.text,
                ),
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              onTap: () => _launchDirections(place.latitude, place.longitude),
              customBorder: const CircleBorder(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.btn,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.btnBorder),
                ),
                child: const Icon(
                  LucideIcons.navigation,
                  size: 17,
                  color: AppColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ส่วน "แมวใกล้คุณ" / "ประกาศใกล้คุณ" (ย่อ 2 รายการ / ดูทั้งหมด)
class NearbyAnnouncementsSection extends StatelessWidget {
  const NearbyAnnouncementsSection({
    super.key,
    required this.announcements,
    required this.isExpanded,
    required this.isAnnouncementCategory,
    required this.isEn,
    required this.onToggleExpand,
    required this.onViewAnnouncement,
  });

  final List<NearbyAnnouncement> announcements;
  final bool isExpanded;
  final bool isAnnouncementCategory;
  final bool isEn;
  final VoidCallback onToggleExpand;
  final ValueChanged<NearbyAnnouncement> onViewAnnouncement;

  @override
  Widget build(BuildContext context) {
    final visible = isExpanded
        ? announcements
        : announcements.take(2).toList();
    final canExpand = announcements.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeaderRow(
            title: NearbyL10n.announcementsSectionTitle(
              isAnnouncementCategory: isAnnouncementCategory,
              isEn: isEn,
            ),
            canExpand: canExpand,
            isExpanded: isExpanded,
            isEn: isEn,
            toggleKey: const Key('nearby-announcements-toggle'),
            onToggleExpand: onToggleExpand,
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < visible.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _AnnouncementCard(
              announcement: visible[i],
              isEn: isEn,
              onView: () => onViewAnnouncement(visible[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({
    required this.announcement,
    required this.isEn,
    required this.onView,
  });

  final NearbyAnnouncement announcement;
  final bool isEn;
  final VoidCallback onView;

  (Color bg, Color ink) _badgeColors(NearbyAnnouncementType type) {
    return switch (type) {
      NearbyAnnouncementType.lostCat => (
        AppColors.quickHelpBg,
        AppColors.quickHelpInk,
      ),
      NearbyAnnouncementType.foundCat => (
        AppColors.quickFeedBg,
        AppColors.quickFeedInk,
      ),
      NearbyAnnouncementType.communityCat => (
        AppColors.btn,
        AppColors.careFoodCheckInk,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final (bg, ink) = _badgeColors(announcement.type);
    final dist = formatNearbyDistance(announcement.distanceKm, isEn: isEn);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F4A3428),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 72,
              height: 72,
              child: AppImage(
                source: announcement.imageSource,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.cat, size: 12, color: ink),
                      const SizedBox(width: 4),
                      Text(
                        NearbyL10n.announcementTypeLabel(
                          announcement.type,
                          isEn,
                        ),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: ink,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  announcement.title(isEn),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${announcement.timeText(isEn)} · $dist',
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
          const SizedBox(width: 8),
          InkWell(
            key: Key('nearby-view-notice-${announcement.id}'),
            onTap: onView,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.line2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    NearbyL10n.viewNotice(isEn),
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    LucideIcons.chevronRight,
                    size: 14,
                    color: AppColors.ink,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeaderRow extends StatelessWidget {
  const _SectionHeaderRow({
    required this.title,
    required this.canExpand,
    required this.isExpanded,
    required this.isEn,
    required this.toggleKey,
    required this.onToggleExpand,
  });

  final String title;
  final bool canExpand;
  final bool isExpanded;
  final bool isEn;
  final Key toggleKey;
  final VoidCallback onToggleExpand;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
        ),
        if (canExpand)
          InkWell(
            key: toggleKey,
            onTap: onToggleExpand,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isExpanded
                        ? NearbyL10n.collapse(isEn)
                        : NearbyL10n.seeAll(isEn),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    LucideIcons.chevronRight,
                    size: 15,
                    color: AppColors.ink,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

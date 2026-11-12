import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/toast_pill.dart';
import '../../domain/entities/nearby_data.dart';
import '../providers/nearby_controller.dart';
import '../providers/nearby_providers.dart';
import '../widgets/nearby_category_chips.dart';
import '../widgets/nearby_header.dart';
import '../widgets/nearby_l10n.dart';
import '../widgets/nearby_list_sections.dart';
import '../widgets/nearby_map_section.dart';
import '../widgets/nearby_settings_sheet.dart';
import '../widgets/nearby_skeleton.dart';

/// หน้าใกล้ฉัน (/nearby) — ค้นหาคลินิก คาเฟ่ ร้านค้า และประกาศแมวใกล้คุณ
class NearbyPage extends ConsumerStatefulWidget {
  const NearbyPage({super.key, this.tileProvider});

  final TileProvider? tileProvider;

  @override
  ConsumerState<NearbyPage> createState() => _NearbyPageState();
}

class _NearbyPageState extends ConsumerState<NearbyPage> with ToastMixin {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    disposeToast();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openSettings(NearbyState state, bool isEn) {
    final ctrl = ref.read(nearbyControllerProvider.notifier);
    return showNearbySettingsSheet(
      context: context,
      selectedArea: state.selectedArea,
      radiusKm: state.radiusKm,
      showAnnouncementsOnMap: state.showAnnouncementsOnMap,
      isEn: isEn,
      onSelectArea: ctrl.selectArea,
      onSelectRadius: ctrl.setRadius,
      onToggleShowAnnouncements: ctrl.setShowAnnouncementsOnMap,
    );
  }

  Future<void> _handleToggleBookmark(NearbyPlace place, bool isEn) async {
    final ctrl = ref.read(nearbyControllerProvider.notifier);
    final saved = await ctrl.toggleBookmark(place.id);
    if (!mounted) return;
    showToast(NearbyL10n.savedToast(place.name(isEn), saved, isEn));
  }

  Future<void> _handleUseMyLocation(bool isEn) async {
    final ctrl = ref.read(nearbyControllerProvider.notifier);
    final ok = await ctrl.requestMyLocation();
    if (!mounted) return;
    final nextState = ref.read(nearbyControllerProvider);
    showToast(
      ok
          ? NearbyL10n.locationUpdatedToast(
              isEn,
              lat: nextState.userLatitude,
              lng: nextState.userLongitude,
            )
          : NearbyL10n.locationDeniedToast(isEn),
    );
  }

  Future<void> _handleSelectArea(NearbyAreaId area, bool isEn) async {
    final ctrl = ref.read(nearbyControllerProvider.notifier);
    ctrl.selectArea(area);
    if (area == NearbyAreaId.myLocation) {
      await _handleUseMyLocation(isEn);
    }
  }

  Future<void> _handleCallPhone(String phone, bool isEn) async {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri(scheme: 'tel', path: cleaned);
    var launched = false;
    try {
      if (await canLaunchUrl(uri)) {
        launched = await launchUrl(uri);
      }
    } catch (_) {
      launched = false;
    }
    if (!launched) {
      await Clipboard.setData(ClipboardData(text: phone));
      if (!mounted) return;
      showToast(NearbyL10n.phoneCopiedToast(phone, isEn));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nearbyControllerProvider);
    final ctrl = ref.read(nearbyControllerProvider.notifier);
    final isEn = ref.watch(appLocaleProvider) == 'en';
    final dataset = state.activeDataset;

    return ColoredBox(
      color: AppColors.page,
      child: SafeArea(
        top: !state.isFullscreenMap,
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                if (!state.isFullscreenMap)
                  NearbyHeader(
                    selectedArea: state.selectedArea,
                    hasRealLocation: state.hasRealLocation,
                    radiusKm: state.radiusKm,
                    searchController: _searchController,
                    isEn: isEn,
                    onOpenSettings: () => _openSettings(state, isEn),
                    onSelectArea: (area) => _handleSelectArea(area, isEn),
                    onCycleRadius: ctrl.cycleRadius,
                    onSearchChanged: ctrl.setSearchQuery,
                  ),
                Expanded(
                  child: _buildBody(
                    state: state,
                    ctrl: ctrl,
                    dataset: dataset,
                    isEn: isEn,
                  ),
                ),
              ],
            ),
            if (toastMessage != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 16,
                child: Center(child: ToastPill(message: toastMessage!)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody({
    required NearbyState state,
    required NearbyController ctrl,
    required NearbyAreaDataset? dataset,
    required bool isEn,
  }) {
    if (state.isLoading && dataset == null) {
      return const SingleChildScrollView(child: NearbySkeleton());
    }

    if (state.errorMessage != null && dataset == null) {
      return ErrorView(
        message: NearbyL10n.errorMessage(isEn),
        actionLabel: NearbyL10n.retryBtn(isEn),
        onRetry: ctrl.load,
      );
    }

    if (dataset == null) {
      return const SizedBox.shrink();
    }

    final places = state.filteredPlaces;
    final announcements = state.filteredAnnouncements;
    final emergency = state.nearestEmergencyPlace;
    final mapCenterLat = state.hasRealLocation
        ? state.userLatitude!
        : dataset.centerLat;
    final mapCenterLng = state.hasRealLocation
        ? state.userLongitude!
        : dataset.centerLng;

    if (state.isFullscreenMap) {
      return NearbyMapSection(
        centerLat: mapCenterLat,
        centerLng: mapCenterLng,
        places: places,
        announcements: announcements,
        showAnnouncementsOnMap: state.showAnnouncementsOnMap,
        isFullscreen: true,
        selectedPinId: state.selectedPinId,
        selectedCategory: state.selectedCategory,
        isEn: isEn,
        onToggleFullscreen: ctrl.setFullscreenMap,
        onSelectPin: (id) => ctrl.selectPin(id),
        onClearSelectedPin: ctrl.clearSelectedPin,
        onToggleCategory: ctrl.toggleCategory,
        onUseMyLocation: () => _handleUseMyLocation(isEn),
        tileProvider: widget.tileProvider,
      );
    }

    return ListView(
      key: const Key('nearby-main-list'),
      padding: const EdgeInsets.only(top: 6, bottom: 28),
      children: [
        NearbyCategoryChips(
          selectedCategory: state.selectedCategory,
          isEn: isEn,
          onToggleCategory: ctrl.toggleCategory,
        ),
        const SizedBox(height: 12),
        NearbyMapSection(
          centerLat: mapCenterLat,
          centerLng: mapCenterLng,
          places: places,
          announcements: announcements,
          showAnnouncementsOnMap: state.showAnnouncementsOnMap,
          isFullscreen: false,
          selectedPinId: state.selectedPinId,
          selectedCategory: state.selectedCategory,
          isEn: isEn,
          onToggleFullscreen: ctrl.setFullscreenMap,
          onSelectPin: (id) => ctrl.selectPin(id, openFullscreen: true),
          onClearSelectedPin: ctrl.clearSelectedPin,
          onToggleCategory: ctrl.toggleCategory,
          onUseMyLocation: () => _handleUseMyLocation(isEn),
          tileProvider: widget.tileProvider,
        ),
        if (emergency != null) ...[
          const SizedBox(height: 12),
          NearbyEmergencyBar(
            place: emergency,
            isEn: isEn,
            onCallPhone: (phone) => _handleCallPhone(phone, isEn),
          ),
        ],
        if (state.isEmptyResult) ...[
          const SizedBox(height: 36),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              NearbyL10n.emptyMessage(isEn),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.muted,
              ),
            ),
          ),
        ] else ...[
          if (places.isNotEmpty) ...[
            const SizedBox(height: 16),
            NearbyPlacesSection(
              places: places,
              bookmarkedIds: state.bookmarkedIds,
              isExpanded: state.placesExpanded,
              isFiltered: state.selectedCategory != null ||
                  state.searchQuery.trim().isNotEmpty,
              isEn: isEn,
              onToggleExpand: ctrl.togglePlacesExpanded,
              onTapPlace: (p) => ctrl.selectPin(p.id, openFullscreen: true),
              onToggleBookmark: (p) => _handleToggleBookmark(p, isEn),
              onCallPhone: (phone) => _handleCallPhone(phone, isEn),
            ),
          ],
          if (announcements.isNotEmpty) ...[
            const SizedBox(height: 20),
            NearbyAnnouncementsSection(
              announcements: announcements,
              isExpanded: state.announcementsExpanded,
              isAnnouncementCategory:
                  state.selectedCategory == NearbyCategory.announcements,
              isEn: isEn,
              onToggleExpand: ctrl.toggleAnnouncementsExpanded,
              onViewAnnouncement: (a) =>
                  ctrl.selectPin(a.id, openFullscreen: true),
            ),
          ],
        ],
      ],
    );
  }
}

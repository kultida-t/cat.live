import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/nearby_data.dart';
import '../../domain/repositories/nearby_repository.dart';
import 'nearby_providers.dart';

/// สถานะทั้งหมดของหน้าใกล้ฉัน (/nearby)
class NearbyState {
  const NearbyState({
    this.isLoading = true,
    this.errorMessage,
    this.snapshot,
    this.selectedArea = NearbyAreaId.myLocation,
    this.radiusKm = 3,
    this.searchQuery = '',
    this.selectedCategory,
    this.showAnnouncementsOnMap = true,
    this.isFullscreenMap = true,
    this.selectedPinId,
    this.placesExpanded = false,
    this.announcementsExpanded = false,
    this.isTogglingBookmark = false,
    this.userLatitude,
    this.userLongitude,
    this.isLocating = false,
  });

  final bool isLoading;
  final String? errorMessage;
  final NearbySnapshot? snapshot;
  final NearbyAreaId selectedArea;
  final int radiusKm;
  final String searchQuery;
  final NearbyCategory? selectedCategory;
  final bool showAnnouncementsOnMap;
  final bool isFullscreenMap;
  final String? selectedPinId;
  final bool placesExpanded;
  final bool announcementsExpanded;
  final bool isTogglingBookmark;
  final double? userLatitude;
  final double? userLongitude;
  final bool isLocating;

  bool get hasRealLocation =>
      selectedArea == NearbyAreaId.myLocation &&
      userLatitude != null &&
      userLongitude != null;

  NearbyAreaDataset? get activeDataset => snapshot?.datasetFor(selectedArea);

  Set<String> get bookmarkedIds => snapshot?.bookmarkedPlaceIds ?? const {};

  /// รายการสถานที่ที่ผ่านเงื่อนไขรัศมี + หมวดหมู่ + คำค้นหา
  List<NearbyPlace> get filteredPlaces {
    final dataset = activeDataset;
    if (dataset == null) return const [];
    if (selectedCategory == NearbyCategory.announcements) return const [];

    final q = searchQuery.trim().toLowerCase();
    return dataset.places.where((p) {
      if (p.distanceKm > radiusKm) return false;
      if (selectedCategory != null && !p.matchesCategory(selectedCategory!)) {
        return false;
      }
      if (q.isNotEmpty) {
        final matchTh = p.nameTh.toLowerCase().contains(q);
        final matchEn = p.nameEn.toLowerCase().contains(q);
        if (!matchTh && !matchEn) return false;
      }
      return true;
    }).toList();
  }

  /// รายการประกาศแมวที่ผ่านเงื่อนไขรัศมี + หมวดหมู่ + คำค้นหา
  List<NearbyAnnouncement> get filteredAnnouncements {
    final dataset = activeDataset;
    if (dataset == null) return const [];
    if (selectedCategory != null &&
        selectedCategory != NearbyCategory.announcements) {
      return const [];
    }

    final q = searchQuery.trim().toLowerCase();
    return dataset.announcements.where((a) {
      if (a.distanceKm > radiusKm) return false;
      if (q.isNotEmpty) {
        final matchTh = a.titleTh.toLowerCase().contains(q);
        final matchEn = a.titleEn.toLowerCase().contains(q);
        if (!matchTh && !matchEn) return false;
      }
      return true;
    }).toList();
  }

  /// โรงพยาบาล/คลินิก 24 ชม. ที่ใกล้ที่สุดในพื้นที่ (ไม่ผูกกับตัวกรองหมวดหมู่เพื่อให้กดโทรฉุกเฉินได้ตลอด)
  NearbyPlace? get nearestEmergencyPlace {
    final dataset = activeDataset;
    if (dataset == null) return null;
    for (final p in dataset.places) {
      if (p.isEmergency24h) return p;
    }
    return null;
  }

  bool get isEmptyResult =>
      !isLoading &&
      errorMessage == null &&
      filteredPlaces.isEmpty &&
      filteredAnnouncements.isEmpty;

  NearbyState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    NearbySnapshot? snapshot,
    NearbyAreaId? selectedArea,
    int? radiusKm,
    String? searchQuery,
    NearbyCategory? selectedCategory,
    bool clearCategory = false,
    bool? showAnnouncementsOnMap,
    bool? isFullscreenMap,
    String? selectedPinId,
    bool clearSelectedPin = false,
    bool? placesExpanded,
    bool? announcementsExpanded,
    bool? isTogglingBookmark,
    double? userLatitude,
    double? userLongitude,
    bool clearUserLocation = false,
    bool? isLocating,
  }) {
    return NearbyState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      snapshot: snapshot ?? this.snapshot,
      selectedArea: selectedArea ?? this.selectedArea,
      radiusKm: radiusKm ?? this.radiusKm,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: clearCategory
          ? null
          : (selectedCategory ?? this.selectedCategory),
      showAnnouncementsOnMap:
          showAnnouncementsOnMap ?? this.showAnnouncementsOnMap,
      isFullscreenMap: isFullscreenMap ?? this.isFullscreenMap,
      selectedPinId: clearSelectedPin
          ? null
          : (selectedPinId ?? this.selectedPinId),
      placesExpanded: placesExpanded ?? this.placesExpanded,
      announcementsExpanded:
          announcementsExpanded ?? this.announcementsExpanded,
      isTogglingBookmark: isTogglingBookmark ?? this.isTogglingBookmark,
      userLatitude: clearUserLocation
          ? null
          : (userLatitude ?? this.userLatitude),
      userLongitude: clearUserLocation
          ? null
          : (userLongitude ?? this.userLongitude),
      isLocating: isLocating ?? this.isLocating,
    );
  }
}

/// ตัวควบคุมสถานะของหน้าใกล้ฉัน (/nearby)
class NearbyController extends Notifier<NearbyState> {
  NearbyRepository get _repo => ref.read(nearbyRepositoryProvider);

  @override
  NearbyState build() {
    Future.microtask(load);
    return const NearbyState();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final snapshot = await _repo.fetchNearby();
      state = state.copyWith(isLoading: false, snapshot: snapshot);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void selectArea(NearbyAreaId area) {
    state = state.copyWith(
      selectedArea: area,
      clearSelectedPin: true,
      placesExpanded: false,
      announcementsExpanded: false,
    );
  }

  void cycleRadius() {
    final next = switch (state.radiusKm) {
      3 => 5,
      5 => 1,
      _ => 3,
    };
    state = state.copyWith(radiusKm: next, clearSelectedPin: true);
  }

  void setRadius(int km) {
    state = state.copyWith(radiusKm: km, clearSelectedPin: true);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query, clearSelectedPin: true);
  }

  void toggleCategory(NearbyCategory category) {
    if (state.selectedCategory == category) {
      state = state.copyWith(clearCategory: true, clearSelectedPin: true);
    } else {
      state = state.copyWith(
        selectedCategory: category,
        clearSelectedPin: true,
      );
    }
  }

  void setShowAnnouncementsOnMap(bool value) {
    state = state.copyWith(
      showAnnouncementsOnMap: value,
      clearSelectedPin: true,
    );
  }

  void setFullscreenMap(bool value) {
    state = state.copyWith(
      isFullscreenMap: value,
      clearSelectedPin: !value,
    );
  }

  void selectPin(String pinId, {bool openFullscreen = false}) {
    state = state.copyWith(
      selectedPinId: pinId,
      isFullscreenMap: openFullscreen ? true : state.isFullscreenMap,
    );
  }

  void clearSelectedPin() {
    state = state.copyWith(clearSelectedPin: true);
  }

  void togglePlacesExpanded() {
    state = state.copyWith(placesExpanded: !state.placesExpanded);
  }

  void toggleAnnouncementsExpanded() {
    state = state.copyWith(
      announcementsExpanded: !state.announcementsExpanded,
    );
  }

  Future<bool> toggleBookmark(String placeId) async {
    if (state.isTogglingBookmark || state.snapshot == null) return false;
    state = state.copyWith(isTogglingBookmark: true);
    try {
      final updatedIds = await _repo.toggleBookmark(placeId);
      state = state.copyWith(
        isTogglingBookmark: false,
        snapshot: NearbySnapshot(
          datasets: state.snapshot!.datasets,
          bookmarkedPlaceIds: updatedIds,
        ),
      );
      return updatedIds.contains(placeId);
    } catch (_) {
      state = state.copyWith(isTogglingBookmark: false);
      return state.bookmarkedIds.contains(placeId);
    }
  }

  /// ขอสิทธิ์ GPS และอัปเดตตำแหน่งผู้ใช้จริงบนแผนที่
  Future<bool> requestMyLocation() async {
    if (state.isLocating) return false;
    state = state.copyWith(isLocating: true);
    final result = await ref
        .read(nearbyLocationServiceProvider)
        .getCurrentLocation();
    if (result is NearbyLocationSuccess) {
      state = state.copyWith(
        isLocating: false,
        selectedArea: NearbyAreaId.myLocation,
        userLatitude: result.latitude,
        userLongitude: result.longitude,
        clearSelectedPin: true,
      );
      return true;
    }
    state = state.copyWith(isLocating: false);
    return false;
  }
}

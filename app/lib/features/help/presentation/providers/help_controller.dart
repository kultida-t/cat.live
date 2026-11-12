import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/help_data.dart';
import '../../domain/repositories/help_repository.dart';
import 'help_providers.dart';

/// สถานะทั้งหมดของหน้าช่วยเหลือ (/help)
class HelpState {
  const HelpState({
    this.isLoading = true,
    this.errorMessage,
    this.snapshot,
    this.mainTab = HelpMainTab.nearby,
    this.selectedCategory,
    this.radiusKm = 5,
    this.notifyNearbyPosts = true,
    this.expandedPostIds = const {},
    this.isSubmitting = false,
  });

  final bool isLoading;
  final String? errorMessage;
  final HelpSnapshot? snapshot;
  final HelpMainTab mainTab;
  final HelpCategory? selectedCategory;
  final int radiusKm;
  final bool notifyNearbyPosts;
  final Set<String> expandedPostIds;
  final bool isSubmitting;

  List<HelpPost> get allPosts => snapshot?.posts ?? const [];

  /// จำนวนประกาศแยกตามหมวดหมู่ในระยะที่เลือก
  int countByCategory(HelpCategory category) {
    return allPosts.where((p) {
      if (p.distanceKm > radiusKm) return false;
      return p.category == category;
    }).length;
  }

  /// รายการประกาศในแท็บ "ใกล้คุณ"
  List<HelpPost> get nearbyPosts {
    return allPosts.where((p) {
      if (p.distanceKm > radiusKm) return false;
      if (selectedCategory != null && p.category != selectedCategory) {
        return false;
      }
      return true;
    }).toList();
  }

  /// รายการประกาศในแท็บ "ประกาศของฉัน"
  List<HelpPost> get myPosts {
    return allPosts.where((p) => p.isMine).toList();
  }

  List<HelpPost> get visiblePosts =>
      mainTab == HelpMainTab.nearby ? nearbyPosts : myPosts;

  bool get isEmptyResult =>
      !isLoading && errorMessage == null && visiblePosts.isEmpty;

  HelpState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    HelpSnapshot? snapshot,
    HelpMainTab? mainTab,
    HelpCategory? selectedCategory,
    bool clearCategory = false,
    int? radiusKm,
    bool? notifyNearbyPosts,
    Set<String>? expandedPostIds,
    bool? isSubmitting,
  }) {
    return HelpState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      snapshot: snapshot ?? this.snapshot,
      mainTab: mainTab ?? this.mainTab,
      selectedCategory: clearCategory
          ? null
          : (selectedCategory ?? this.selectedCategory),
      radiusKm: radiusKm ?? this.radiusKm,
      notifyNearbyPosts: notifyNearbyPosts ?? this.notifyNearbyPosts,
      expandedPostIds: expandedPostIds ?? this.expandedPostIds,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

final helpControllerProvider = NotifierProvider<HelpController, HelpState>(
  HelpController.new,
);

class HelpController extends Notifier<HelpState> {
  HelpRepository get _repo => ref.read(helpRepositoryProvider);

  @override
  HelpState build() {
    Future.microtask(load);
    return const HelpState();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final data = await _repo.fetchHelpData();
      state = state.copyWith(isLoading: false, snapshot: data);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void selectMainTab(HelpMainTab tab) {
    if (state.mainTab == tab) return;
    state = state.copyWith(mainTab: tab);
  }

  void selectCategory(HelpCategory? category) {
    if (category == null) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(selectedCategory: category);
    }
  }

  void clearCategory() {
    state = state.copyWith(clearCategory: true);
  }

  void setRadiusKm(int km) {
    state = state.copyWith(radiusKm: km);
  }

  void setNotifyNearbyPosts(bool value) {
    state = state.copyWith(notifyNearbyPosts: value);
  }

  void toggleExpanded(String postId) {
    final next = Set<String>.from(state.expandedPostIds);
    if (!next.add(postId)) {
      next.remove(postId);
    }
    state = state.copyWith(expandedPostIds: next);
  }

  Future<bool> sendClue(String postId) async {
    final current = state.snapshot;
    if (current == null) return false;
    final target = current.posts.where((p) => p.id == postId).firstOrNull;
    if (target == null || target.clueSent) return false;

    final updatedPosts = current.posts
        .map((p) => p.id == postId ? p.copyWith(clueSent: true) : p)
        .toList();
    state = state.copyWith(snapshot: current.copyWith(posts: updatedPosts));
    await _repo.sendClue(postId);
    return true;
  }

  Future<HelpPost?> createPost(CreateHelpPostInput input) async {
    if (state.isSubmitting) return null;
    state = state.copyWith(isSubmitting: true);
    try {
      final created = await _repo.createHelpPost(input);
      final current = state.snapshot;
      if (current != null) {
        state = state.copyWith(
          isSubmitting: false,
          snapshot: current.copyWith(posts: [created, ...current.posts]),
          mainTab: HelpMainTab.nearby,
          clearCategory: true,
        );
      } else {
        state = state.copyWith(isSubmitting: false);
      }
      return created;
    } catch (_) {
      state = state.copyWith(isSubmitting: false);
      return null;
    }
  }

  Future<void> updatePostStatus(String postId, HelpPostStatus status) async {
    final current = state.snapshot;
    if (current == null) return;
    final updatedPosts = current.posts
        .map((p) => p.id == postId ? p.copyWith(status: status) : p)
        .toList();
    state = state.copyWith(snapshot: current.copyWith(posts: updatedPosts));
    await _repo.updatePostStatus(postId, status);
  }

  Future<void> setDonationClosed(String postId, bool isClosed) async {
    final current = state.snapshot;
    if (current == null) return;
    final updatedPosts = current.posts
        .map(
          (p) => p.id == postId && p.donation != null
              ? p.copyWith(donation: p.donation!.copyWith(isClosed: isClosed))
              : p,
        )
        .toList();
    state = state.copyWith(snapshot: current.copyWith(posts: updatedPosts));
    await _repo.setDonationClosed(postId, isClosed);
  }

  Future<void> updatePostContent(
    String postId, {
    required String title,
    required String summary,
    required String location,
  }) async {
    final current = state.snapshot;
    if (current == null) return;
    final updatedPosts = current.posts
        .map(
          (p) => p.id == postId
              ? p.copyWith(
                  titleTh: title,
                  titleEn: title,
                  summaryTh: summary,
                  summaryEn: summary,
                  locationTh: location,
                  locationEn: location,
                )
              : p,
        )
        .toList();
    state = state.copyWith(snapshot: current.copyWith(posts: updatedPosts));
    await _repo.updatePostContent(
      postId,
      title: title,
      summary: summary,
      location: location,
    );
  }
}

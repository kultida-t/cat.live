import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_locale.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/my_cat_data.dart';
import 'my_cat_providers.dart';

enum MyCatLoadStatus { loading, ready, error }

enum MyCatContentTab { photos, careToday, health, caregivers }

const ownerTargetId = 'owner';

class MyCatState {
  const MyCatState({
    this.status = MyCatLoadStatus.loading,
    this.bundle,
    this.selectedTargetId,
    this.activeTab = MyCatContentTab.photos,
    this.photoComments = const {},
    this.errorMessage,
  });

  final MyCatLoadStatus status;
  final MyCatBundle? bundle;
  final String? selectedTargetId;
  final MyCatContentTab activeTab;
  final Map<String, List<CatPhotoComment>> photoComments;
  final String? errorMessage;

  bool get isOwnerSelected => selectedTargetId == ownerTargetId;

  CatProfile? get selectedCat {
    final cats = bundle?.cats ?? const [];
    if (cats.isEmpty || isOwnerSelected) return null;
    for (final cat in cats) {
      if (cat.id == selectedTargetId) return cat;
    }
    return cats.first;
  }

  MyCatState copyWith({
    MyCatLoadStatus? status,
    MyCatBundle? bundle,
    String? selectedTargetId,
    MyCatContentTab? activeTab,
    Map<String, List<CatPhotoComment>>? photoComments,
    String? errorMessage,
  }) {
    return MyCatState(
      status: status ?? this.status,
      bundle: bundle ?? this.bundle,
      selectedTargetId: selectedTargetId ?? this.selectedTargetId,
      activeTab: activeTab ?? this.activeTab,
      photoComments: photoComments ?? this.photoComments,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final myCatControllerProvider = NotifierProvider<MyCatController, MyCatState>(
  MyCatController.new,
);

/// จัดการสถานะหน้าแมวและฉัน — สลับตัวฉัน/แมว, แท็บ, งานดูแลวันนี้ และแก้ไขโปรไฟล์
class MyCatController extends Notifier<MyCatState> {
  int _loadSeq = 0;

  @override
  MyCatState build() {
    Future.microtask(load);
    return const MyCatState();
  }

  Future<void> load() async {
    final seq = ++_loadSeq;
    state = state.copyWith(status: MyCatLoadStatus.loading, errorMessage: null);
    try {
      final bundle = await ref.read(getMyCatBundleProvider)();
      if (!ref.mounted || seq != _loadSeq) return;
      final defaultId =
          state.selectedTargetId ??
          (bundle.cats.isNotEmpty ? bundle.cats.first.id : ownerTargetId);
      state = state.copyWith(
        status: MyCatLoadStatus.ready,
        bundle: bundle,
        selectedTargetId: defaultId,
      );
      ref
          .read(appLocaleProvider.notifier)
          .setLocale(bundle.owner.notifications.locale);
    } on Failure catch (f) {
      if (!ref.mounted || seq != _loadSeq) return;
      state = state.copyWith(
        status: MyCatLoadStatus.error,
        errorMessage: f.message,
      );
    } catch (_) {
      if (!ref.mounted || seq != _loadSeq) return;
      state = state.copyWith(
        status: MyCatLoadStatus.error,
        errorMessage: 'โหลดข้อมูลไม่สำเร็จ ลองใหม่อีกครั้ง',
      );
    }
  }

  void selectProfile(String targetId) {
    if (state.selectedTargetId == targetId) return;
    state = state.copyWith(
      selectedTargetId: targetId,
      activeTab: MyCatContentTab.photos,
    );
  }

  void selectTab(MyCatContentTab tab) {
    if (state.activeTab == tab) return;
    state = state.copyWith(activeTab: tab);
  }

  /// ติ๊กงานดูแลวันนี้แบบ Optimistic — ย้อนกลับพร้อมคืน Failure เมื่อ API ล้มเหลว
  Future<Failure?> toggleCareTask(String taskId) async {
    final bundle = state.bundle;
    final cat = state.selectedCat;
    if (bundle == null || cat == null) return null;

    final targetIndex = cat.careTasks.indexWhere((t) => t.id == taskId);
    if (targetIndex == -1) return null;
    final prevTask = cat.careTasks[targetIndex];
    final nextDone = !prevTask.isDone;

    final optimisticTasks = [
      for (var i = 0; i < cat.careTasks.length; i++)
        i == targetIndex
            ? prevTask.copyWith(
                isDone: nextDone,
                subtitle: nextDone
                    ? 'เสร็จแล้ว · ฉัน · เมื่อสักครู่'
                    : prevTask.subtitle,
              )
            : cat.careTasks[i],
    ];
    final optimisticCat = cat.copyWith(careTasks: optimisticTasks);
    _replaceCat(optimisticCat);

    try {
      await ref.read(toggleCareTaskProvider)(
        catId: cat.id,
        taskId: taskId,
        isDone: nextDone,
      );
      return null;
    } on Failure catch (f) {
      if (ref.mounted) _replaceCat(cat);
      return f;
    } catch (_) {
      if (ref.mounted) _replaceCat(cat);
      return const UnknownFailure('บันทึกไม่สำเร็จ ลองใหม่อีกครั้ง');
    }
  }

  Future<Failure?> updateCat(CatProfile updated) async {
    final bundle = state.bundle;
    if (bundle == null) return null;
    final previous = bundle;
    _replaceCat(updated);
    try {
      final saved = await ref.read(updateCatProfileProvider)(updated);
      if (ref.mounted) _replaceCat(saved);
      return null;
    } on Failure catch (f) {
      if (ref.mounted) state = state.copyWith(bundle: previous);
      return f;
    } catch (_) {
      if (ref.mounted) state = state.copyWith(bundle: previous);
      return const UnknownFailure('บันทึกโปรไฟล์แมวไม่สำเร็จ');
    }
  }

  Future<(CatProfile?, Failure?)> addCat(CatProfile draft) async {
    final bundle = state.bundle;
    if (bundle == null) return (null, null);
    try {
      final created = await ref.read(addCatProfileProvider)(draft);
      if (!ref.mounted) return (created, null);
      state = state.copyWith(
        bundle: bundle.copyWith(cats: [...bundle.cats, created]),
        selectedTargetId: created.id,
        activeTab: MyCatContentTab.photos,
      );
      return (created, null);
    } on Failure catch (f) {
      return (null, f);
    } catch (_) {
      return (null, const UnknownFailure('เพิ่มแมวไม่สำเร็จ ลองใหม่อีกครั้ง'));
    }
  }

  Future<Failure?> updateOwner(OwnerProfile updated) async {
    final bundle = state.bundle;
    if (bundle == null) return null;
    final previous = bundle;
    state = state.copyWith(bundle: bundle.copyWith(owner: updated));
    ref
        .read(appLocaleProvider.notifier)
        .setLocale(updated.notifications.locale);
    try {
      final saved = await ref.read(updateOwnerProfileProvider)(updated);
      if (ref.mounted) {
        state = state.copyWith(bundle: state.bundle!.copyWith(owner: saved));
        ref
            .read(appLocaleProvider.notifier)
            .setLocale(saved.notifications.locale);
      }
      return null;
    } on Failure catch (f) {
      if (ref.mounted) {
        state = state.copyWith(bundle: previous);
        ref
            .read(appLocaleProvider.notifier)
            .setLocale(previous.owner.notifications.locale);
      }
      return f;
    } catch (_) {
      if (ref.mounted) {
        state = state.copyWith(bundle: previous);
        ref
            .read(appLocaleProvider.notifier)
            .setLocale(previous.owner.notifications.locale);
      }
      return const UnknownFailure('บันทึกโปรไฟล์ไม่สำเร็จ');
    }
  }

  Future<Failure?> addPhotoToSelectedCat({
    required String imageSource,
    required String caption,
  }) async {
    final cat = state.selectedCat;
    if (cat == null) return null;
    try {
      final added = await ref.read(addCatPhotoProvider)(
        catId: cat.id,
        imageSource: imageSource,
        caption: caption,
      );
      if (!ref.mounted) return null;
      _replaceCat(cat.copyWith(photos: [added, ...cat.photos]));
      return null;
    } on Failure catch (f) {
      return f;
    } catch (_) {
      return const UnknownFailure('เพิ่มรูปไม่สำเร็จ ลองใหม่อีกครั้ง');
    }
  }

  void updateCaregiverAvatar(String caregiverId, String avatarSource) {
    final cat = state.selectedCat;
    if (cat == null) return;
    _replaceCat(
      cat.copyWith(
        caregivers: cat.caregivers
            .map(
              (c) => c.id == caregiverId
                  ? c.copyWith(avatarSource: avatarSource)
                  : c,
            )
            .toList(),
      ),
    );
  }

  void togglePhotoLike(String catId, String photoId) {
    _updatePhoto(
      catId,
      photoId,
      (p) => p.copyWith(
        isLiked: !p.isLiked,
        likeCount: p.isLiked ? p.likeCount - 1 : p.likeCount + 1,
      ),
    );
  }

  void togglePhotoRepost(String catId, String photoId) {
    _updatePhoto(
      catId,
      photoId,
      (p) => p.copyWith(
        isReposted: !p.isReposted,
        repostCount: p.isReposted ? p.repostCount - 1 : p.repostCount + 1,
      ),
    );
  }

  void togglePhotoSave(String catId, String photoId) {
    _updatePhoto(catId, photoId, (p) => p.copyWith(isSaved: !p.isSaved));
  }

  void setPhotoComments(
    String catId,
    String photoId,
    List<CatPhotoComment> comments,
  ) {
    state = state.copyWith(
      photoComments: {...state.photoComments, photoId: List.of(comments)},
    );
    _updatePhoto(
      catId,
      photoId,
      (p) => p.copyWith(commentCount: comments.length),
    );
  }

  void _updatePhoto(
    String catId,
    String photoId,
    CatPhotoItem Function(CatPhotoItem) updater,
  ) {
    final bundle = state.bundle;
    if (bundle == null) return;
    final cat = bundle.cats.where((c) => c.id == catId).firstOrNull;
    if (cat == null) return;
    _replaceCat(
      cat.copyWith(
        photos: [for (final p in cat.photos) p.id == photoId ? updater(p) : p],
      ),
    );
  }

  void _replaceCat(CatProfile next) {
    final bundle = state.bundle;
    if (bundle == null) return;
    state = state.copyWith(
      bundle: bundle.copyWith(
        cats: bundle.cats.map((c) => c.id == next.id ? next : c).toList(),
      ),
    );
  }
}

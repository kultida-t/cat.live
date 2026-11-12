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
    this.catIdSkins = const {},
    this.errorMessage,
  });

  final MyCatLoadStatus status;
  final MyCatBundle? bundle;
  final String? selectedTargetId;
  final MyCatContentTab activeTab;
  final Map<String, List<CatPhotoComment>> photoComments;
  final Map<String, CatIdSkin> catIdSkins;
  final String? errorMessage;

  CatIdSkin skinForCat(CatProfile cat) =>
      catIdSkins[cat.id] ?? cat.idCard.defaultSkin;

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
    Map<String, CatIdSkin>? catIdSkins,
    String? errorMessage,
  }) {
    return MyCatState(
      status: status ?? this.status,
      bundle: bundle ?? this.bundle,
      selectedTargetId: selectedTargetId ?? this.selectedTargetId,
      activeTab: activeTab ?? this.activeTab,
      photoComments: photoComments ?? this.photoComments,
      catIdSkins: catIdSkins ?? this.catIdSkins,
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

  void setCatIdSkin(String catId, CatIdSkin skin) {
    if (state.catIdSkins[catId] == skin) return;
    state = state.copyWith(catIdSkins: {...state.catIdSkins, catId: skin});
  }

  /// อัปเดตการตั้งค่าแท็ก/เขตปลอดภัย/โหมดแมวหายของแมวตัวที่เลือก
  void updateTrackerInfo(
    String catId,
    CatTrackerInfo Function(CatTrackerInfo current) updater,
  ) {
    final bundle = state.bundle;
    if (bundle == null) return;
    final cat = bundle.cats.where((c) => c.id == catId).firstOrNull;
    if (cat == null) return;
    _replaceCat(cat.copyWith(trackerInfo: updater(cat.trackerInfo)));
  }

  /// เพิ่มบันทึกสุขภาพในสมุดสุขภาพ (/my-cat/health)
  void addHealthRecord(
    String catId,
    HealthRecordEntry entry, {
    BodyOrganId? targetOrgan,
  }) {
    final cat = _findCatById(catId);
    if (cat == null) return;
    final book = cat.healthBook;
    var nextBodyReports = book.bodyReports;
    if (targetOrgan != null) {
      final updated = BodyOrganReport(
        organ: targetOrgan,
        status: BodyOrganStatus.watch,
        summaryTh: entry.titleTh,
        summaryEn: entry.titleEn,
        sourceTh: 'บันทึกเมื่อ ${entry.dateTh}',
        sourceEn: 'Logged ${entry.dateEn}',
      );
      final idx = nextBodyReports.indexWhere((r) => r.organ == targetOrgan);
      nextBodyReports = idx >= 0
          ? [
              for (var i = 0; i < nextBodyReports.length; i++)
                i == idx ? updated : nextBodyReports[i],
            ]
          : [...nextBodyReports, updated];
    }
    _replaceCat(
      cat.copyWith(
        recordCount: cat.recordCount + 1,
        healthBook: book.copyWith(
          records: [entry, ...book.records],
          bodyReports: nextBodyReports,
        ),
      ),
    );
  }

  /// เพิ่มรายการฉีดวัคซีนลงสมุดวัคซีนและไทม์ไลน์ประวัติ
  void addVaccineRecord(String catId, VaccineRecord vaccine) {
    final cat = _findCatById(catId);
    if (cat == null) return;
    final book = cat.healthBook;
    final historyEntry = HealthRecordEntry(
      id: 'rec-${vaccine.id}',
      category: HealthRecordCategory.vaccine,
      dateTh: vaccine.dateTh,
      dateEn: vaccine.dateEn,
      titleTh: vaccine.nameTh,
      titleEn: vaccine.nameEn,
      detailsTh: vaccine.doseTh,
      detailsEn: vaccine.doseEn,
      clinicTh: vaccine.clinicTh,
      clinicEn: vaccine.clinicEn,
    );
    _replaceCat(
      cat.copyWith(
        recordCount: cat.recordCount + 1,
        healthBook: book.copyWith(
          vaccines: [vaccine, ...book.vaccines],
          records: [historyEntry, ...book.records],
        ),
      ),
    );
  }

  /// เพิ่มรายการยาในสมุดสุขภาพ
  void addMedication(String catId, MedicationItem med) {
    final cat = _findCatById(catId);
    if (cat == null) return;
    final book = cat.healthBook;
    _replaceCat(
      cat.copyWith(
        healthBook: book.copyWith(medications: [med, ...book.medications]),
      ),
    );
  }

  /// บันทึกน้ำหนักวันนี้ลงกราฟ 6 เดือน + ไทม์ไลน์ + น้ำหนักบนโปรไฟล์
  void logWeight(
    String catId, {
    required double weightKg,
    required String dateTh,
    required String dateEn,
    String note = '',
  }) {
    final cat = _findCatById(catId);
    if (cat == null) return;
    final book = cat.healthBook;
    final currentPoints = List<WeightPoint>.of(book.weightHistory);
    final newPoint = WeightPoint(monthTh: 'พ.ย.', monthEn: 'Nov', kg: weightKg);
    if (currentPoints.isNotEmpty && currentPoints.last.monthEn == 'Nov') {
      currentPoints[currentPoints.length - 1] = newPoint;
    } else {
      currentPoints.add(newPoint);
      if (currentPoints.length > 6) {
        currentPoints.removeAt(0);
      }
    }

    var deltaTh = '';
    var deltaEn = '';
    var dropping = false;
    if (currentPoints.length >= 2) {
      final baselineIdx = currentPoints.length >= 3
          ? currentPoints.length - 3
          : 0;
      final diff = weightKg - currentPoints[baselineIdx].kg;
      dropping = diff < -0.05;
      final sign = diff >= 0 ? '+' : '';
      final formatted = '$sign${diff.toStringAsFixed(1)}';
      deltaTh = '$formatted กก. ใน 2 เดือน';
      deltaEn = '$formatted kg in 2 months';
    }

    final formattedKg = weightKg.toStringAsFixed(1);
    final entry = HealthRecordEntry(
      id: 'w-${DateTime.now().microsecondsSinceEpoch}',
      category: HealthRecordCategory.weight,
      dateTh: dateTh,
      dateEn: dateEn,
      titleTh: 'บันทึกน้ำหนัก $formattedKg กก.',
      titleEn: 'Logged weight $formattedKg kg',
      detailsTh: note,
      detailsEn: note,
    );

    _replaceCat(
      cat.copyWith(
        weightKg: weightKg,
        recordCount: cat.recordCount + 1,
        healthBook: book.copyWith(
          weightHistory: currentPoints,
          weightDeltaTh: deltaTh,
          weightDeltaEn: deltaEn,
          weightDropping: dropping,
          records: [entry, ...book.records],
        ),
      ),
    );
  }

  /// เพิ่มเอกสารแนบในแท็บเอกสาร
  void addHealthDocument(String catId, HealthDocumentItem doc) {
    final cat = _findCatById(catId);
    if (cat == null) return;
    final book = cat.healthBook;
    _replaceCat(
      cat.copyWith(
        healthBook: book.copyWith(documents: [doc, ...book.documents]),
      ),
    );
  }

  CatProfile? _findCatById(String catId) {
    final bundle = state.bundle;
    if (bundle == null) return null;
    return bundle.cats.where((c) => c.id == catId).firstOrNull;
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

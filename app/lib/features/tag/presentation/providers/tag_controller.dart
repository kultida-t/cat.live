import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/tag_product_data.dart';
import 'tag_providers.dart';

enum TagStatus { loading, empty, error, ready }

class TagState {
  const TagState({
    this.status = TagStatus.loading,
    this.data,
    this.selectedTagColorId = 'teal',
    this.selectedCollarColorId = 'navy',
    this.soundTrigger = 0,
    this.isFlashlightOn = false,
    this.errorMessage,
  });

  final TagStatus status;
  final TagProductData? data;
  final String selectedTagColorId;
  final String selectedCollarColorId;
  final int soundTrigger;
  final bool isFlashlightOn;
  final String? errorMessage;

  TagColorOption? get selectedTagColor {
    final list = data?.tagColors;
    if (list == null || list.isEmpty) return null;
    for (final c in list) {
      if (c.id == selectedTagColorId) return c;
    }
    return list.first;
  }

  TagColorOption? get selectedCollarColor {
    final list = data?.collarColors;
    if (list == null || list.isEmpty) return null;
    for (final c in list) {
      if (c.id == selectedCollarColorId) return c;
    }
    return list.first;
  }

  TagState copyWith({
    TagStatus? status,
    TagProductData? data,
    String? selectedTagColorId,
    String? selectedCollarColorId,
    int? soundTrigger,
    bool? isFlashlightOn,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TagState(
      status: status ?? this.status,
      data: data ?? this.data,
      selectedTagColorId: selectedTagColorId ?? this.selectedTagColorId,
      selectedCollarColorId:
          selectedCollarColorId ?? this.selectedCollarColorId,
      soundTrigger: soundTrigger ?? this.soundTrigger,
      isFlashlightOn: isFlashlightOn ?? this.isFlashlightOn,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final tagControllerProvider = NotifierProvider.autoDispose<TagController, TagState>(
  TagController.new,
);

/// จัดการสถานะหน้า แมว.live Tag (/tag) — โหลดข้อมูล เลือกสีแท็ก/ปลอกคอ ส่งเสียง และไฟฉาย
class TagController extends Notifier<TagState> {
  @override
  TagState build() {
    Future.microtask(_load);
    return const TagState();
  }

  Future<void> _load() async {
    state = state.copyWith(status: TagStatus.loading, clearError: true);
    try {
      final result = await ref.read(loadTagProductProvider).call();
      if (result.tagColors.isEmpty && result.specs.isEmpty) {
        state = state.copyWith(status: TagStatus.empty, data: result);
        return;
      }
      state = state.copyWith(
        status: TagStatus.ready,
        data: result,
        selectedTagColorId: result.tagColors.isNotEmpty
            ? result.tagColors.first.id
            : state.selectedTagColorId,
        selectedCollarColorId: result.collarColors.isNotEmpty
            ? result.collarColors.first.id
            : state.selectedCollarColorId,
      );
    } on Failure catch (f) {
      state = state.copyWith(status: TagStatus.error, errorMessage: f.message);
    } catch (_) {
      state = state.copyWith(
        status: TagStatus.error,
        errorMessage: 'ไม่สามารถโหลดข้อมูลได้ กรุณาลองใหม่อีกครั้ง',
      );
    }
  }

  Future<void> retry() => _load();

  void selectTagColor(String id) {
    state = state.copyWith(selectedTagColorId: id);
  }

  void selectCollarColor(String id) {
    state = state.copyWith(selectedCollarColorId: id);
  }

  void triggerSoundPing() {
    state = state.copyWith(soundTrigger: state.soundTrigger + 1);
  }

  void toggleFlashlight() {
    state = state.copyWith(isFlashlightOn: !state.isFlashlightOn);
  }
}

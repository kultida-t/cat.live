import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../data/datasources/mock_settings_data_source.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/entities/settings_data.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/usecases/settings_usecases.dart';

enum SettingsStatus { loading, empty, error, ready }

class SettingsState {
  const SettingsState({
    this.status = SettingsStatus.loading,
    this.data,
    this.errorMessage,
  });

  final SettingsStatus status;
  final SettingsData? data;
  final String? errorMessage;

  SettingsState copyWith({
    SettingsStatus? status,
    SettingsData? data,
    String? errorMessage,
  }) {
    return SettingsState(
      status: status ?? this.status,
      data: data ?? this.data,
      errorMessage: errorMessage,
    );
  }
}

final mockSettingsDataSourceProvider = Provider<MockSettingsDataSource>(
  (_) => MockSettingsDataSource(),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepositoryImpl(ref.watch(mockSettingsDataSourceProvider)),
);

final settingsControllerProvider =
    NotifierProvider<SettingsController, SettingsState>(
      SettingsController.new,
    );

class SettingsController extends Notifier<SettingsState> {
  late SettingsRepository _repo;

  @override
  SettingsState build() {
    _repo = ref.watch(settingsRepositoryProvider);
    Future.microtask(_load);
    return const SettingsState(status: SettingsStatus.loading);
  }

  Future<void> retry() async {
    state = const SettingsState(status: SettingsStatus.loading);
    await _load();
  }

  Future<void> _load() async {
    try {
      final data = await GetSettingsUseCase(_repo).call();
      if (data.pdpaConsents.isEmpty && data.faqs.isEmpty) {
        state = SettingsState(status: SettingsStatus.empty, data: data);
        return;
      }
      state = SettingsState(status: SettingsStatus.ready, data: data);
    } on Failure catch (f) {
      state = SettingsState(
        status: SettingsStatus.error,
        errorMessage: f.message,
      );
    } catch (_) {
      state = const SettingsState(
        status: SettingsStatus.error,
        errorMessage: 'โหลดการตั้งค่าไม่สำเร็จ ลองใหม่อีกครั้ง',
      );
    }
  }

  Future<bool> _persist(SettingsData next) async {
    final prev = state.data;
    state = state.copyWith(data: next);
    try {
      final saved = await SaveSettingsUseCase(_repo).call(next);
      state = state.copyWith(data: saved);
      return true;
    } catch (_) {
      if (prev != null) state = state.copyWith(data: prev);
      return false;
    }
  }

  Future<bool> togglePush(bool enabled) async {
    final current = state.data;
    if (current == null) return false;
    return _persist(current.copyWith(pushEnabled: enabled));
  }

  Future<bool> toggleQuietHours(bool enabled) async {
    final current = state.data;
    if (current == null) return false;
    return _persist(current.copyWith(quietHoursEnabled: enabled));
  }

  Future<bool> setQuietRange(String start, String end) async {
    final current = state.data;
    if (current == null) return false;
    return _persist(current.copyWith(quietStart: start, quietEnd: end));
  }

  Future<bool> toggleCategory(
    NotificationCategoryKey key,
    bool enabled,
  ) async {
    if (key.isLocked && !enabled) {
      return false;
    }
    final current = state.data;
    if (current == null) return false;
    final nextMap = Map<NotificationCategoryKey, bool>.from(
      current.notificationCategories,
    )..[key] = enabled;
    return _persist(current.copyWith(notificationCategories: nextMap));
  }

  Future<bool> togglePdpaConsent(PdpaConsentKey key, bool granted) async {
    final current = state.data;
    if (current == null) return false;
    final nowLabel = _todayLabel();
    final nextList = current.pdpaConsents
        .map(
          (item) => item.key == key
              ? item.copyWith(granted: granted, updatedAtLabel: nowLabel)
              : item,
        )
        .toList();
    return _persist(current.copyWith(pdpaConsents: nextList));
  }

  Future<bool> requestDataExport() async {
    final current = state.data;
    if (current == null || current.dataExportRequested) return false;
    try {
      await RequestDataExportUseCase(_repo).call();
      state = state.copyWith(
        data: current.copyWith(dataExportRequested: true),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> submitSupportMessage({
    required String subject,
    required String message,
  }) async {
    try {
      await SubmitSupportMessageUseCase(_repo).call(
        subject: subject,
        message: message,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  String _todayLabel() {
    final now = DateTime.now();
    const months = [
      'ม.ค.',
      'ก.พ.',
      'มี.ค.',
      'เม.ย.',
      'พ.ค.',
      'มิ.ย.',
      'ก.ค.',
      'ส.ค.',
      'ก.ย.',
      'ต.ค.',
      'พ.ย.',
      'ธ.ค.',
    ];
    final beYear = now.year + 543;
    return '${now.day} ${months[now.month - 1]} $beYear';
  }
}

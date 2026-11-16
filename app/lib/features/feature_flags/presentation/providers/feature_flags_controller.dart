import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/feature_flags_remote_data_source.dart';
import '../../data/datasources/feature_flags_storage.dart';
import '../../data/repositories/feature_flags_repository_impl.dart';
import '../../domain/entities/feature_flags_data.dart';
import '../../domain/repositories/feature_flags_repository.dart';
import '../../domain/usecases/feature_flags_usecases.dart';

final featureFlagsLocalStorageProvider = Provider<FeatureFlagsLocalStorage>(
  (ref) => InMemoryFeatureFlagsLocalStorage(),
);

final featureFlagsRemoteDataSourceProvider =
    Provider<FeatureFlagsRemoteDataSource>(
      (ref) => const MockFeatureFlagsRemoteDataSource(),
    );

final featureFlagsRepositoryProvider = Provider<FeatureFlagsRepository>((ref) {
  return FeatureFlagsRepositoryImpl(
    remoteDataSource: ref.read(featureFlagsRemoteDataSourceProvider),
    localStorage: ref.read(featureFlagsLocalStorageProvider),
  );
});

enum FeatureFlagsLoadStatus { loading, ready, error }

class FeatureFlagsState {
  const FeatureFlagsState({
    required this.status,
    this.snapshot,
    this.errorMessage,
  });

  final FeatureFlagsLoadStatus status;
  final FeatureFlagsSnapshot? snapshot;
  final String? errorMessage;

  bool isEnabled(AppFeatureFlag flag) {
    final snap = snapshot;
    if (snap == null) return FeatureFlagMetadata.of(flag).defaultEnabled;
    return snap.isEnabled(flag);
  }

  bool get isForceUpdateRequired {
    final snap = snapshot;
    if (snap == null) return false;
    return FeatureFlagsRules.isForceUpdateRequired(
      currentVersion: snap.appVersion,
      minSupportedVersion: snap.minSupportedVersion,
    );
  }

  FeatureFlagsState copyWith({
    FeatureFlagsLoadStatus? status,
    FeatureFlagsSnapshot? snapshot,
    String? errorMessage,
  }) {
    return FeatureFlagsState(
      status: status ?? this.status,
      snapshot: snapshot ?? this.snapshot,
      errorMessage: errorMessage,
    );
  }
}

class FeatureFlagsController extends Notifier<FeatureFlagsState> {
  static const currentAppVersion = '1.0.0';

  String get _currentPlatform {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'ios',
      TargetPlatform.android => 'android',
      _ => 'mobile',
    };
  }

  @override
  FeatureFlagsState build() {
    Future<void>.microtask(_load);
    return FeatureFlagsState(
      status: FeatureFlagsLoadStatus.loading,
      snapshot: FeatureFlagsSnapshot(
        flags: {
          for (final meta in FeatureFlagMetadata.catalog)
            meta.flag: meta.defaultEnabled,
        },
        platform: _currentPlatform,
        appVersion: currentAppVersion,
        minSupportedVersion: '1.0.0',
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _load() async {
    try {
      final repo = ref.read(featureFlagsRepositoryProvider);
      final snap = await repo.loadFlags(
        platform: _currentPlatform,
        appVersion: currentAppVersion,
      );
      state = FeatureFlagsState(
        status: FeatureFlagsLoadStatus.ready,
        snapshot: snap,
      );
    } catch (e) {
      state = FeatureFlagsState(
        status: FeatureFlagsLoadStatus.error,
        snapshot: state.snapshot,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> retry() async {
    state = state.copyWith(status: FeatureFlagsLoadStatus.loading);
    await _load();
  }

  Future<void> toggleFlag(AppFeatureFlag flag, bool enabled) async {
    final current = state.snapshot;
    if (current == null) return;
    final repo = ref.read(featureFlagsRepositoryProvider);
    final next = await repo.setLocalOverride(
      current: current,
      flag: flag,
      enabled: enabled,
    );
    state = FeatureFlagsState(
      status: FeatureFlagsLoadStatus.ready,
      snapshot: next,
    );
  }

  Future<void> setAllPhase2(bool enabled) async {
    final current = state.snapshot;
    if (current == null) return;
    final repo = ref.read(featureFlagsRepositoryProvider);
    final next = await repo.setPhase2Bundle(
      current: current,
      enabled: enabled,
    );
    state = FeatureFlagsState(
      status: FeatureFlagsLoadStatus.ready,
      snapshot: next,
    );
  }

  Future<void> resetToDefault() async {
    final repo = ref.read(featureFlagsRepositoryProvider);
    final next = await repo.resetOverrides(
      platform: _currentPlatform,
      appVersion: currentAppVersion,
    );
    state = FeatureFlagsState(
      status: FeatureFlagsLoadStatus.ready,
      snapshot: next,
    );
  }
}

final featureFlagsControllerProvider =
    NotifierProvider<FeatureFlagsController, FeatureFlagsState>(
      FeatureFlagsController.new,
    );

/// Provider สะดวกสำหรับเช็กสถานะของ Flag รายตัวจากทุกหน้าจอ
final isFeatureEnabledProvider = Provider.family<bool, AppFeatureFlag>(
  (ref, flag) => ref.watch(featureFlagsControllerProvider).isEnabled(flag),
);

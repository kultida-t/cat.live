import '../../domain/entities/feature_flags_data.dart';
import '../../domain/repositories/feature_flags_repository.dart';
import '../datasources/feature_flags_remote_data_source.dart';
import '../datasources/feature_flags_storage.dart';

class FeatureFlagsRepositoryImpl implements FeatureFlagsRepository {
  FeatureFlagsRepositoryImpl({
    required FeatureFlagsRemoteDataSource remoteDataSource,
    required FeatureFlagsLocalStorage localStorage,
  }) : _remote = remoteDataSource,
       _local = localStorage;

  final FeatureFlagsRemoteDataSource _remote;
  final FeatureFlagsLocalStorage _local;

  @override
  Future<FeatureFlagsSnapshot> loadFlags({
    required String platform,
    required String appVersion,
  }) async {
    final base = await _remote.fetchRemoteFlags(
      platform: platform,
      appVersion: appVersion,
    );
    final overrides = await _local.readOverrides();
    if (overrides.isEmpty) return base;

    final merged = Map<AppFeatureFlag, bool>.from(base.flags)
      ..addAll(overrides);
    return base.copyWith(
      flags: merged,
      overriddenFlags: overrides.keys.toSet(),
    );
  }

  @override
  Future<FeatureFlagsSnapshot> setLocalOverride({
    required FeatureFlagsSnapshot current,
    required AppFeatureFlag flag,
    required bool enabled,
  }) async {
    final overrides = Map<AppFeatureFlag, bool>.from(
      await _local.readOverrides(),
    )..[flag] = enabled;
    await _local.writeOverrides(overrides);

    final merged = Map<AppFeatureFlag, bool>.from(current.flags)
      ..[flag] = enabled;
    return current.copyWith(
      flags: merged,
      overriddenFlags: overrides.keys.toSet(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<FeatureFlagsSnapshot> setPhase2Bundle({
    required FeatureFlagsSnapshot current,
    required bool enabled,
  }) async {
    final overrides = Map<AppFeatureFlag, bool>.from(
      await _local.readOverrides(),
    );
    final merged = Map<AppFeatureFlag, bool>.from(current.flags);

    for (final meta in FeatureFlagMetadata.catalog) {
      if (meta.isPhase2Feature) {
        overrides[meta.flag] = enabled;
        merged[meta.flag] = enabled;
      }
    }
    await _local.writeOverrides(overrides);

    return current.copyWith(
      flags: merged,
      overriddenFlags: overrides.keys.toSet(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<FeatureFlagsSnapshot> resetOverrides({
    required String platform,
    required String appVersion,
  }) async {
    await _local.clearOverrides();
    return _remote.fetchRemoteFlags(
      platform: platform,
      appVersion: appVersion,
    );
  }
}

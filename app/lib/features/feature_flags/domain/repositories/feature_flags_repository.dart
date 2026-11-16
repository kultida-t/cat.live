import '../entities/feature_flags_data.dart';

/// สัญญา Repository สำหรับระบบ Feature Flags (OPS-04) — แยกจากแหล่งข้อมูลจริงและ UI
abstract interface class FeatureFlagsRepository {
  Future<FeatureFlagsSnapshot> loadFlags({
    required String platform,
    required String appVersion,
  });

  Future<FeatureFlagsSnapshot> setLocalOverride({
    required FeatureFlagsSnapshot current,
    required AppFeatureFlag flag,
    required bool enabled,
  });

  Future<FeatureFlagsSnapshot> setPhase2Bundle({
    required FeatureFlagsSnapshot current,
    required bool enabled,
  });

  Future<FeatureFlagsSnapshot> resetOverrides({
    required String platform,
    required String appVersion,
  });
}

import '../../domain/entities/feature_flags_data.dart';

/// สัญญา Local Storage สำหรับเก็บค่า Feature Flag cache & overrides บนเครื่อง
/// ออกแบบแยก Interface เพื่อสลับเป็น SharedPreferences / Hive ได้ทันทีโดยไม่แก้ Logic
abstract interface class FeatureFlagsLocalStorage {
  Future<Map<AppFeatureFlag, bool>> readOverrides();
  Future<void> writeOverrides(Map<AppFeatureFlag, bool> overrides);
  Future<void> clearOverrides();
}

/// Implementation แบบเก็บในหน่วยความจำ (UI Mock Baseline / Fallback)
class InMemoryFeatureFlagsLocalStorage implements FeatureFlagsLocalStorage {
  final Map<AppFeatureFlag, bool> _overrides = {};

  @override
  Future<Map<AppFeatureFlag, bool>> readOverrides() async =>
      Map<AppFeatureFlag, bool>.unmodifiable(_overrides);

  @override
  Future<void> writeOverrides(Map<AppFeatureFlag, bool> overrides) async {
    _overrides
      ..clear()
      ..addAll(overrides);
  }

  @override
  Future<void> clearOverrides() async {
    _overrides.clear();
  }
}

import '../entities/feature_flags_data.dart';

/// Business Logic กลางสำหรับประเมิน Feature Flags และ Force Update (แยกออกจาก UI)
abstract final class FeatureFlagsRules {
  /// ตรวจสอบว่าเวอร์ชันแอปปัจจุบันต่ำกว่าขั้นต่ำที่หลังบ้านกำหนดหรือไม่ (Semantic Version)
  static bool isForceUpdateRequired({
    required String currentVersion,
    required String minSupportedVersion,
  }) {
    final currentParts = _parseVersionParts(currentVersion);
    final minParts = _parseVersionParts(minSupportedVersion);
    for (var i = 0; i < 3; i++) {
      if (currentParts[i] < minParts[i]) return true;
      if (currentParts[i] > minParts[i]) return false;
    }
    return false;
  }

  /// นับจำนวนฟีเจอร์ Phase 2 ที่กำลังเปิดใช้งานอยู่
  static int countEnabledPhase2Features(FeatureFlagsSnapshot snapshot) {
    return FeatureFlagMetadata.catalog
        .where((meta) => meta.isPhase2Feature && snapshot.isEnabled(meta.flag))
        .length;
  }

  static List<int> _parseVersionParts(String raw) {
    final clean = raw.split('+').first.split('-').first.trim();
    final pieces = clean.split('.');
    return List<int>.generate(3, (index) {
      if (index >= pieces.length) return 0;
      return int.tryParse(pieces[index]) ?? 0;
    });
  }
}

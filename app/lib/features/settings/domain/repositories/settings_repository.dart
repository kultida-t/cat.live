import '../entities/settings_data.dart';

/// สัญญาดึงและบันทึกข้อมูลหน้าตั้งค่า (/settings)
abstract interface class SettingsRepository {
  Future<SettingsData> getSettings();
  Future<SettingsData> saveSettings(SettingsData next);
  Future<void> requestDataExport();
  Future<void> submitSupportMessage({
    required String subject,
    required String message,
  });
}

import '../../domain/entities/settings_data.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/mock_settings_data_source.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl(this._mock);

  final MockSettingsDataSource _mock;

  @override
  Future<SettingsData> getSettings() => _mock.getSettings();

  @override
  Future<SettingsData> saveSettings(SettingsData next) =>
      _mock.saveSettings(next);

  @override
  Future<void> requestDataExport() => _mock.requestDataExport();

  @override
  Future<void> submitSupportMessage({
    required String subject,
    required String message,
  }) =>
      _mock.submitSupportMessage(subject: subject, message: message);
}

import '../entities/settings_data.dart';
import '../repositories/settings_repository.dart';

class GetSettingsUseCase {
  const GetSettingsUseCase(this._repo);
  final SettingsRepository _repo;

  Future<SettingsData> call() => _repo.getSettings();
}

class SaveSettingsUseCase {
  const SaveSettingsUseCase(this._repo);
  final SettingsRepository _repo;

  Future<SettingsData> call(SettingsData next) => _repo.saveSettings(next);
}

class RequestDataExportUseCase {
  const RequestDataExportUseCase(this._repo);
  final SettingsRepository _repo;

  Future<void> call() => _repo.requestDataExport();
}

class SubmitSupportMessageUseCase {
  const SubmitSupportMessageUseCase(this._repo);
  final SettingsRepository _repo;

  Future<void> call({required String subject, required String message}) =>
      _repo.submitSupportMessage(subject: subject, message: message);
}

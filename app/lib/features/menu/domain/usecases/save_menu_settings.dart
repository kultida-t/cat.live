import '../entities/menu_data.dart';
import '../repositories/menu_repository.dart';

class SaveMenuSettings {
  const SaveMenuSettings(this._repo);

  final MenuRepository _repo;

  Future<MenuSettings> call(MenuSettings settings) =>
      _repo.saveSettings(settings);
}

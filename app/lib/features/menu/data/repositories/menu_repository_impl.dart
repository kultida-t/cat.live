import '../../domain/entities/menu_data.dart';
import '../../domain/repositories/menu_repository.dart';
import '../datasources/mock_menu_data_source.dart';

class MenuRepositoryImpl implements MenuRepository {
  MenuRepositoryImpl(this._mock);

  final MockMenuDataSource _mock;

  @override
  Future<MenuData> getMenuData() => _mock.fetchMenuData();

  @override
  Future<MenuSettings> saveSettings(MenuSettings settings) =>
      _mock.updateSettings(settings);
}

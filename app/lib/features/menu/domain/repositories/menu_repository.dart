import '../entities/menu_data.dart';

abstract interface class MenuRepository {
  Future<MenuData> getMenuData();
  Future<MenuSettings> saveSettings(MenuSettings settings);
}

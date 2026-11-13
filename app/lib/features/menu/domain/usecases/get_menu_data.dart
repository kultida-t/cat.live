import '../entities/menu_data.dart';
import '../repositories/menu_repository.dart';

class GetMenuData {
  const GetMenuData(this._repo);

  final MenuRepository _repo;

  Future<MenuData> call() => _repo.getMenuData();
}

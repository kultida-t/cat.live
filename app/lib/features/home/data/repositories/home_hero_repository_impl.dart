import '../../domain/entities/hero_photo.dart';
import '../../domain/repositories/home_hero_repository.dart';
import '../datasources/mock_home_hero_data_source.dart';

class HomeHeroRepositoryImpl implements HomeHeroRepository {
  const HomeHeroRepositoryImpl(this._dataSource);

  final MockHomeHeroDataSource _dataSource;

  @override
  HomeHeroGallery getHeroGallery() => _dataSource.getGallery();
}

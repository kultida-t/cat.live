import '../entities/hero_photo.dart';
import '../repositories/home_hero_repository.dart';

class GetHomeHeroGallery {
  const GetHomeHeroGallery(this._repository);

  final HomeHeroRepository _repository;

  HomeHeroGallery call() => _repository.getHeroGallery();
}

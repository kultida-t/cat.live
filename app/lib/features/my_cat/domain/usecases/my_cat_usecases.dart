import '../entities/my_cat_data.dart';
import '../repositories/my_cat_repository.dart';

class GetMyCatBundle {
  const GetMyCatBundle(this._repo);
  final MyCatRepository _repo;

  Future<MyCatBundle> call() => _repo.fetchBundle();
}

class ToggleCareTask {
  const ToggleCareTask(this._repo);
  final MyCatRepository _repo;

  Future<void> call({
    required String catId,
    required String taskId,
    required bool isDone,
  }) => _repo.toggleCareTask(catId: catId, taskId: taskId, isDone: isDone);
}

class UpdateCatProfile {
  const UpdateCatProfile(this._repo);
  final MyCatRepository _repo;

  Future<CatProfile> call(CatProfile cat) => _repo.updateCatProfile(cat);
}

class AddCatProfile {
  const AddCatProfile(this._repo);
  final MyCatRepository _repo;

  Future<CatProfile> call(CatProfile newCat) => _repo.addCatProfile(newCat);
}

class UpdateOwnerProfile {
  const UpdateOwnerProfile(this._repo);
  final MyCatRepository _repo;

  Future<OwnerProfile> call(OwnerProfile owner) =>
      _repo.updateOwnerProfile(owner);
}

class AddCatPhoto {
  const AddCatPhoto(this._repo);
  final MyCatRepository _repo;

  Future<CatPhotoItem> call({
    required String catId,
    required String imageSource,
    required String caption,
  }) => _repo.addCatPhoto(
    catId: catId,
    imageSource: imageSource,
    caption: caption,
  );
}

import '../../domain/entities/my_cat_data.dart';
import '../../domain/repositories/my_cat_repository.dart';
import '../datasources/my_cat_remote_data_source.dart';

class MyCatRepositoryImpl implements MyCatRepository {
  const MyCatRepositoryImpl(this._remote);

  final MyCatRemoteDataSource _remote;

  @override
  Future<MyCatBundle> fetchBundle() async =>
      (await _remote.fetchBundle()).toEntity();

  @override
  Future<void> toggleCareTask({
    required String catId,
    required String taskId,
    required bool isDone,
  }) => _remote.toggleCareTask(catId: catId, taskId: taskId, isDone: isDone);

  @override
  Future<CatProfile> updateCatProfile(CatProfile cat) async =>
      (await _remote.updateCatProfile(cat)).toEntity();

  @override
  Future<CatProfile> addCatProfile(CatProfile newCat) async =>
      (await _remote.addCatProfile(newCat)).toEntity();

  @override
  Future<OwnerProfile> updateOwnerProfile(OwnerProfile owner) async =>
      (await _remote.updateOwnerProfile(owner)).toEntity();

  @override
  Future<CatPhotoItem> addCatPhoto({
    required String catId,
    required String imageSource,
    required String caption,
  }) => _remote.addCatPhoto(
    catId: catId,
    imageSource: imageSource,
    caption: caption,
  );
}

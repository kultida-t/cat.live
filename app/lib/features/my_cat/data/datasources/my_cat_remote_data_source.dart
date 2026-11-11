import '../../domain/entities/my_cat_data.dart';
import '../models/my_cat_models.dart';

/// แหล่งข้อมูลหน้าแมวและฉัน — สลับระหว่าง Mock กับ Dio API จริงได้
abstract interface class MyCatRemoteDataSource {
  Future<MyCatBundleModel> fetchBundle();

  Future<void> toggleCareTask({
    required String catId,
    required String taskId,
    required bool isDone,
  });

  Future<CatProfileModel> updateCatProfile(CatProfile cat);

  Future<CatProfileModel> addCatProfile(CatProfile newCat);

  Future<OwnerProfileModel> updateOwnerProfile(OwnerProfile owner);

  Future<CatPhotoItem> addCatPhoto({
    required String catId,
    required String imageSource,
    required String caption,
  });
}

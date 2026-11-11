import '../entities/my_cat_data.dart';

/// สัญญาข้อมูลหน้าแมวและฉัน — แยกจาก UI เพื่อสลับ mock ↔ API จริงได้
abstract interface class MyCatRepository {
  Future<MyCatBundle> fetchBundle();

  Future<void> toggleCareTask({
    required String catId,
    required String taskId,
    required bool isDone,
  });

  Future<CatProfile> updateCatProfile(CatProfile cat);

  Future<CatProfile> addCatProfile(CatProfile newCat);

  Future<OwnerProfile> updateOwnerProfile(OwnerProfile owner);

  Future<CatPhotoItem> addCatPhoto({
    required String catId,
    required String imageSource,
    required String caption,
  });
}

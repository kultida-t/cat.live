import '../models/tag_product_models.dart';

/// แหล่งข้อมูลระยะไกลสำหรับหน้า แมว.live Tag
abstract interface class TagRemoteDataSource {
  Future<TagProductDto> fetchTagProduct();
}

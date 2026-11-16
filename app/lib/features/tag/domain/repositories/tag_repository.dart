import '../entities/tag_product_data.dart';

/// สัญญาการดึงข้อมูลสินค้า แมว.live Tag
abstract interface class TagRepository {
  Future<TagProductData> loadTagProduct();
}

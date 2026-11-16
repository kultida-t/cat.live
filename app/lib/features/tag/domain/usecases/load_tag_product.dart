import '../entities/tag_product_data.dart';
import '../repositories/tag_repository.dart';

/// Use case โหลดข้อมูลสินค้าและตัวเลือกสีของหน้า แมว.live Tag
class LoadTagProduct {
  const LoadTagProduct(this._repository);

  final TagRepository _repository;

  Future<TagProductData> call() => _repository.loadTagProduct();
}

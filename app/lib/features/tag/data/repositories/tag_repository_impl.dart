import 'package:dio/dio.dart';

import '../../../../core/network/dio_failure_mapper.dart';
import '../../domain/entities/tag_product_data.dart';
import '../../domain/repositories/tag_repository.dart';
import '../datasources/tag_remote_data_source.dart';

/// Repository เชื่อมข้อมูลสินค้า แมว.live Tag และแปลง DioException เป็น Failure
class TagRepositoryImpl implements TagRepository {
  const TagRepositoryImpl(this._remote);

  final TagRemoteDataSource _remote;

  @override
  Future<TagProductData> loadTagProduct() async {
    try {
      final dto = await _remote.fetchTagProduct();
      return dto.toEntity();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}

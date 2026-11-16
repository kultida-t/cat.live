import 'package:dio/dio.dart';

import '../models/tag_product_models.dart';
import 'tag_remote_data_source.dart';

/// เรียก API ข้อมูล แมว.live Tag จริงผ่าน Dio (ใช้เมื่อ USE_MOCK_DATA=false)
class DioTagDataSource implements TagRemoteDataSource {
  const DioTagDataSource(this._dio);

  final Dio _dio;

  @override
  Future<TagProductDto> fetchTagProduct() async {
    final res = await _dio.get<Map<String, dynamic>>('/v1/tag');
    return TagProductDto.fromJson(res.data!);
  }
}

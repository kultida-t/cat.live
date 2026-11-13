import 'package:dio/dio.dart';

import '../models/search_models.dart';
import 'search_remote_data_source.dart';

/// เรียก API ค้นหาจริงผ่าน Dio (ใช้เมื่อ USE_MOCK_DATA=false)
class DioSearchDataSource implements SearchRemoteDataSource {
  const DioSearchDataSource(this._dio);

  final Dio _dio;

  @override
  Future<SearchDataModel> fetchSearchData() async {
    final res = await _dio.get<Map<String, dynamic>>('/v1/search');
    return SearchDataModel.fromJson(res.data!);
  }
}

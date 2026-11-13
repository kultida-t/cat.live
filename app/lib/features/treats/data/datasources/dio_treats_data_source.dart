import 'package:dio/dio.dart';

import '../models/treats_models.dart';
import 'treats_remote_data_source.dart';

/// เรียก API เลี้ยงขนมแมวจริงผ่าน Dio (ใช้เมื่อ USE_MOCK_DATA=false)
class DioTreatsDataSource implements TreatsRemoteDataSource {
  const DioTreatsDataSource(this._dio);

  final Dio _dio;

  @override
  Future<TreatsDataModel> fetchTreatsData() async {
    final res = await _dio.get<Map<String, dynamic>>('/v1/treats');
    return TreatsDataModel.fromJson(res.data!);
  }
}

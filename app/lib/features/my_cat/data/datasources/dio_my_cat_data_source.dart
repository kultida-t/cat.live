import 'package:dio/dio.dart';

import '../../../../core/network/dio_failure_mapper.dart';
import '../../domain/entities/my_cat_data.dart';
import '../models/my_cat_models.dart';
import 'my_cat_remote_data_source.dart';

/// แหล่งข้อมูลหน้าแมวและฉันจาก Backend API จริง (พร้อมใช้งานเมื่อเปิด API)
class DioMyCatDataSource implements MyCatRemoteDataSource {
  DioMyCatDataSource(this._dio);

  final Dio _dio;

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<MyCatBundleModel> fetchBundle() => _guard(() async {
    final res = await _dio.get<Map<String, dynamic>>('/v1/my-cat');
    return MyCatBundleModel.fromJson(res.data!);
  });

  @override
  Future<void> toggleCareTask({
    required String catId,
    required String taskId,
    required bool isDone,
  }) => _guard(
    () => _dio.patch<void>(
      '/v1/cats/$catId/care-tasks/$taskId',
      data: {'is_done': isDone},
    ),
  );

  @override
  Future<CatProfileModel> updateCatProfile(CatProfile cat) => _guard(() async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/v1/cats/${cat.id}',
      data: CatProfileModel.toJson(cat),
    );
    return CatProfileModel.fromJson(res.data!);
  });

  @override
  Future<CatProfileModel> addCatProfile(CatProfile newCat) => _guard(() async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/v1/cats',
      data: CatProfileModel.toJson(newCat),
    );
    return CatProfileModel.fromJson(res.data!);
  });

  @override
  Future<OwnerProfileModel> updateOwnerProfile(OwnerProfile owner) =>
      _guard(() async {
        final res = await _dio.put<Map<String, dynamic>>(
          '/v1/me/profile',
          data: OwnerProfileModel.toJson(owner),
        );
        return OwnerProfileModel.fromJson(res.data!);
      });

  @override
  Future<CatPhotoItem> addCatPhoto({
    required String catId,
    required String imageSource,
    required String caption,
  }) => _guard(() async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/v1/cats/$catId/photos',
      data: {'image_url': imageSource, 'caption': caption},
    );
    final data = res.data!;
    return CatPhotoItem(
      id: data['id'] as String,
      imageSource: data['image_url'] as String,
      caption: data['caption'] as String? ?? caption,
      relativeTime: 'เมื่อสักครู่',
    );
  });
}

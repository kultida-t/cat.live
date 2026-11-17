import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/network/dio_failure_mapper.dart';

/// รูปโปรไฟล์ที่เคยใช้ (จาก `/media/avatars`)
class AvatarHistoryItem {
  const AvatarHistoryItem({
    required this.id,
    required this.url,
    required this.isCurrent,
  });

  final String id;
  final String url;
  final bool isCurrent;
}

/// เรียก API รูปโปรไฟล์จริง: ส่งรูปใหม่, ดูรูปที่เคยใช้, เลือกรูปเก่ากลับมา
class AvatarApi {
  AvatarApi(this._dio);

  final Dio _dio;

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<List<AvatarHistoryItem>> listAvatars() => _guard(() async {
    final res = await _dio.get<List<dynamic>>('/media/avatars');
    return [
      for (final e in res.data!)
        AvatarHistoryItem(
          id: (e as Map)['id'] as String,
          url: e['url'] as String,
          isCurrent: e['isCurrent'] as bool,
        ),
    ];
  });

  /// ส่งรูป PNG ที่ลบข้อมูลแฝงแล้วขึ้นระบบ — ผลจะขึ้นในรายการหลังประมวลผลเสร็จ
  Future<void> uploadAvatar(Uint8List png) => _guard(() async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        png,
        filename: 'avatar.png',
        contentType: DioMediaType('image', 'png'),
      ),
    });
    await _dio.post<void>('/media/avatar', data: form);
  });

  Future<void> selectAvatar(String id) => _guard(() async {
    await _dio.post<void>('/media/avatars/$id/select');
  });
}

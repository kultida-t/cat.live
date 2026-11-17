import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/error/failure.dart';
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
  /// [_uploadDio] ใช้ส่งไฟล์ไป S3 ด้วย presigned URL — ต้องไม่แนบ token ของแอป (ไม่งั้นลายเซ็นผิด)
  AvatarApi(this._dio, {Dio? uploadDio}) : _uploadDio = uploadDio ?? Dio();

  final Dio _dio;
  final Dio _uploadDio;

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

  /// ส่งรูป PNG ที่ลบข้อมูลแฝงแล้วขึ้นระบบ: ขอ presigned URL → อัปโหลดตรงไป S3 → แจ้งเสร็จ
  /// ผลจะขึ้นในรายการหลังประมวลผลเสร็จ
  Future<void> uploadAvatar(Uint8List png) => _guard(() async {
    final slot = await _dio.post<Map<String, dynamic>>(
      '/media/avatar/upload-url',
      data: {'contentType': 'image/png', 'fileSize': png.length},
    );
    final uploadId = slot.data!['uploadId'] as String;
    final headers = Map<String, dynamic>.from(slot.data!['headers'] as Map);
    try {
      await _uploadDio.put<void>(
        slot.data!['uploadUrl'] as String,
        data: png,
        options: Options(headers: headers),
      );
    } on DioException {
      throw const UnknownFailure('อัปโหลดรูปไม่สำเร็จ ลองใหม่อีกครั้ง');
    }
    await _dio.post<void>('/media/avatar/$uploadId/complete');
  });

  Future<void> selectAvatar(String id) => _guard(() async {
    await _dio.post<void>('/media/avatars/$id/select');
  });
}

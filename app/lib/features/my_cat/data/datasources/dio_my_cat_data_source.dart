import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/network/dio_failure_mapper.dart';
import '../../domain/entities/my_cat_data.dart';
import '../models/my_cat_models.dart';
import 'my_cat_remote_data_source.dart';

/// แหล่งข้อมูลหน้าแมวและฉันจาก Backend API จริง (พร้อมใช้งานเมื่อเปิด API)
class DioMyCatDataSource implements MyCatRemoteDataSource {
  /// [_uploadDio] ใช้ส่งไฟล์ขึ้น S3 ด้วย presigned URL เท่านั้น — ห้ามแนบ token ของแอป (ไม่งั้นลายเซ็นผิด)
  DioMyCatDataSource(this._dio, {Dio? uploadDio})
    : _uploadDio = uploadDio ?? Dio();

  final Dio _dio;
  final Dio _uploadDio;

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  /// โหลดเจ้าของจาก `/auth/me` และแมวจาก `/cats` — ฟิลด์ที่ backend ยังไม่มี
  /// (ชื่อผู้ใช้ รูป สุขภาพ Tag) ส่งค่าว่างไว้ ไม่ใช้ค่าตัวอย่าง
  @override
  Future<MyCatBundleModel> fetchBundle() => _guard(() async {
    final me = (await _dio.get<Map<String, dynamic>>('/auth/me')).data!;
    final cats = (await _dio.get<List<dynamic>>('/cats')).data!;
    return MyCatBundleModel.fromJson({
      'owner': _ownerJson(me),
      'cats': cats
          .map((c) => _catJson(Map<String, dynamic>.from(c as Map)))
          .toList(),
    });
  });

  static Map<String, dynamic> _ownerJson(Map<String, dynamic> me) => {
    'id': me['id'],
    'username': '',
    'display_name': me['displayName'] ?? '',
    'bio': '',
    'district': '',
    'member_since': '',
    'avatar_url': me['avatarUrl'] ?? '',
    'user_private': {
      'phone_verified': me['phoneMasked'] != null,
      'donation_account': {
        'method': 'promptpay',
        'account_number': '',
        'account_name': '',
      },
    },
  };

  static Map<String, dynamic> _catJson(Map<String, dynamic> c) {
    final birth = c['birthDate'] == null
        ? null
        : DateTime.parse(c['birthDate'] as String);
    final photos =
        (c['photoUrls'] as List?)?.whereType<String>().toList() ??
        const <String>[];
    return {
      'id': c['id'],
      'public_id': c['publicId'],
      'name': c['name'],
      'breed': c['breed'] ?? '',
      'sex': c['sex'],
      'neutered': c['neutered'] ?? false,
      'age_label': birth == null ? '' : _ageLabel(birth, DateTime.now()),
      'adopted_year': birth?.year ?? DateTime.now().year,
      'weight_kg': c['weightKg'] ?? 0.0,
      'avatar_url': photos.isNotEmpty ? photos.first : '',
      'photos': [
        for (final url in photos) {'id': url, 'image_url': url},
      ],
    };
  }

  /// ข้อความอายุตามรูปแบบที่หน้าแมวและฉันแสดง (`3 ปี`, `5 เดือน`, `น้อยกว่า 3 เดือน`)
  static String _ageLabel(DateTime birth, DateTime now) {
    var months = (now.year - birth.year) * 12 + now.month - birth.month;
    if (now.day < birth.day) months--;
    if (months < 3) return 'น้อยกว่า 3 เดือน';
    return months >= 12 ? '${months ~/ 12} ปี' : '$months เดือน';
  }

  /// แปลงค่ารูปในฟอร์มเป็น URL จริง: `file:` อัปโหลดขึ้น S3 ก่อน, URL อยู่แล้วใช้เลย, asset/ว่าง = ไม่มีรูป
  Future<String?> _resolvePhotoUrl(String source) async {
    if (source.isEmpty) return null;
    if (source.startsWith('file:')) return _uploadLocalPhoto(source);
    if (source.startsWith('http')) return source;
    return null;
  }

  /// อัปโหลดไฟล์รูปในเครื่อง (ลบข้อมูลแฝงแล้วจากฝั่งฟอร์ม) ขึ้น S3 ผ่าน presigned URL
  Future<String> _uploadLocalPhoto(String fileUri) async {
    final bytes = await File(fileUri.substring(5)).readAsBytes();
    final slot = await _dio.post<Map<String, dynamic>>(
      '/media/cat-photos/upload-url',
      data: {'contentType': 'image/png', 'fileSize': bytes.length},
    );
    try {
      await _uploadDio.put<void>(
        slot.data!['uploadUrl'] as String,
        data: bytes,
        options: Options(
          headers: Map<String, dynamic>.from(slot.data!['headers'] as Map),
        ),
      );
    } on DioException {
      throw const UnknownFailure('อัปโหลดรูปไม่สำเร็จ ลองใหม่อีกครั้ง');
    }
    return slot.data!['imageUrl'] as String;
  }

  /// body สำหรับสร้าง/แก้แมว — ส่งเฉพาะฟิลด์ที่ backend รับ (snake_case ตามสัญญา)
  Map<String, dynamic> _catMutationJson(CatProfile c, String? photoUrl) => {
    'name': c.name,
    'breed': c.breed,
    'sex': c.gender == CatGender.male ? 'male' : 'female',
    'neutered': c.neutered,
    'age_label': c.ageLabel,
    'weight_kg': c.weightKg,
    'photo_url': ?photoUrl,
  };

  @override
  Future<void> toggleCareTask({
    required String catId,
    required String taskId,
    required bool isDone,
  }) => _guard(
    () => _dio.patch<void>(
      '/cats/$catId/care-tasks/$taskId',
      data: {'is_done': isDone},
    ),
  );

  @override
  Future<CatProfileModel> updateCatProfile(CatProfile cat) => _guard(() async {
    final photoUrl = await _resolvePhotoUrl(cat.avatarSource);
    final res = await _dio.put<Map<String, dynamic>>(
      '/cats/${cat.id}',
      data: _catMutationJson(cat, photoUrl),
    );
    return CatProfileModel.fromJson(
      _catJson(Map<String, dynamic>.from(res.data!)),
    );
  });

  @override
  Future<CatProfileModel> addCatProfile(CatProfile newCat) => _guard(() async {
    final photoUrl = await _resolvePhotoUrl(newCat.avatarSource);
    final res = await _dio.post<Map<String, dynamic>>(
      '/cats',
      data: _catMutationJson(newCat, photoUrl),
    );
    return CatProfileModel.fromJson(
      _catJson(Map<String, dynamic>.from(res.data!)),
    );
  });

  @override
  Future<OwnerProfileModel> updateOwnerProfile(OwnerProfile owner) =>
      _guard(() async {
        // backend ตอนนี้รับเฉพาะ displayName — ฟิลด์อื่นของโปรไฟล์ยังเก็บฝั่งแอปไว้ก่อน
        await _dio.put<void>(
          '/me/profile',
          data: {'displayName': owner.displayName},
        );
        return OwnerProfileModel(entity: owner);
      });

  @override
  Future<CatPhotoItem> addCatPhoto({
    required String catId,
    required String imageSource,
    required String caption,
  }) => _guard(() async {
    final url = await _resolvePhotoUrl(imageSource) ?? imageSource;
    final res = await _dio.post<Map<String, dynamic>>(
      '/cats/$catId/photos',
      data: {'image_url': url, 'caption': caption},
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

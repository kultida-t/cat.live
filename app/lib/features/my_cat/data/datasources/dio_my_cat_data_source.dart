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
    'avatar_url': '',
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
    return {
      'id': c['id'],
      'public_id': c['publicId'],
      'name': c['name'],
      'breed': c['breed'] ?? '',
      'sex': c['sex'],
      'neutered': c['neutered'] ?? false,
      'age_label': birth == null ? '' : _ageLabel(birth, DateTime.now()),
      'adopted_year': birth?.year ?? DateTime.now().year,
    };
  }

  /// ข้อความอายุตามรูปแบบที่หน้าแมวและฉันแสดง (`3 ปี`, `5 เดือน`, `น้อยกว่า 3 เดือน`)
  static String _ageLabel(DateTime birth, DateTime now) {
    var months = (now.year - birth.year) * 12 + now.month - birth.month;
    if (now.day < birth.day) months--;
    if (months < 3) return 'น้อยกว่า 3 เดือน';
    return months >= 12 ? '${months ~/ 12} ปี' : '$months เดือน';
  }

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

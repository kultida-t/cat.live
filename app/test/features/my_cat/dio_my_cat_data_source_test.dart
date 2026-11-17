import 'package:catlive/features/my_cat/data/datasources/dio_my_cat_data_source.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Dio ปลอมที่ตอบ `/auth/me` และ `/cats` ตามที่กำหนด
Dio _fakeDio({required Object me, required List<dynamic> cats}) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final data = switch (options.path) {
          '/auth/me' => me,
          '/cats' => cats,
          _ => null,
        };
        handler.resolve(
          Response(requestOptions: options, data: data, statusCode: 200),
        );
      },
    ),
  );
  return dio;
}

void main() {
  final me = {
    'id': 'user-1',
    'displayName': 'พี่มาเต็ม',
    'phoneMasked': '089-XXX-0002',
    'birthYear': 1990,
  };

  test('แมวจริงแสดงชื่อ รหัส และอายุจากฐานข้อมูล ไม่ใช้ค่าตัวอย่างจาก mock', () async {
    final now = DateTime.now();
    final birth = DateTime.utc(now.year - 2, now.month, 1);
    final bundle = await DioMyCatDataSource(
      _fakeDio(
        me: me,
        cats: [
          {
            'id': 'cat-1',
            'publicId': 'MAW000123',
            'name': 'มะลิ',
            'breed': 'วิเชียรมาศ',
            'sex': 'female',
            'neutered': true,
            'birthDate': birth.toIso8601String(),
            'photoUrls': <String>[],
            'status': 'normal',
            'role': 'owner',
          },
        ],
      ),
    ).fetchBundle();

    final entity = bundle.toEntity();
    expect(entity.owner.displayName, 'พี่มาเต็ม');
    expect(entity.owner.handle, isEmpty);
    expect(entity.owner.isPhoneVerified, isTrue);
    expect(entity.cats, hasLength(1));
    final cat = entity.cats.single;
    expect(cat.publicId, 'MAW000123');
    expect(cat.name, 'มะลิ');
    expect(cat.ageLabel, '2 ปี');
    expect(cat.photos, isEmpty);
    expect(cat.careTasks, isEmpty);
    expect(cat.healthHighlights, isEmpty);
    expect(cat.healthBook.calendarEvents, isEmpty);
  });

  test('ยังไม่มีแมวเลย → ได้รายการว่าง', () async {
    final bundle = await DioMyCatDataSource(
      _fakeDio(me: me, cats: const []),
    ).fetchBundle();

    expect(bundle.toEntity().cats, isEmpty);
  });
}

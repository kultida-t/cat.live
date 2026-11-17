import 'dart:typed_data';

import 'package:catlive/core/error/failure.dart';
import 'package:catlive/features/my_cat/data/datasources/avatar_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Dio ปลอมที่บันทึกคำขอไว้ และตอบตาม [respond]
class _Recorder {
  final List<RequestOptions> requests = [];
  Dio dio(Object? Function(RequestOptions options) respond) {
    final d = Dio(BaseOptions(baseUrl: 'http://test'));
    d.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          handler.resolve(
            Response(
              requestOptions: options,
              data: respond(options),
              statusCode: 200,
            ),
          );
        },
      ),
    );
    return d;
  }
}

void main() {
  test('รายการรูปที่เคยใช้แปลงเป็นรายการพร้อมสถานะรูปปัจจุบัน', () async {
    final rec = _Recorder();
    final items = await AvatarApi(
      rec.dio(
        (_) => [
          {'id': 'a1', 'url': 'https://cdn.test/a.webp', 'isCurrent': true},
          {'id': 'a2', 'url': 'https://cdn.test/b.webp', 'isCurrent': false},
        ],
      ),
    ).listAvatars();

    expect(rec.requests.single.path, '/media/avatars');
    expect(items.map((e) => e.id), ['a1', 'a2']);
    expect(items.first.isCurrent, isTrue);
    expect(items.last.url, 'https://cdn.test/b.webp');
  });

  test('เลือกรูปเก่าส่งไปที่เส้นทางของรูปนั้น', () async {
    final rec = _Recorder();
    await AvatarApi(rec.dio((_) => null)).selectAvatar('a2');

    expect(rec.requests.single.method, 'POST');
    expect(rec.requests.single.path, '/media/avatars/a2/select');
  });

  test(
    'อัปโหลดรูป: ขอ URL → PUT ไป S3 โดยไม่แนบ token → แจ้งเสร็จ ตามลำดับ',
    () async {
      final api = _Recorder();
      final s3 = _Recorder();
      final png = Uint8List.fromList([137, 80, 78, 71]);
      final apiDio = api.dio((o) {
        if (o.path == '/media/avatar/upload-url') {
          return {
            'uploadId': 'u1',
            'uploadUrl': 'https://s3.test/catlive/avatars/me/a.png?sig=1',
            'expiresInSeconds': 300,
            'headers': {'Content-Type': 'image/png'},
          };
        }
        return null;
      });
      apiDio.options.headers['Authorization'] = 'Bearer secret';

      await AvatarApi(apiDio, uploadDio: s3.dio((_) => null)).uploadAvatar(png);

      expect(api.requests.map((r) => r.path), [
        '/media/avatar/upload-url',
        '/media/avatar/u1/complete',
      ]);
      expect(api.requests.first.data, {
        'contentType': 'image/png',
        'fileSize': png.length,
      });
      final put = s3.requests.single;
      expect(put.method, 'PUT');
      expect(
        put.uri.toString(),
        contains('https://s3.test/catlive/avatars/me/a.png'),
      );
      expect(put.headers['Content-Type'], 'image/png');
      expect(put.headers.containsKey('Authorization'), isFalse);
      expect(put.data, png);
    },
  );

  test(
    'อัปโหลดไป S3 ไม่สำเร็จ → ไม่แจ้งเสร็จ และแจ้งผู้ใช้เป็นข้อความไทย',
    () async {
      final api = _Recorder();
      final apiDio = api.dio(
        (o) => o.path == '/media/avatar/upload-url'
            ? {
                'uploadId': 'u1',
                'uploadUrl': 'https://s3.test/x',
                'headers': {'Content-Type': 'image/png'},
              }
            : null,
      );
      final failing = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (o, h) => h.reject(
              DioException(
                requestOptions: o,
                type: DioExceptionType.connectionError,
              ),
            ),
          ),
        );

      await expectLater(
        AvatarApi(apiDio, uploadDio: failing).uploadAvatar(Uint8List(4)),
        throwsA(isA<Failure>()),
      );
      expect(api.requests.map((r) => r.path), ['/media/avatar/upload-url']);
    },
  );
}

import 'dart:typed_data';

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

  test('ส่งรูป PNG เป็นฟิลด์ file แบบ multipart', () async {
    final rec = _Recorder();
    final png = Uint8List.fromList([137, 80, 78, 71]);
    await AvatarApi(rec.dio((_) => null)).uploadAvatar(png);

    final req = rec.requests.single;
    expect(req.path, '/media/avatar');
    expect(req.method, 'POST');
    final form = req.data as FormData;
    final file = form.files.single;
    expect(file.key, 'file');
    expect(file.value.contentType?.mimeType, 'image/png');
    expect(file.value.length, png.length);
  });
}

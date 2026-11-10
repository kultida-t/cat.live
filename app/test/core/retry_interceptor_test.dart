import 'dart:typed_data';

import 'package:catlive/core/network/dio_failure_mapper.dart';
import 'package:catlive/core/error/failure.dart';
import 'package:catlive/core/network/retry_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// adapter จำลอง: ตอบตามลำดับที่กำหนด แล้วนับจำนวนครั้งที่ถูกเรียก
class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this._script);

  final List<ResponseBody Function(RequestOptions)> _script;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final step = _script[calls < _script.length ? calls : _script.length - 1];
    calls++;
    return step(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _status(int code) => ResponseBody.fromString(
  '{}',
  code,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);

Dio _dioWith(_ScriptedAdapter adapter, List<Duration> sleeps) {
  final dio = Dio(BaseOptions(baseUrl: 'https://test.local'))
    ..httpClientAdapter = adapter;
  dio.interceptors.add(
    RetryInterceptor(dio, sleep: (d) async => sleeps.add(d)),
  );
  return dio;
}

void main() {
  test(
    'GET ที่ได้ 503 สองครั้งแล้วสำเร็จ — ลองซ้ำและเว้นระยะเพิ่มเป็นสองเท่า',
    () async {
      final adapter = _ScriptedAdapter([
        (_) => _status(503),
        (_) => _status(503),
        (_) => _status(200),
      ]);
      final sleeps = <Duration>[];
      final res = await _dioWith(adapter, sleeps).get<dynamic>('/ping');

      expect(res.statusCode, 200);
      expect(adapter.calls, 3);
      expect(sleeps, [
        const Duration(milliseconds: 500),
        const Duration(milliseconds: 1000),
      ]);
    },
  );

  test(
    'ได้ 5xx ต่อเนื่อง — หยุดที่ 3 ครั้งซ้ำ (รวม 4 คำขอ) แล้วโยน error',
    () async {
      final adapter = _ScriptedAdapter([(_) => _status(500)]);
      final dio = _dioWith(adapter, []);

      await expectLater(
        dio.get<dynamic>('/ping'),
        throwsA(isA<DioException>()),
      );
      expect(adapter.calls, 4);
    },
  );

  test('POST ไม่ถูกส่งซ้ำ เพราะอาจทำรายการซ้ำสองครั้ง', () async {
    final adapter = _ScriptedAdapter([(_) => _status(503)]);
    final dio = _dioWith(adapter, []);

    await expectLater(dio.post<dynamic>('/like'), throwsA(isA<DioException>()));
    expect(adapter.calls, 1);
  });

  test('4xx ไม่ถูกส่งซ้ำ', () async {
    final adapter = _ScriptedAdapter([(_) => _status(404)]);
    final dio = _dioWith(adapter, []);

    await expectLater(
      dio.get<dynamic>('/missing'),
      throwsA(isA<DioException>()),
    );
    expect(adapter.calls, 1);
  });

  group('mapDioException', () {
    DioException err(DioExceptionType type, [int? status]) {
      final opts = RequestOptions(path: '/x');
      return DioException(
        requestOptions: opts,
        type: type,
        response: status == null
            ? null
            : Response(requestOptions: opts, statusCode: status),
      );
    }

    test('เน็ตหลุด/หมดเวลา → NetworkFailure', () {
      expect(
        mapDioException(err(DioExceptionType.connectionError)),
        isA<NetworkFailure>(),
      );
      expect(
        mapDioException(err(DioExceptionType.receiveTimeout)),
        isA<NetworkFailure>(),
      );
    });

    test('401/403 → UnauthorizedFailure, 404 → NotFoundFailure, 5xx → ServerFailure', () {
      expect(
        mapDioException(err(DioExceptionType.badResponse, 401)),
        isA<UnauthorizedFailure>(),
      );
      expect(
        mapDioException(err(DioExceptionType.badResponse, 403)),
        isA<UnauthorizedFailure>(),
      );
      expect(
        mapDioException(err(DioExceptionType.badResponse, 404)),
        isA<NotFoundFailure>(),
      );
      expect(
        mapDioException(err(DioExceptionType.badResponse, 502)),
        isA<ServerFailure>(),
      );
    });

    test('อย่างอื่น → UnknownFailure', () {
      expect(
        mapDioException(err(DioExceptionType.cancel)),
        isA<UnknownFailure>(),
      );
      expect(
        mapDioException(err(DioExceptionType.badResponse, 418)),
        isA<UnknownFailure>(),
      );
    });
  });
}

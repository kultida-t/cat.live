import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';

/// ลองส่งคำขอซ้ำอัตโนมัติเมื่อเน็ตหลุด/เซิร์ฟเวอร์ตอบ 5xx โดยเว้นระยะเพิ่มขึ้นเรื่อย ๆ
/// (exponential backoff) — ทำเฉพาะคำขอที่ส่งซ้ำได้ปลอดภัย (GET/HEAD/PUT/DELETE)
class RetryInterceptor extends Interceptor {
  RetryInterceptor(
    this._dio, {
    this.maxRetries = 3,
    this.baseDelay = const Duration(milliseconds: 500),
    Future<void> Function(Duration)? sleep,
  }) : _sleep = sleep ?? Future<void>.delayed;

  final Dio _dio;
  final int maxRetries;
  final Duration baseDelay;
  final Future<void> Function(Duration) _sleep;

  static const _attemptKey = 'retry_attempt';
  static const _safeMethods = {'GET', 'HEAD', 'PUT', 'DELETE'};

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final attempt = (err.requestOptions.extra[_attemptKey] as int?) ?? 0;
    if (!_shouldRetry(err) || attempt >= maxRetries) {
      return handler.next(err);
    }

    await _sleep(baseDelay * pow(2, attempt).toInt());
    err.requestOptions.extra[_attemptKey] = attempt + 1;
    try {
      handler.resolve(await _dio.fetch<dynamic>(err.requestOptions));
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  bool _shouldRetry(DioException err) {
    final method = err.requestOptions.method.toUpperCase();
    if (!_safeMethods.contains(method)) return false;
    final status = err.response?.statusCode;
    return switch (err.type) {
      DioExceptionType.connectionError ||
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => true,
      DioExceptionType.badResponse => status != null && status >= 500,
      _ => false,
    };
  }
}

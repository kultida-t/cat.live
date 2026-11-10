import 'package:dio/dio.dart';

import '../error/failure.dart';

/// แปลง DioException เป็น Failure ที่ชั้นบนเข้าใจ — ชั้น data เรียกก่อนโยนต่อ
Failure mapDioException(DioException e) {
  return switch (e.type) {
    DioExceptionType.connectionError ||
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout => const NetworkFailure(),
    DioExceptionType.badResponse => switch (e.response?.statusCode) {
      401 || 403 => const UnauthorizedFailure(),
      404 => const NotFoundFailure(),
      final int s when s >= 500 => const ServerFailure(),
      _ => const UnknownFailure(),
    },
    _ => const UnknownFailure(),
  };
}

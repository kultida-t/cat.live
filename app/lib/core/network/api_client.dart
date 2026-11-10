import 'package:dio/dio.dart';

import 'auth_interceptor.dart';
import 'retry_interceptor.dart';
import 'token_provider.dart';

/// ตั้งค่า base URL ตอน build: `flutter run --dart-define=API_BASE_URL=https://api.example.com`
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://api.catlive.example',
);

/// สร้าง Dio ตัวเดียวของแอป — ทุก data source เรียก API ผ่านตัวนี้
Dio createApiClient({
  String baseUrl = apiBaseUrl,
  TokenProvider tokens = const NoTokenProvider(),
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
    ),
  );
  dio.interceptors.addAll([AuthInterceptor(tokens), RetryInterceptor(dio)]);
  return dio;
}

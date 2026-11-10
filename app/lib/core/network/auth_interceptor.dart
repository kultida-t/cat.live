import 'package:dio/dio.dart';

import 'token_provider.dart';

/// แนบ Bearer token ให้ทุกคำขอเมื่อมี token
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokens);

  final TokenProvider _tokens;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokens.readAccessToken();
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }
}

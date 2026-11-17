import 'package:dio/dio.dart';

/// เรียก API Auth ของ backend (apps/api) ตรง ๆ — ใช้เมื่อ USE_REAL_AUTH=true
/// ข้อผิดพลาดยังเป็น DioException ให้ชั้น repository อ่านรหัส `code` จาก response เอง
class DioAuthApi {
  const DioAuthApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> requestOtp(String phone) =>
      _post('/auth/otp/request', {'phone': phone});

  Future<Map<String, dynamic>> verifyOtp({
    required String refCode,
    required String code,
    required int birthYear,
    required bool guardianConsentGranted,
    String? displayName,
  }) => _post('/auth/otp/verify', {
    'refCode': refCode,
    'code': code,
    'birthYear': birthYear,
    'guardianConsentGranted': guardianConsentGranted,
    'displayName': ?displayName,
  });

  Future<Map<String, dynamic>> pinLogin({
    required String phone,
    required String pin,
  }) => _post('/auth/pin/login', {'phone': phone, 'pin': pin});

  Future<bool> hasPin() async {
    final res = await _dio.get<Map<String, dynamic>>('/auth/pin/status');
    return res.data?['hasPin'] == true;
  }

  Future<void> verifyPin(String pin) =>
      _dio.post<void>('/auth/pin/verify', data: {'pin': pin});

  Future<void> setPin(String pin) =>
      _dio.post<void>('/auth/pin', data: {'pin': pin});

  Future<void> changePin({
    required String currentPin,
    required String newPin,
  }) => _dio.post<void>(
    '/auth/pin/change',
    data: {'currentPin': currentPin, 'newPin': newPin},
  );

  Future<Map<String, dynamic>> refresh(String refreshToken) =>
      _post('/auth/refresh', {'refreshToken': refreshToken});

  Future<void> logout(String refreshToken) =>
      _dio.post<void>('/auth/logout', data: {'refreshToken': refreshToken});

  Future<Map<String, dynamic>> me() async {
    final res = await _dio.get<Map<String, dynamic>>('/auth/me');
    return res.data ?? const {};
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final res = await _dio.post<Map<String, dynamic>>(path, data: body);
    return res.data ?? const {};
  }
}

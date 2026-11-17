import 'package:dio/dio.dart';

import '../../../../core/network/dio_failure_mapper.dart';
import '../../domain/entities/auth_data.dart';
import '../../domain/usecases/auth_rules.dart';

/// สัญญาแหล่งข้อมูล Remote สำหรับ Auth (AUTH-01..04)
abstract interface class AuthRemoteDataSource {
  Future<OtpChallenge> requestOtp(String phoneNumber);

  Future<
    ({AuthSession? session, OtpChallenge? updatedChallenge, String? errorCode})
  >
  verifyOtp({
    required OtpChallenge challenge,
    required String code,
    required int birthYear,
    required bool guardianConsentGranted,
    String? displayName,
  });

  Future<AuthSession> signInWithProvider({
    required AuthMethod method,
    required int birthYear,
    required bool guardianConsentGranted,
    String? displayName,
  });

  Future<void> signOut(String? accessToken);
}

/// แหล่งข้อมูล Mock สำหรับ UI Mock Baseline (จำลองกติกา AUTH-03 ครบทุกเงื่อนไข)
class MockAuthRemoteDataSource implements AuthRemoteDataSource {
  MockAuthRemoteDataSource({
    this.latency = const Duration(milliseconds: 120),
    DateTime Function()? nowProvider,
  }) : _now = nowProvider ?? DateTime.now;

  final Duration latency;
  final DateTime Function() _now;

  @override
  Future<OtpChallenge> requestOtp(String phoneNumber) async {
    if (latency > Duration.zero) {
      await Future<void>.delayed(latency);
    }
    final now = _now();
    final normalized = AuthRules.normalizeThaiPhone(phoneNumber);
    final refSuffix = normalized.length >= 4
        ? normalized.substring(normalized.length - 4)
        : '2026';
    return OtpChallenge(
      refCode: 'ML$refSuffix',
      phoneNumber: normalized,
      expiresAt: now.add(AuthRules.otpTtl),
      resendAvailableAt: now.add(AuthRules.otpResendCooldown),
    );
  }

  @override
  Future<
    ({AuthSession? session, OtpChallenge? updatedChallenge, String? errorCode})
  >
  verifyOtp({
    required OtpChallenge challenge,
    required String code,
    required int birthYear,
    required bool guardianConsentGranted,
    String? displayName,
  }) async {
    if (latency > Duration.zero) {
      await Future<void>.delayed(latency);
    }
    final now = _now();

    if (challenge.isLockedAt(now)) {
      return (
        session: null,
        updatedChallenge: challenge,
        errorCode: 'otp_locked',
      );
    }

    if (challenge.isExpiredAt(now)) {
      return (
        session: null,
        updatedChallenge: challenge,
        errorCode: 'otp_expired',
      );
    }

    if (code.trim() != AuthRules.mockValidOtp) {
      final nextAttempts = challenge.attemptsUsed + 1;
      final lockedUntil = nextAttempts >= challenge.maxAttempts
          ? now.add(AuthRules.otpLockDuration)
          : null;
      return (
        session: null,
        updatedChallenge: challenge.copyWith(
          attemptsUsed: nextAttempts,
          lockedUntil: lockedUntil,
        ),
        errorCode: lockedUntil != null ? 'otp_locked' : 'otp_invalid',
      );
    }

    final masked = AuthRules.maskThaiPhone(challenge.phoneNumber);
    final name = displayName?.trim();
    final session = AuthSession(
      mode: AuthMode.authenticated,
      user: AuthUser(
        id: 'user-lookkaew',
        displayName: (name != null && name.isNotEmpty)
            ? name
            : 'จุฑามาศ ลูกแก้ว',
        method: AuthMethod.phoneOtp,
        phoneMasked: masked,
        birthYear: birthYear,
        guardianConsentGranted: guardianConsentGranted,
      ),
      accessToken: 'mock-access-token-${now.millisecondsSinceEpoch}',
      refreshToken: 'mock-refresh-token-${now.millisecondsSinceEpoch}',
      expiresAt: now.add(const Duration(days: 7)),
    );
    return (session: session, updatedChallenge: null, errorCode: null);
  }

  @override
  Future<AuthSession> signInWithProvider({
    required AuthMethod method,
    required int birthYear,
    required bool guardianConsentGranted,
    String? displayName,
  }) async {
    if (latency > Duration.zero) {
      await Future<void>.delayed(latency);
    }
    final now = _now();
    final providerEmail = switch (method) {
      AuthMethod.apple => 'lookkaew@icloud.com',
      AuthMethod.google => 'lookkaew@gmail.com',
      AuthMethod.line => null,
      _ => null,
    };
    final name = displayName?.trim();

    return AuthSession(
      mode: AuthMode.authenticated,
      user: AuthUser(
        id: 'user-lookkaew',
        displayName: (name != null && name.isNotEmpty)
            ? name
            : 'จุฑามาศ ลูกแก้ว',
        method: method,
        email: providerEmail,
        birthYear: birthYear,
        guardianConsentGranted: guardianConsentGranted,
      ),
      accessToken:
          'mock-access-token-${method.name}-${now.millisecondsSinceEpoch}',
      refreshToken: 'mock-refresh-token-${now.millisecondsSinceEpoch}',
      expiresAt: now.add(const Duration(days: 7)),
    );
  }

  @override
  Future<void> signOut(String? accessToken) async {
    if (latency > Duration.zero) {
      await Future<void>.delayed(latency);
    }
  }
}

/// แหล่งข้อมูล Backend API จริง (พร้อมสลับใช้งานเมื่อเปิด Backend Auth)
class DioAuthRemoteDataSource implements AuthRemoteDataSource {
  const DioAuthRemoteDataSource(this._dio);

  final Dio _dio;

  @override
  Future<OtpChallenge> requestOtp(String phoneNumber) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/auth/otp/request',
        data: {'phone_number': AuthRules.normalizeThaiPhone(phoneNumber)},
      );
      final body = response.data ?? const <String, dynamic>{};
      final now = DateTime.now();
      return OtpChallenge(
        refCode: body['ref_code'] as String? ?? 'REF',
        phoneNumber: AuthRules.normalizeThaiPhone(phoneNumber),
        expiresAt:
            DateTime.tryParse(body['expires_at'] as String? ?? '') ??
            now.add(AuthRules.otpTtl),
        resendAvailableAt:
            DateTime.tryParse(body['resend_available_at'] as String? ?? '') ??
            now.add(AuthRules.otpResendCooldown),
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<
    ({AuthSession? session, OtpChallenge? updatedChallenge, String? errorCode})
  >
  verifyOtp({
    required OtpChallenge challenge,
    required String code,
    required int birthYear,
    required bool guardianConsentGranted,
    String? displayName,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/auth/otp/verify',
        data: {
          'phone_number': challenge.phoneNumber,
          'ref_code': challenge.refCode,
          'code': code,
          'birth_year': birthYear,
          'guardian_consent': guardianConsentGranted,
          if (displayName != null && displayName.trim().isNotEmpty)
            'display_name': displayName.trim(),
        },
      );
      final body = response.data ?? const <String, dynamic>{};
      final userJson = body['user'] as Map<String, dynamic>? ?? const {};
      final session = AuthSession(
        mode: AuthMode.authenticated,
        user: AuthUser(
          id: userJson['id'] as String? ?? '',
          displayName: userJson['display_name'] as String? ?? '',
          method: AuthMethod.phoneOtp,
          phoneMasked: userJson['phone_masked'] as String?,
          birthYear: userJson['birth_year'] as int?,
          guardianConsentGranted:
              userJson['guardian_consent_granted'] as bool? ?? false,
        ),
        accessToken: body['access_token'] as String?,
        refreshToken: body['refresh_token'] as String?,
        expiresAt: DateTime.tryParse(body['expires_at'] as String? ?? ''),
      );
      return (session: session, updatedChallenge: null, errorCode: null);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<AuthSession> signInWithProvider({
    required AuthMethod method,
    required int birthYear,
    required bool guardianConsentGranted,
    String? displayName,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/auth/oauth',
        data: {
          'provider': method.name,
          'birth_year': birthYear,
          'guardian_consent': guardianConsentGranted,
          if (displayName != null && displayName.trim().isNotEmpty)
            'display_name': displayName.trim(),
        },
      );
      final body = response.data ?? const <String, dynamic>{};
      final userJson = body['user'] as Map<String, dynamic>? ?? const {};
      return AuthSession(
        mode: AuthMode.authenticated,
        user: AuthUser(
          id: userJson['id'] as String? ?? '',
          displayName: userJson['display_name'] as String? ?? '',
          method: method,
          email: userJson['email'] as String?,
          birthYear: userJson['birth_year'] as int?,
          guardianConsentGranted:
              userJson['guardian_consent_granted'] as bool? ?? false,
        ),
        accessToken: body['access_token'] as String?,
        refreshToken: body['refresh_token'] as String?,
        expiresAt: DateTime.tryParse(body['expires_at'] as String? ?? ''),
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<void> signOut(String? accessToken) async {
    try {
      await _dio.post<void>('/api/v1/auth/logout');
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}

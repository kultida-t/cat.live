import 'package:dio/dio.dart';

import '../../../../core/network/dio_failure_mapper.dart';
import '../../domain/entities/auth_data.dart';
import '../../domain/entities/deletion_data.dart';
import '../../domain/usecases/auth_rules.dart';

/// สัญญาแหล่งข้อมูล Remote สำหรับ Auth (AUTH-01..05)
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

  /// แมวที่ผู้ใช้เป็นเจ้าของพร้อมผู้ดูแลร่วม สำหรับ flow ลบบัญชี (AUTH-05)
  Future<List<CatDeletionRequirement>> loadDeletionRequirements(
    String? accessToken,
  );

  /// ขอลบบัญชี — เก็บข้อมูลไว้ 30 วันก่อนลบถาวร (กู้คืนได้ด้วยการล็อกอินใหม่)
  Future<void> requestAccountDeletion({
    required String? accessToken,
    required Map<String, String?> transferDecisions,
  });

  /// กู้คืนบัญชีค้างลบภายใน 30 วัน — คืน session ที่เคลียร์สถานะรอลบแล้ว
  /// คืน null ถ้าไม่มีบัญชีค้างลบหรือเลยกำหนด 30 วันแล้ว
  Future<AuthSession?> restorePendingDeletion(String? accessToken);
}

/// แหล่งข้อมูล Mock สำหรับ UI Mock Baseline (จำลองกติกา AUTH-03 และ AUTH-05)
class MockAuthRemoteDataSource implements AuthRemoteDataSource {
  MockAuthRemoteDataSource({
    this.latency = const Duration(milliseconds: 120),
    DateTime Function()? nowProvider,
  }) : _now = nowProvider ?? DateTime.now;

  /// ช่วงเวลาเก็บข้อมูลก่อนลบถาวรตาม AUTH-05
  static const deletionGracePeriod = Duration(days: 30);

  final Duration latency;
  final DateTime Function() _now;

  /// session ที่ถูกขอลบค้างไว้ (จำลอง soft delete ฝั่งเซิร์ฟเวอร์)
  AuthSession? _pendingDeletionSession;

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

    // บัญชีที่ถูกขอลบแล้วเข้าสู่ระบบใหม่ภายใน 30 วัน → คืน session ค้างลบเพื่อให้กู้คืน (AUTH-05)
    final pending = _pendingDeletionIfValid();
    if (pending != null) {
      return (session: pending, updatedChallenge: null, errorCode: null);
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

    // เข้าสู่ระบบใหม่ระหว่างรอลบ → เจอ session ค้างลบแทนบัญชีใหม่ (AUTH-05)
    final pending = _pendingDeletionIfValid();
    if (pending != null) return pending;

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

  /// คืน session ค้างลบถ้ายังอยู่ในระยะ 30 วัน — เลยกำหนดแล้วถือว่าถูกลบถาวร (คืน null)
  AuthSession? _pendingDeletionIfValid() {
    final pending = _pendingDeletionSession;
    if (pending == null) return null;
    final scheduledAt = pending.deletionScheduledAt;
    if (scheduledAt == null) return null;
    if (_now().isBefore(scheduledAt.add(deletionGracePeriod))) return pending;
    _pendingDeletionSession = null;
    return null;
  }

  @override
  Future<List<CatDeletionRequirement>> loadDeletionRequirements(
    String? accessToken,
  ) async {
    if (latency > Duration.zero) {
      await Future<void>.delayed(latency);
    }
    // จำลองสถานการณ์จริงของบัญชีเดโม: มะลิมีผู้ดูแลร่วม 2 คน ต้องโอนสิทธิ์/ยืนยันลบก่อน,
    // ส้มจี๊ดมีผู้ดูแลร่วม 1 คน, ถั่วดำไม่มีผู้ดูแลร่วมลบพร้อมบัญชีได้เลย
    return const [
      CatDeletionRequirement(
        catId: 'cat-mali',
        catName: 'มะลิ',
        imageSource: 'asset:assets/images/hero/mali.jpg',
        coCaretakers: [
          DeletionCaretakerOption(
            id: 'cg-mom',
            name: 'แม่',
            avatarSource:
                'asset:assets/images/avatars/1566616213894-2d4e1baee5d8.jpg',
          ),
          DeletionCaretakerOption(
            id: 'cg-sis',
            name: 'พี่สาว',
            avatarSource:
                'asset:assets/images/avatars/1580489944761-15a19d654956.jpg',
          ),
        ],
      ),
      CatDeletionRequirement(
        catId: 'cat-somjeed',
        catName: 'ส้มจี๊ด',
        imageSource: 'asset:assets/images/hero/somjeed.jpg',
        coCaretakers: [
          DeletionCaretakerOption(
            id: 'cg-mom',
            name: 'แม่',
            avatarSource:
                'asset:assets/images/avatars/1566616213894-2d4e1baee5d8.jpg',
          ),
        ],
      ),
      CatDeletionRequirement(
        catId: 'cat-thuadam',
        catName: 'ถั่วดำ',
        imageSource: 'asset:assets/images/hero/thuadam.jpg',
      ),
    ];
  }

  @override
  Future<void> requestAccountDeletion({
    required String? accessToken,
    required Map<String, String?> transferDecisions,
  }) async {
    if (latency > Duration.zero) {
      await Future<void>.delayed(latency);
    }
    _pendingDeletionSession = AuthSession(
      mode: AuthMode.authenticated,
      user: const AuthUser(
        id: 'user-lookkaew',
        displayName: 'จุฑามาศ ลูกแก้ว',
        method: AuthMethod.phoneOtp,
        phoneMasked: '081-xxx-4567',
        birthYear: 1995,
      ),
      accessToken: 'mock-access-token-deleted',
      deletionScheduledAt: _now(),
    );
  }

  @override
  Future<AuthSession?> restorePendingDeletion(String? accessToken) async {
    if (latency > Duration.zero) {
      await Future<void>.delayed(latency);
    }
    final pending = _pendingDeletionIfValid();
    if (pending == null) return null;
    _pendingDeletionSession = null;
    return pending.copyWith(clearDeletionScheduledAt: true);
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

  @override
  Future<List<CatDeletionRequirement>> loadDeletionRequirements(
    String? accessToken,
  ) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/api/v1/auth/deletion-requirements',
      );
      final items = response.data ?? const [];
      return [
        for (final item in items)
          if (item is Map<String, dynamic>)
            CatDeletionRequirement(
              catId: item['cat_id'] as String? ?? '',
              catName: item['cat_name'] as String? ?? '',
              imageSource: item['image_source'] as String?,
              coCaretakers: [
                for (final c
                    in (item['co_caretakers'] as List<dynamic>? ?? const []))
                  if (c is Map<String, dynamic>)
                    DeletionCaretakerOption(
                      id: c['id'] as String? ?? '',
                      name: c['name'] as String? ?? '',
                      avatarSource: c['avatar_source'] as String?,
                    ),
              ],
            ),
      ];
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<void> requestAccountDeletion({
    required String? accessToken,
    required Map<String, String?> transferDecisions,
  }) async {
    try {
      await _dio.post<void>(
        '/api/v1/auth/delete',
        data: {'transfer_decisions': transferDecisions},
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<AuthSession?> restorePendingDeletion(String? accessToken) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/auth/restore',
      );
      final body = response.data;
      if (body == null) return null;
      final userJson = body['user'] as Map<String, dynamic>? ?? const {};
      return AuthSession(
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
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}

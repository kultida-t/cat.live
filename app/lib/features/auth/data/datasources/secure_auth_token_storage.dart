import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/entities/auth_data.dart';
import 'auth_token_storage.dart';

/// เก็บ Session/Token ลง Keychain (iOS) / EncryptedSharedPreferences+Keystore (Android)
/// ทำให้สถานะล็อกอินอยู่ข้ามการปิดเปิดแอป และ token พร้อมส่งเข้า API ผ่าน TokenProvider
/// ห้ามย้ายไป shared_preferences หรือไฟล์ธรรมดาเพราะ token เป็นข้อมูลลับ
class SecureAuthTokenStorage implements AuthTokenStorage {
  SecureAuthTokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _sessionKey = 'catlive.auth.session.v1';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> readAccessToken() async {
    final session = await readSession();
    return session?.accessToken;
  }

  @override
  Future<void> saveSession(AuthSession session) async {
    await _storage.write(key: _sessionKey, value: jsonEncode(_encode(session)));
  }

  @override
  Future<AuthSession?> readSession() async {
    final raw = await _storage.read(key: _sessionKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return _decode(jsonDecode(raw));
    } catch (_) {
      // ข้อมูลเสียหาย/อ่านไม่ได้ ให้ถือว่าไม่มี session แล้วให้ระบบสร้างใหม่
      return null;
    }
  }

  @override
  Future<void> clearSession() => _storage.delete(key: _sessionKey);

  Map<String, dynamic> _encode(AuthSession session) {
    return {
      'mode': session.mode.name,
      'user': session.user == null
          ? null
          : {
              'id': session.user!.id,
              'display_name': session.user!.displayName,
              'method': session.user!.method.name,
              'phone_masked': session.user!.phoneMasked,
              'email': session.user!.email,
              'birth_year': session.user!.birthYear,
              'guardian_consent_granted': session.user!.guardianConsentGranted,
            },
      'access_token': session.accessToken,
      'refresh_token': session.refreshToken,
      'expires_at': session.expiresAt?.toIso8601String(),
      'deletion_scheduled_at': session.deletionScheduledAt?.toIso8601String(),
    };
  }

  AuthSession? _decode(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    if (json['mode'] != AuthMode.authenticated.name) {
      return const AuthSession.guest();
    }
    final userJson = json['user'];
    if (userJson is! Map<String, dynamic>) return null;
    final id = userJson['id'];
    final displayName = userJson['display_name'];
    if (id is! String || displayName is! String) return null;

    return AuthSession(
      mode: AuthMode.authenticated,
      user: AuthUser(
        id: id,
        displayName: displayName,
        method: _decodeMethod(userJson['method']),
        phoneMasked: userJson['phone_masked'] as String?,
        email: userJson['email'] as String?,
        birthYear: userJson['birth_year'] as int?,
        guardianConsentGranted:
            userJson['guardian_consent_granted'] as bool? ?? false,
      ),
      accessToken: json['access_token'] as String?,
      refreshToken: json['refresh_token'] as String?,
      expiresAt: DateTime.tryParse(json['expires_at'] as String? ?? ''),
      deletionScheduledAt: DateTime.tryParse(
        json['deletion_scheduled_at'] as String? ?? '',
      ),
    );
  }

  AuthMethod _decodeMethod(Object? name) {
    for (final method in AuthMethod.values) {
      if (method.name == name) return method;
    }
    return AuthMethod.phoneOtp;
  }
}

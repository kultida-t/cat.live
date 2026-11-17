import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/entities/auth_data.dart';
import '../../domain/entities/pin_account_record.dart';
import 'auth_pin_storage.dart';

/// เก็บ PIN (เฉพาะ hash + salt) ผูกกับบัญชีลง Keychain (iOS) /
/// EncryptedSharedPreferences+Keystore (Android) — แยก key จาก session
/// ห้ามย้ายไป shared_preferences หรือไฟล์ธรรมดาเพราะเป็นข้อมูลลับ
class SecureAuthPinStorage implements AuthPinStorage {
  SecureAuthPinStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _pinKey = 'catlive.auth.pin.v1';
  final FlutterSecureStorage _storage;

  @override
  Future<List<PinAccountRecord>> readAll() async {
    final raw = await _storage.read(key: _pinKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [for (final item in decoded) ?_decode(item)];
    } catch (_) {
      // ข้อมูลเสียหาย ให้ถือว่าไม่มี PIN บนเครื่องนี้แล้วให้ผู้ใช้ตั้งใหม่
      return const [];
    }
  }

  @override
  Future<PinAccountRecord?> findByPhone(String phone) async {
    final records = await readAll();
    for (final record in records) {
      if (record.phone == phone) return record;
    }
    return null;
  }

  @override
  Future<PinAccountRecord?> findByUserId(String userId) async {
    final records = await readAll();
    for (final record in records) {
      if (record.userId == userId) return record;
    }
    return null;
  }

  @override
  Future<void> saveRecord(PinAccountRecord record) async {
    final records = [...await readAll()];
    records.removeWhere((r) => r.phone == record.phone);
    records.add(record);
    await _write(records);
  }

  @override
  Future<void> deleteForUser(String userId) async {
    final records = [...await readAll()];
    records.removeWhere((r) => r.userId == userId);
    await _write(records);
  }

  Future<void> _write(List<PinAccountRecord> records) {
    final encoded = jsonEncode([for (final r in records) _encode(r)]);
    return _storage.write(key: _pinKey, value: encoded);
  }

  Map<String, dynamic> _encode(PinAccountRecord record) {
    return {
      'user_id': record.userId,
      'phone': record.phone,
      'salt': record.salt,
      'pin_hash': record.pinHash,
      'display_name': record.displayName,
      'method': record.method.name,
      'phone_masked': record.phoneMasked,
      'email': record.email,
      'birth_year': record.birthYear,
      'guardian_consent_granted': record.guardianConsentGranted,
    };
  }

  PinAccountRecord? _decode(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final userId = json['user_id'];
    final phone = json['phone'];
    final salt = json['salt'];
    final pinHash = json['pin_hash'];
    final displayName = json['display_name'];
    if (userId is! String ||
        phone is! String ||
        salt is! String ||
        pinHash is! String ||
        displayName is! String) {
      return null;
    }
    return PinAccountRecord(
      userId: userId,
      phone: phone,
      salt: salt,
      pinHash: pinHash,
      displayName: displayName,
      method: _decodeMethod(json['method']),
      phoneMasked: json['phone_masked'] as String?,
      email: json['email'] as String?,
      birthYear: json['birth_year'] as int?,
      guardianConsentGranted:
          json['guardian_consent_granted'] as bool? ?? false,
    );
  }

  AuthMethod _decodeMethod(Object? name) {
    for (final method in AuthMethod.values) {
      if (method.name == name) return method;
    }
    return AuthMethod.phoneOtp;
  }
}

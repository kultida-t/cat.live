import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../entities/pin_account_record.dart';

/// กติกาและการเข้ารหัส PIN 6 หลัก (แยกออกจาก Widget)
/// เก็บเฉพาะ hash เท่านั้น — salt ผูกกับ userId เพื่อกันตารางเดาและกันเอา hash
/// ไปใช้กับบัญชีอื่นได้
abstract final class PinRules {
  static const pinLength = 6;

  static bool isValidPin(String raw) => RegExp(r'^\d{6}$').hasMatch(raw.trim());

  /// salt สุ่มใหม่ทุกครั้งที่ตั้ง/เปลี่ยน PIN
  static String generateSalt() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    return base64UrlEncode(bytes);
  }

  static String hashPin({
    required String pin,
    required String salt,
    required String userId,
  }) {
    return sha256.convert(utf8.encode('$salt:$userId:$pin')).toString();
  }

  static bool verifyPin({
    required String pin,
    required PinAccountRecord record,
  }) {
    if (!isValidPin(pin)) return false;
    return hashPin(pin: pin.trim(), salt: record.salt, userId: record.userId) ==
        record.pinHash;
  }
}

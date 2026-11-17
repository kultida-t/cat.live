import 'package:flutter_riverpod/flutter_riverpod.dart';

/// แหล่งอ่าน access token — ช่วงนี้ยังไม่มีล็อกอิน จึงคืน null
/// ตอนทำล็อกอินจริงให้เปลี่ยนไปเก็บใน Keychain/Keystore (flutter_secure_storage) ห้ามเก็บใน storage ธรรมดา
abstract interface class TokenProvider {
  Future<String?> readAccessToken();
}

class NoTokenProvider implements TokenProvider {
  const NoTokenProvider();

  @override
  Future<String?> readAccessToken() async => null;
}

/// TokenProvider กลางของแอป — main.dart override ให้ชี้ไป SecureAuthTokenStorage
/// (ค่าเริ่มต้น NoTokenProvider สำหรับ test และสภาพแวดล้อมที่ยังไม่มีล็อกอิน)
final appTokenProvider = Provider<TokenProvider>(
  (ref) => const NoTokenProvider(),
);

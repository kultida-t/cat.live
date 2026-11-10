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

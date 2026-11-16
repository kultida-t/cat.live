import '../../../../core/network/token_provider.dart';
import '../../domain/entities/auth_data.dart';

/// สัญญา Secure Storage สำหรับเก็บ Access/Refresh Token และ Session
/// ตอนต่อ Production ให้สลับไปใช้ flutter_secure_storage (Keychain/Keystore)
abstract interface class AuthTokenStorage implements TokenProvider {
  Future<void> saveSession(AuthSession session);
  Future<AuthSession?> readSession();
  Future<void> clearSession();
}

/// Implementation แบบเก็บในหน่วยความจำสำหรับ UI Mock Baseline
class InMemoryAuthTokenStorage implements AuthTokenStorage {
  AuthSession? _cached;

  @override
  Future<String?> readAccessToken() async => _cached?.accessToken;

  @override
  Future<void> saveSession(AuthSession session) async {
    _cached = session;
  }

  @override
  Future<AuthSession?> readSession() async => _cached;

  @override
  Future<void> clearSession() async {
    _cached = null;
  }
}

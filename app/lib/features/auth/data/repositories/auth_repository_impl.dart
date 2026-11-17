import '../../domain/entities/auth_data.dart';
import '../../domain/entities/deletion_data.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../datasources/auth_token_storage.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthTokenStorage tokenStorage,
  }) : _remote = remoteDataSource,
       _storage = tokenStorage;

  final AuthRemoteDataSource _remote;
  final AuthTokenStorage _storage;

  @override
  Future<AuthSession> restoreSession() async {
    final stored = await _storage.readSession();
    if (stored != null) return stored;

    // ค่าเริ่มต้นช่วง UI Mock Baseline: จำลองผู้ใช้ล็อกอินอยู่แล้วเพื่อให้หน้าจอที่ล็อกไว้ใช้งานได้ต่อเนื่อง
    const defaultSession = AuthSession(
      mode: AuthMode.authenticated,
      user: AuthUser(
        id: 'user-lookkaew',
        displayName: 'จุฑามาศ ลูกแก้ว',
        method: AuthMethod.phoneOtp,
        phoneMasked: '081-xxx-4567',
        birthYear: 1995,
      ),
      accessToken: 'mock-initial-token',
    );
    await _storage.saveSession(defaultSession);
    return defaultSession;
  }

  @override
  Future<AuthSession> enterGuestMode() async {
    const guest = AuthSession.guest();
    await _storage.saveSession(guest);
    return guest;
  }

  @override
  Future<OtpChallenge> requestOtp(String phoneNumber) =>
      _remote.requestOtp(phoneNumber);

  @override
  Future<
    ({AuthSession session, OtpChallenge? updatedChallenge, String? errorCode})
  >
  verifyOtp({
    required OtpChallenge challenge,
    required String code,
    required int birthYear,
    required bool guardianConsentGranted,
    String? displayName,
  }) async {
    final res = await _remote.verifyOtp(
      challenge: challenge,
      code: code,
      birthYear: birthYear,
      guardianConsentGranted: guardianConsentGranted,
      displayName: displayName,
    );
    if (res.session != null) {
      await _storage.saveSession(res.session!);
      return (session: res.session!, updatedChallenge: null, errorCode: null);
    }
    final current = await restoreSession();
    return (
      session: current,
      updatedChallenge: res.updatedChallenge,
      errorCode: res.errorCode,
    );
  }

  @override
  Future<AuthSession> signInWithProvider({
    required AuthMethod method,
    required int birthYear,
    required bool guardianConsentGranted,
    String? displayName,
  }) async {
    final session = await _remote.signInWithProvider(
      method: method,
      birthYear: birthYear,
      guardianConsentGranted: guardianConsentGranted,
      displayName: displayName,
    );
    await _storage.saveSession(session);
    return session;
  }

  @override
  Future<AuthSession> signOut() async {
    final token = await _storage.readAccessToken();
    await _remote.signOut(token);
    await _storage.clearSession();
    const guest = AuthSession.guest();
    await _storage.saveSession(guest);
    return guest;
  }

  @override
  Future<List<CatDeletionRequirement>> loadDeletionRequirements() async {
    final token = await _storage.readAccessToken();
    return _remote.loadDeletionRequirements(token);
  }

  @override
  Future<void> requestAccountDeletion({
    required Map<String, String?> transferDecisions,
  }) async {
    final token = await _storage.readAccessToken();
    await _remote.requestAccountDeletion(
      accessToken: token,
      transferDecisions: transferDecisions,
    );
    // ขอลบสำเร็จ → บังคับออกจากระบบทันที บัญชีเข้าสถานะรอลบ 30 วัน
    await _storage.clearSession();
    await _storage.saveSession(const AuthSession.guest());
  }

  @override
  Future<AuthSession?> restorePendingDeletion() async {
    final token = await _storage.readAccessToken();
    final restored = await _remote.restorePendingDeletion(token);
    if (restored != null) {
      await _storage.saveSession(restored);
    }
    return restored;
  }
}

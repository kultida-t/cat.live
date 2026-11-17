import '../../domain/entities/auth_data.dart';
import '../../domain/entities/deletion_data.dart';
import '../../domain/entities/pin_account_record.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/auth_rules.dart';
import '../../domain/usecases/pin_rules.dart';
import '../datasources/auth_pin_storage.dart';
import '../datasources/auth_remote_data_source.dart';
import '../datasources/auth_token_storage.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthTokenStorage tokenStorage,
    required this._pinStorage,
  }) : _remote = remoteDataSource,
       _storage = tokenStorage;

  /// ค่าบัญชีเดโม (จุฑามาศ) ที่ seed PIN ให้ตั้งแต่เปิดแอปครั้งแรก
  static const _demoUserId = 'user-lookkaew';
  static const _demoPhone = '0812344567';
  static const _demoPin = '123456';

  final AuthRemoteDataSource _remote;
  final AuthTokenStorage _storage;
  final AuthPinStorage _pinStorage;

  @override
  Future<AuthSession> restoreSession() async {
    // seed PIN เดโมทุกครั้งที่เปิดแอป (idempotent) — ให้เบอร์เดโมล็อกอินด้วย
    // PIN ได้เสมอ แม้ session ก่อนหน้าจะเป็น guest หรือเพิ่งออกจากระบบ
    await _seedDemoPin();
    final stored = await _storage.readSession();
    if (stored != null) return stored;

    // ค่าเริ่มต้นช่วง UI Mock Baseline: จำลองผู้ใช้ล็อกอินอยู่แล้วเพื่อให้หน้าจอที่ล็อกไว้ใช้งานได้ต่อเนื่อง
    const defaultSession = AuthSession(
      mode: AuthMode.authenticated,
      user: AuthUser(
        id: 'user-lookkaew',
        displayName: 'จุฑามาศ ลูกแก้ว',
        method: AuthMethod.phoneOtp,
        phone: _demoPhone,
        phoneMasked: '081-xxx-4567',
        birthYear: 1995,
      ),
      accessToken: 'mock-initial-token',
    );
    await _storage.saveSession(defaultSession);
    return defaultSession;
  }

  /// seed PIN 123456 ผูกเบอร์เดโม — ทำให้ล็อกอินด้วย PIN ใช้งานได้ตั้งแต่ติดตั้ง
  Future<void> _seedDemoPin() async {
    if (await _pinStorage.findByUserId(_demoUserId) != null) return;
    final salt = PinRules.generateSalt();
    await _pinStorage.saveRecord(
      PinAccountRecord(
        userId: _demoUserId,
        phone: _demoPhone,
        salt: salt,
        pinHash: PinRules.hashPin(
          pin: _demoPin,
          salt: salt,
          userId: _demoUserId,
        ),
        displayName: 'จุฑามาศ ลูกแก้ว',
        method: AuthMethod.phoneOtp,
        phoneMasked: '081-xxx-4567',
        birthYear: 1995,
      ),
    );
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
  Future<({AuthSession? session, PinSignInFailure? failure})> signInWithPin({
    required String phone,
    required String pin,
  }) async {
    final normalized = AuthRules.normalizeThaiPhone(phone);
    final record = await _pinStorage.findByPhone(normalized);
    if (record == null) {
      return (session: null, failure: PinSignInFailure.noPinForPhone);
    }
    if (!PinRules.verifyPin(pin: pin, record: record)) {
      return (session: null, failure: PinSignInFailure.wrongPin);
    }
    final session = await _remote.signInWithPin(
      phone: normalized,
      pin: pin.trim(),
      localAccount: record,
    );
    await _storage.saveSession(session);
    return (session: session, failure: null);
  }

  @override
  Future<bool> hasPinForPhone(String phone) async {
    final normalized = AuthRules.normalizeThaiPhone(phone);
    return (await _pinStorage.findByPhone(normalized)) != null;
  }

  @override
  Future<void> setPin({required AuthUser user, required String pin}) async {
    final phone = user.phone;
    if (phone == null || phone.isEmpty || !PinRules.isValidPin(pin)) {
      throw ArgumentError(
        'PIN setup requires a phone-bound account and a 6-digit PIN',
      );
    }
    final salt = PinRules.generateSalt();
    await _pinStorage.saveRecord(
      PinAccountRecord(
        userId: user.id,
        phone: phone,
        salt: salt,
        pinHash: PinRules.hashPin(pin: pin.trim(), salt: salt, userId: user.id),
        displayName: user.displayName,
        method: user.method,
        phoneMasked: user.phoneMasked,
        email: user.email,
        birthYear: user.birthYear,
        guardianConsentGranted: user.guardianConsentGranted,
      ),
    );
  }

  @override
  Future<bool> verifyCurrentPin({
    required AuthUser user,
    required String pin,
  }) async {
    final phone = user.phone;
    if (phone == null) return false;
    final record = await _pinStorage.findByPhone(phone);
    if (record == null) return false;
    return PinRules.verifyPin(pin: pin, record: record);
  }

  @override
  Future<bool> changePin({
    required AuthUser user,
    required String currentPin,
    required String newPin,
  }) async {
    final verified = await verifyCurrentPin(user: user, pin: currentPin);
    if (!verified || !PinRules.isValidPin(newPin)) return false;
    await setPin(user: user, pin: newPin);
    return true;
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
    final sessionBefore = await _storage.readSession();
    await _remote.requestAccountDeletion(
      accessToken: token,
      transferDecisions: transferDecisions,
    );
    // ขอลบสำเร็จ → บังคับออกจากระบบทันที บัญชีเข้าสถานะรอลบ 30 วัน
    // และล้าง PIN ที่ผูกกับบัญชีนั้นออกจากเครื่องนี้ด้วย
    await _storage.clearSession();
    await _storage.saveSession(const AuthSession.guest());
    final userId = sessionBefore?.user?.id;
    if (userId != null) {
      await _pinStorage.deleteForUser(userId);
    }
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

import 'package:dio/dio.dart';

import '../../domain/entities/auth_data.dart';
import '../../domain/entities/deletion_data.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/auth_rules.dart';
import '../datasources/auth_token_storage.dart';
import '../datasources/dio_auth_api.dart';

/// Repository ที่คุยกับ backend จริง (ใช้เมื่อ USE_REAL_AUTH=true)
/// PIN ตัดสินที่ server ทั้งหมด — ไม่เช็กกับ PIN บนเครื่องอีก
/// เมธอดที่ backend ยังไม่มี (โซเชียลล็อกอิน, ลบบัญชี) คืนข้อผิดพลาดชัดเจนแทนการจำลองผลลัพธ์
class RemoteAuthRepositoryImpl implements AuthRepository {
  RemoteAuthRepositoryImpl({
    required this._api,
    required this._storage,
    DateTime Function()? nowProvider,
  }) : _now = nowProvider ?? DateTime.now;

  final DioAuthApi _api;
  final AuthTokenStorage _storage;
  final DateTime Function() _now;

  /// สถานะการกรอก PIN ผิดล่าสุดที่ server ตอบกลับ — ใช้แสดงจำนวนครั้งที่เหลือ/เวลาล็อก
  String? _statusPhone;
  PinAttemptStatus? _status;

  @override
  Future<AuthSession> restoreSession() async =>
      await _storage.readSession() ?? const AuthSession.guest();

  @override
  Future<AuthSession> enterGuestMode() async {
    const guest = AuthSession.guest();
    await _storage.saveSession(guest);
    return guest;
  }

  @override
  Future<OtpChallenge> requestOtp(String phoneNumber) async {
    final phone = AuthRules.normalizeThaiPhone(phoneNumber);
    final res = await _api.requestOtp(phone);
    return OtpChallenge(
      refCode: res['refCode'] as String,
      phoneNumber: phone,
      expiresAt: DateTime.parse(res['expiresAt'] as String),
      resendAvailableAt: DateTime.parse(res['resendAvailableAt'] as String),
    );
  }

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
    try {
      final res = await _api.verifyOtp(
        refCode: challenge.refCode,
        code: code,
        birthYear: birthYear,
        guardianConsentGranted: guardianConsentGranted,
        displayName: displayName,
      );
      final session = await _saveTokens(res, phone: challenge.phoneNumber);
      return (session: session, updatedChallenge: null, errorCode: null);
    } on DioException catch (e) {
      final body = _body(e);
      final errorCode = body?['code'] as String?;
      if (errorCode == null) {
        rethrow;
      }
      return (
        session: await restoreSession(),
        updatedChallenge: _challengeFromError(challenge, body!),
        errorCode: errorCode,
      );
    }
  }

  @override
  Future<AuthSession> signInWithProvider({
    required AuthMethod method,
    required int birthYear,
    required bool guardianConsentGranted,
    String? displayName,
  }) => Future.error(
    UnsupportedError(
      'ยังไม่รองรับการเข้าสู่ระบบด้วยบัญชีโซเชียลกับเซิร์ฟเวอร์',
    ),
  );

  @override
  Future<AuthSession> signOut() async {
    final refreshToken = (await _storage.readSession())?.refreshToken;
    if (refreshToken != null) {
      try {
        await _api.logout(refreshToken);
      } on DioException {
        // server ตอบไม่ได้ก็ยังออกจากระบบฝั่งแอปต่อ token จะหมดอายุเองภายหลัง
      }
    }
    await _storage.clearSession();
    const guest = AuthSession.guest();
    await _storage.saveSession(guest);
    return guest;
  }

  @override
  Future<({AuthSession? session, PinSignInFailure? failure})> signInWithPin({
    required String phone,
    required String pin,
  }) async {
    final normalized = AuthRules.normalizeThaiPhone(phone);
    try {
      final res = await _api.pinLogin(phone: normalized, pin: pin.trim());
      _clearStatus();
      return (
        session: await _saveTokens(res, phone: normalized),
        failure: null,
      );
    } on DioException catch (e) {
      final body = _body(e);
      final failure = switch (body?['code']) {
        'no_pin_for_phone' => PinSignInFailure.noPinForPhone,
        'pin_invalid' => PinSignInFailure.wrongPin,
        'pin_locked' => PinSignInFailure.locked,
        _ => null,
      };
      if (failure == null) rethrow;
      if (failure != PinSignInFailure.noPinForPhone) {
        _rememberStatus(normalized, body!);
      }
      return (session: null, failure: failure);
    }
  }

  @override
  Future<bool> hasPinForPhone(String phone) async {
    try {
      return await _api.hasPin();
    } on DioException {
      return false;
    }
  }

  @override
  Future<PinAttemptStatus?> pinAttemptStatus(String phone) async =>
      AuthRules.normalizeThaiPhone(phone) == _statusPhone ? _status : null;

  @override
  Future<void> setPin({required AuthUser user, required String pin}) =>
      _api.setPin(pin.trim());

  @override
  Future<bool> verifyCurrentPin({
    required AuthUser user,
    required String pin,
  }) async {
    try {
      await _api.verifyPin(pin.trim());
      return true;
    } on DioException catch (e) {
      _rememberPinFailure(user.phone, e);
      return false;
    }
  }

  @override
  Future<bool> changePin({
    required AuthUser user,
    required String currentPin,
    required String newPin,
  }) async {
    try {
      await _api.changePin(
        currentPin: currentPin.trim(),
        newPin: newPin.trim(),
      );
      return true;
    } on DioException catch (e) {
      _rememberPinFailure(user.phone, e);
      return false;
    }
  }

  @override
  Future<List<CatDeletionRequirement>> loadDeletionRequirements() =>
      Future.error(UnsupportedError('ยังไม่รองรับการลบบัญชีกับเซิร์ฟเวอร์'));

  @override
  Future<void> requestAccountDeletion({
    required Map<String, String?> transferDecisions,
  }) => Future.error(UnsupportedError('ยังไม่รองรับการลบบัญชีกับเซิร์ฟเวอร์'));

  @override
  Future<AuthSession?> restorePendingDeletion() => Future.error(
    UnsupportedError('ยังไม่รองรับการกู้คืนบัญชีกับเซิร์ฟเวอร์'),
  );

  Future<AuthSession> _saveTokens(
    Map<String, dynamic> res, {
    required String phone,
  }) async {
    final user = res['user'] as Map<String, dynamic>;
    final session = AuthSession(
      mode: AuthMode.authenticated,
      user: AuthUser(
        id: user['id'] as String,
        displayName: user['displayName'] as String,
        method: AuthMethod.phoneOtp,
        phone: phone,
        phoneMasked: user['phoneMasked'] as String?,
        birthYear: user['birthYear'] as int?,
      ),
      accessToken: res['accessToken'] as String,
      refreshToken: res['refreshToken'] as String,
      expiresAt: _now().add(Duration(seconds: res['expiresIn'] as int)),
    );
    await _storage.saveSession(session);
    return session;
  }

  OtpChallenge _challengeFromError(
    OtpChallenge challenge,
    Map<String, dynamic> body,
  ) {
    final remaining = body['remainingAttempts'] as int?;
    final unlock = body['unlockSeconds'] as int?;
    return challenge.copyWith(
      attemptsUsed: remaining != null
          ? challenge.maxAttempts - remaining
          : challenge.attemptsUsed,
      lockedUntil: unlock != null
          ? _now().add(Duration(seconds: unlock))
          : null,
    );
  }

  void _rememberPinFailure(String? phone, DioException e) {
    final body = _body(e);
    final code = body?['code'];
    if (body == null || (code != 'pin_invalid' && code != 'pin_locked')) return;
    _rememberStatus(AuthRules.normalizeThaiPhone(phone ?? ''), body);
  }

  void _rememberStatus(String phone, Map<String, dynamic> body) {
    final remaining = body['remainingAttempts'] as int?;
    final unlock = body['unlockSeconds'] as int?;
    _statusPhone = phone;
    _status = PinAttemptStatus(
      remainingAttempts: unlock != null
          ? 0
          : (remaining ?? AuthRules.pinMaxAttempts),
      lockedUntil: unlock != null
          ? _now().add(Duration(seconds: unlock))
          : null,
    );
  }

  void _clearStatus() {
    _statusPhone = null;
    _status = null;
  }

  Map<String, dynamic>? _body(DioException e) {
    final data = e.response?.data;
    return data is Map<String, dynamic> ? data : null;
  }
}

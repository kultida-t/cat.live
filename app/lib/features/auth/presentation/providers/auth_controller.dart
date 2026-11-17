import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/auth_pin_storage.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/datasources/auth_token_storage.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/auth_data.dart';
import '../../domain/entities/deletion_data.dart';
import '../../domain/repositories/auth_repository.dart';

final authTokenStorageProvider = Provider<AuthTokenStorage>(
  (ref) => InMemoryAuthTokenStorage(),
);

final authPinStorageProvider = Provider<AuthPinStorage>(
  (ref) => InMemoryAuthPinStorage(),
);

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => MockAuthRemoteDataSource(),
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.read(authRemoteDataSourceProvider),
    tokenStorage: ref.read(authTokenStorageProvider),
    pinStorage: ref.read(authPinStorageProvider),
  );
});

class AuthState {
  const AuthState({
    required this.session,
    this.isSubmitting = false,
    this.otpChallenge,
    this.errorCode,
    this.tickSeconds = 0,
    this.sessionResolved = false,
    this.pinRevision = 0,
  });

  final AuthSession session;
  final bool isSubmitting;
  final OtpChallenge? otpChallenge;
  final String? errorCode;
  final int tickSeconds;

  /// ตัวนับที่เพิ่มทุกครั้งที่ตั้ง/เปลี่ยน PIN — หน้าจัดการบัญชีใช้ watch
  /// เพื่อสลับข้อความ ตั้งรหัส PIN ↔ เปลี่ยนรหัส PIN ให้ตรงสถานะล่าสุด
  final int pinRevision;

  /// true เมื่ออ่าน session จาก storage เสร็จแล้ว — ใช้แยกช่วงแอปเพิ่งเปิด
  /// ที่ยังไม่รู้ว่าผู้ใช้ล็อกอินค้างไว้หรือไม่ (เช่น กันเข้า /login ซ้ำ)
  final bool sessionResolved;

  bool get isAuthenticated => session.isAuthenticated;
  bool get isGuest => session.isGuest;

  /// true เมื่อบัญชีอยู่ในช่วงรอลบ 30 วัน — ผู้ใช้เลือกกู้คืนหรือลบต่อได้ (AUTH-05)
  bool get isPendingDeletion => session.isPendingDeletion;

  AuthState copyWith({
    AuthSession? session,
    bool? isSubmitting,
    OtpChallenge? otpChallenge,
    bool clearOtpChallenge = false,
    String? errorCode,
    bool clearError = false,
    int? tickSeconds,
    bool? sessionResolved,
    int? pinRevision,
  }) {
    return AuthState(
      session: session ?? this.session,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      otpChallenge: clearOtpChallenge
          ? null
          : (otpChallenge ?? this.otpChallenge),
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
      tickSeconds: tickSeconds ?? this.tickSeconds,
      sessionResolved: sessionResolved ?? this.sessionResolved,
      pinRevision: pinRevision ?? this.pinRevision,
    );
  }
}

class AuthController extends Notifier<AuthState> {
  Timer? _countdownTimer;

  @override
  AuthState build() {
    ref.onDispose(() => _countdownTimer?.cancel());
    Future<void>.microtask(_restore);
    return const AuthState(
      session: AuthSession(
        mode: AuthMode.authenticated,
        user: AuthUser(
          id: 'user-lookkaew',
          displayName: 'จุฑามาศ ลูกแก้ว',
          method: AuthMethod.phoneOtp,
          phone: '0812344567',
          phoneMasked: '081-xxx-4567',
          birthYear: 1995,
        ),
        accessToken: 'mock-initial-token',
      ),
    );
  }

  Future<void> _restore() async {
    final repo = ref.read(authRepositoryProvider);
    final restored = await repo.restoreSession();
    state = state.copyWith(session: restored, sessionResolved: true);
  }

  void _startTickerIfNeeded() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final challenge = state.otpChallenge;
      if (challenge == null) {
        _countdownTimer?.cancel();
        return;
      }
      state = state.copyWith(tickSeconds: state.tickSeconds + 1);
    });
  }

  Future<void> continueAsGuest() async {
    _countdownTimer?.cancel();
    state = state.copyWith(isSubmitting: true, clearError: true);
    final repo = ref.read(authRepositoryProvider);
    final guestSession = await repo.enterGuestMode();
    state = AuthState(session: guestSession, sessionResolved: true);
  }

  Future<bool> requestOtp(String phoneNumber) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final challenge = await repo.requestOtp(phoneNumber);
      state = state.copyWith(
        isSubmitting: false,
        otpChallenge: challenge,
        clearError: true,
      );
      _startTickerIfNeeded();
      return true;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        errorCode: 'otp_request_failed',
      );
      return false;
    }
  }

  Future<bool> verifyOtp({
    required String code,
    required int birthYear,
    required bool guardianConsentGranted,
    String? displayName,
  }) async {
    final challenge = state.otpChallenge;
    if (challenge == null) return false;

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.verifyOtp(
        challenge: challenge,
        code: code,
        birthYear: birthYear,
        guardianConsentGranted: guardianConsentGranted,
        displayName: displayName,
      );
      if (result.errorCode == null && result.session.isAuthenticated) {
        _countdownTimer?.cancel();
        state = AuthState(session: result.session, sessionResolved: true);
        return true;
      }
      state = state.copyWith(
        isSubmitting: false,
        otpChallenge: result.updatedChallenge ?? challenge,
        errorCode: result.errorCode ?? 'otp_invalid',
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        errorCode: 'otp_verify_failed',
      );
      return false;
    }
  }

  /// ล็อกอินด้วยเบอร์ + PIN — คืน null เมื่อสำเร็จ, หรือเหตุผลที่ล้มเหลว
  /// (เบอร์ยังไม่มี PIN บนเครื่องนี้ / PIN ผิด) เพื่อให้หน้าจอแจ้งตรงจุด
  Future<PinSignInFailure?> signInWithPin({
    required String phone,
    required String pin,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.signInWithPin(phone: phone, pin: pin);
      if (result.session != null) {
        _countdownTimer?.cancel();
        state = AuthState(session: result.session!, sessionResolved: true);
        return null;
      }
      state = state.copyWith(isSubmitting: false);
      return result.failure ?? PinSignInFailure.wrongPin;
    } catch (_) {
      state = state.copyWith(isSubmitting: false, errorCode: 'pin_failed');
      return PinSignInFailure.wrongPin;
    }
  }

  /// เช็กว่าเบอร์นี้เคยตั้ง PIN ไว้บนเครื่องนี้หรือยัง — ใช้ตัดสินว่าจะเสนอ
  /// ขั้นตั้ง PIN หลังยืนยัน OTP ไหม (สมัครใหม่ / เครื่องใหม่ / ลืม PIN)
  Future<bool> hasPinForPhone(String phone) {
    final repo = ref.read(authRepositoryProvider);
    return repo.hasPinForPhone(phone);
  }

  /// สถานะการกรอก PIN ผิดของเบอร์นี้ — ใช้แสดงจำนวนครั้งที่เหลือและเวลาล็อก
  Future<PinAttemptStatus?> pinAttemptStatus(String phone) {
    final repo = ref.read(authRepositoryProvider);
    return repo.pinAttemptStatus(phone);
  }

  /// ตั้ง PIN ให้บัญชีที่ล็อกอินอยู่ — คืน false ถ้าบัญชีไม่มีเบอร์ผูก
  Future<bool> setPinForCurrentAccount(String pin) async {
    final user = state.session.user;
    if (user == null || user.phone == null) return false;
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.setPin(user: user, pin: pin);
      state = state.copyWith(pinRevision: state.pinRevision + 1);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// ตรวจ PIN เดิมก่อนเริ่มขั้นเปลี่ยนในหน้าจัดการบัญชี
  Future<bool> verifyCurrentPin(String pin) {
    final user = state.session.user;
    if (user == null) return Future.value(false);
    final repo = ref.read(authRepositoryProvider);
    return repo.verifyCurrentPin(user: user, pin: pin);
  }

  /// เปลี่ยน PIN — ต้องยืนยัน PIN เดิมก่อน คืน false ถ้า PIN เดิมผิด
  Future<bool> changePinForCurrentAccount({
    required String currentPin,
    required String newPin,
  }) async {
    final user = state.session.user;
    if (user == null) return false;
    try {
      final repo = ref.read(authRepositoryProvider);
      final ok = await repo.changePin(
        user: user,
        currentPin: currentPin,
        newPin: newPin,
      );
      if (ok) {
        state = state.copyWith(pinRevision: state.pinRevision + 1);
      }
      return ok;
    } catch (_) {
      return false;
    }
  }

  Future<bool> signInWithProvider({
    required AuthMethod method,
    required int birthYear,
    required bool guardianConsentGranted,
    String? displayName,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final session = await repo.signInWithProvider(
        method: method,
        birthYear: birthYear,
        guardianConsentGranted: guardianConsentGranted,
        displayName: displayName,
      );
      _countdownTimer?.cancel();
      state = AuthState(session: session, sessionResolved: true);
      return true;
    } catch (_) {
      state = state.copyWith(isSubmitting: false, errorCode: 'oauth_failed');
      return false;
    }
  }

  /// จำว่าผู้ใช้เพิ่ง "ออกจากระบบ" เอง — ล็อกอินครั้งถัดไปพากลับหน้าหลัก
  /// เสมอ ไม่ย้อนไปหน้าที่เปิดลิงก์ล็อกอินไว้ (เช่น หน้าตั้งค่า)
  bool _consumeHomeAfterLogin = false;

  /// อ่าน + เคลียร์ธง "ล็อกอินครั้งนี้ให้ไปหน้าหลัก" — ใช้ครั้งเดียวแล้วทิ้ง
  bool consumeHomeAfterLoginFlag() {
    final value = _consumeHomeAfterLogin;
    _consumeHomeAfterLogin = false;
    return value;
  }

  Future<void> signOut() async {
    _countdownTimer?.cancel();
    state = state.copyWith(isSubmitting: true, clearError: true);
    final repo = ref.read(authRepositoryProvider);
    final guest = await repo.signOut();
    _consumeHomeAfterLogin = true;
    state = AuthState(session: guest, sessionResolved: true);
  }

  /// โหลดรายการแมวที่ผู้ใช้เป็นเจ้าของพร้อมผู้ดูแลร่วม สำหรับ flow ลบบัญชี (AUTH-05)
  Future<List<CatDeletionRequirement>> loadDeletionRequirements() {
    final repo = ref.read(authRepositoryProvider);
    return repo.loadDeletionRequirements();
  }

  /// ขอลบบัญชี — ระบบเก็บข้อมูลไว้ 30 วันก่อนลบถาวร และบังคับออกจากระบบทันที
  Future<bool> requestAccountDeletion({
    required Map<String, String?> transferDecisions,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.requestAccountDeletion(transferDecisions: transferDecisions);
      state = const AuthState(
        session: AuthSession.guest(),
        sessionResolved: true,
      );
      return true;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        errorCode: 'account_delete_failed',
      );
      return false;
    }
  }

  /// กู้คืนบัญชีที่อยู่ในช่วงรอลบ 30 วัน — คืน true ถ้ากู้สำเร็จ
  Future<bool> restorePendingDeletion() async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final restored = await repo.restorePendingDeletion();
      if (restored == null) {
        // ไม่มีบัญชีค้างลบหรือเลยกำหนด 30 วัน → ถือว่าบัญชีถูกลบถาวรแล้ว
        state = const AuthState(
          session: AuthSession.guest(),
          sessionResolved: true,
        );
        return false;
      }
      state = AuthState(session: restored, sessionResolved: true);
      return true;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        errorCode: 'account_restore_failed',
      );
      return false;
    }
  }

  /// ยืนยันลบบัญชีถาวรจากสถานะค้างลบ — เซิร์ฟเวอร์ mock จะลบตามกำหนด
  /// ฝั่งแอปแค่ล้าง session กลับเป็น guest เพื่อจบ flow
  Future<void> confirmPermanentDeletion() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.signOut();
    _consumeHomeAfterLogin = true;
    state = const AuthState(
      session: AuthSession.guest(),
      sessionResolved: true,
    );
  }

  void clearOtpChallenge() {
    _countdownTimer?.cancel();
    state = state.copyWith(clearOtpChallenge: true, clearError: true);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

/// สถานะ PIN ของบัญชีปัจจุบันสำหรับหน้าจัดการบัญชี — re-fetch อัตโนมัติเมื่อ
/// pinRevision เปลี่ยน (ตั้ง/เปลี่ยน PIN) บัญชีไม่มีเบอร์ผูกคืน false เสมอ
final accountPinStatusProvider = FutureProvider.autoDispose<bool>((ref) async {
  final authState = ref.watch(authControllerProvider);
  final phone = authState.session.user?.phone;
  if (phone == null) return false;
  return ref.read(authRepositoryProvider).hasPinForPhone(phone);
});

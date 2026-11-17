import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/datasources/auth_token_storage.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/auth_data.dart';
import '../../domain/repositories/auth_repository.dart';

final authTokenStorageProvider = Provider<AuthTokenStorage>(
  (ref) => InMemoryAuthTokenStorage(),
);

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => MockAuthRemoteDataSource(),
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.read(authRemoteDataSourceProvider),
    tokenStorage: ref.read(authTokenStorageProvider),
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
  });

  final AuthSession session;
  final bool isSubmitting;
  final OtpChallenge? otpChallenge;
  final String? errorCode;
  final int tickSeconds;

  /// true เมื่ออ่าน session จาก storage เสร็จแล้ว — ใช้แยกช่วงแอปเพิ่งเปิด
  /// ที่ยังไม่รู้ว่าผู้ใช้ล็อกอินค้างไว้หรือไม่ (เช่น กันเข้า /login ซ้ำ)
  final bool sessionResolved;

  bool get isAuthenticated => session.isAuthenticated;
  bool get isGuest => session.isGuest;

  AuthState copyWith({
    AuthSession? session,
    bool? isSubmitting,
    OtpChallenge? otpChallenge,
    bool clearOtpChallenge = false,
    String? errorCode,
    bool clearError = false,
    int? tickSeconds,
    bool? sessionResolved,
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

  Future<void> signOut() async {
    _countdownTimer?.cancel();
    state = state.copyWith(isSubmitting: true, clearError: true);
    final repo = ref.read(authRepositoryProvider);
    final guest = await repo.signOut();
    state = AuthState(session: guest, sessionResolved: true);
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

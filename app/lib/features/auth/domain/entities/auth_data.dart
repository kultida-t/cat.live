import 'package:equatable/equatable.dart';

/// ช่องทางเข้าสู่ระบบตามสเปก AUTH-03 และ Guest Mode (AUTH-01)
enum AuthMethod { phoneOtp, apple, google, line, guest }

/// สถานะเซสชันผู้ใช้ปัจจุบัน
enum AuthMode { guest, authenticated }

/// ข้อมูลบัญชีผู้ใช้ที่ผ่านการยืนยันตัวตนแล้ว
class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.displayName,
    required this.method,
    this.phone,
    this.phoneMasked,
    this.email,
    this.birthYear,
    this.guardianConsentGranted = false,
  });

  final String id;
  final String displayName;
  final AuthMethod method;

  /// เบอร์โทรแบบตัวเลขล้วนของบัญชี (เก็บใน secure storage) — ใช้ผูก PIN กับบัญชี
  final String? phone;
  final String? phoneMasked;
  final String? email;
  final int? birthYear;
  final bool guardianConsentGranted;

  @override
  List<Object?> get props => [
    id,
    displayName,
    method,
    phone,
    phoneMasked,
    email,
    birthYear,
    guardianConsentGranted,
  ];
}

/// ข้อมูล OTP Challenge (AUTH-03: หมดอายุ 5 นาที, ขอใหม่ได้หลัง 60 วิ, ผิด 5 ครั้งล็อก 15 นาที)
class OtpChallenge extends Equatable {
  const OtpChallenge({
    required this.refCode,
    required this.phoneNumber,
    required this.expiresAt,
    required this.resendAvailableAt,
    this.attemptsUsed = 0,
    this.maxAttempts = 5,
    this.lockedUntil,
  });

  final String refCode;
  final String phoneNumber;
  final DateTime expiresAt;
  final DateTime resendAvailableAt;
  final int attemptsUsed;
  final int maxAttempts;
  final DateTime? lockedUntil;

  int get remainingAttempts =>
      (maxAttempts - attemptsUsed).clamp(0, maxAttempts);

  bool isExpiredAt(DateTime now) => !now.isBefore(expiresAt);

  bool isLockedAt(DateTime now) =>
      lockedUntil != null && now.isBefore(lockedUntil!);

  int secondsUntilResend(DateTime now) {
    final diff = resendAvailableAt.difference(now).inSeconds;
    return diff > 0 ? diff : 0;
  }

  int secondsUntilExpiry(DateTime now) {
    final diff = expiresAt.difference(now).inSeconds;
    return diff > 0 ? diff : 0;
  }

  int secondsUntilUnlock(DateTime now) {
    if (lockedUntil == null) return 0;
    final diff = lockedUntil!.difference(now).inSeconds;
    return diff > 0 ? diff : 0;
  }

  OtpChallenge copyWith({
    String? refCode,
    String? phoneNumber,
    DateTime? expiresAt,
    DateTime? resendAvailableAt,
    int? attemptsUsed,
    int? maxAttempts,
    DateTime? lockedUntil,
    bool clearLockedUntil = false,
  }) {
    return OtpChallenge(
      refCode: refCode ?? this.refCode,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      expiresAt: expiresAt ?? this.expiresAt,
      resendAvailableAt: resendAvailableAt ?? this.resendAvailableAt,
      attemptsUsed: attemptsUsed ?? this.attemptsUsed,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      lockedUntil: clearLockedUntil ? null : (lockedUntil ?? this.lockedUntil),
    );
  }

  @override
  List<Object?> get props => [
    refCode,
    phoneNumber,
    expiresAt,
    resendAvailableAt,
    attemptsUsed,
    maxAttempts,
    lockedUntil,
  ];
}

/// สถานะเซสชันรวม Token สำหรับเตรียมสลับต่อ API จริง
class AuthSession extends Equatable {
  const AuthSession({
    required this.mode,
    this.user,
    this.accessToken,
    this.refreshToken,
    this.expiresAt,
    this.deletionScheduledAt,
  });

  const AuthSession.guest()
    : mode = AuthMode.guest,
      user = null,
      accessToken = null,
      refreshToken = null,
      expiresAt = null,
      deletionScheduledAt = null;

  final AuthMode mode;
  final AuthUser? user;
  final String? accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;

  /// เวลาที่ขอลบบัญชี (AUTH-05) — ไม่เป็น null = บัญชีอยู่ในช่วงรอลบ 30 วัน กู้คืนได้
  final DateTime? deletionScheduledAt;

  bool get isAuthenticated => mode == AuthMode.authenticated && user != null;
  bool get isGuest => !isAuthenticated;
  bool get isPendingDeletion => deletionScheduledAt != null;

  AuthSession copyWith({bool clearDeletionScheduledAt = false}) {
    return AuthSession(
      mode: mode,
      user: user,
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
      deletionScheduledAt: clearDeletionScheduledAt
          ? null
          : deletionScheduledAt,
    );
  }

  @override
  List<Object?> get props => [
    mode,
    user,
    accessToken,
    refreshToken,
    expiresAt,
    deletionScheduledAt,
  ];
}

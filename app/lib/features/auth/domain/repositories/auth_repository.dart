import '../entities/auth_data.dart';

/// สัญญา Repository สำหรับระบบยืนยันตัวตน (AUTH-01..04)
abstract interface class AuthRepository {
  Future<AuthSession> restoreSession();

  Future<AuthSession> enterGuestMode();

  Future<OtpChallenge> requestOtp(String phoneNumber);

  Future<
    ({AuthSession session, OtpChallenge? updatedChallenge, String? errorCode})
  >
  verifyOtp({
    required OtpChallenge challenge,
    required String code,
    required int birthYear,
    required bool guardianConsentGranted,
    String? displayName,
  });

  Future<AuthSession> signInWithProvider({
    required AuthMethod method,
    required int birthYear,
    required bool guardianConsentGranted,
    String? displayName,
  });

  Future<AuthSession> signOut();
}

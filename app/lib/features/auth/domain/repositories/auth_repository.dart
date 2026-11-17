import '../entities/auth_data.dart';
import '../entities/deletion_data.dart';

/// สัญญา Repository สำหรับระบบยืนยันตัวตน (AUTH-01..05)
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

  /// โหลดแมวที่ผู้ใช้เป็นเจ้าของพร้อมผู้ดูแลร่วม สำหรับ flow ลบบัญชี (AUTH-05)
  Future<List<CatDeletionRequirement>> loadDeletionRequirements();

  /// ขอลบบัญชี — `transferDecisions`: catId → caretakerId ที่รับโอนสิทธิ์
  /// (ไม่ใส่ catId หรือส่ง null = ลบโปรไฟล์แมวนั้นไปพร้อมบัญชี)
  /// สำเร็จแล้วบัญชีเข้าสถานะรอลบ 30 วันและ session กลายเป็น guest
  Future<void> requestAccountDeletion({
    required Map<String, String?> transferDecisions,
  });

  /// กู้คืนบัญชีที่อยู่ในช่วงรอลบ 30 วัน — คืน session ที่เคลียร์สถานะรอลบแล้ว
  /// คืน null ถ้าไม่มีบัญชีค้างลบหรือเลยกำหนดไปแล้ว
  Future<AuthSession?> restorePendingDeletion();
}

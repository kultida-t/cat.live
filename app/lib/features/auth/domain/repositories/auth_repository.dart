import '../entities/auth_data.dart';
import '../entities/deletion_data.dart';

/// เหตุผลที่ล็อกอินด้วย PIN ไม่สำเร็จ — แยกเคสเบอร์ยังไม่มี PIN กับ PIN ผิด
/// เพื่อให้หน้าจอแจ้งผู้ใช้ตรงจุดและพาไปใช้ OTP ได้
enum PinSignInFailure { noPinForPhone, wrongPin }

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

  /// ล็อกอินด้วยเบอร์ + PIN 6 หลัก — เช็กกับ PIN ที่ผู้ใช้ตั้งไว้บนเครื่องนี้
  /// เบอร์ต้องตรงกับบัญชีที่เคยตั้ง PIN ไว้เท่านั้น
  Future<({AuthSession? session, PinSignInFailure? failure})> signInWithPin({
    required String phone,
    required String pin,
  });

  /// เช็กว่าเบอร์นี้เคยตั้ง PIN ไว้บนเครื่องนี้หรือยัง
  Future<bool> hasPinForPhone(String phone);

  /// ตั้ง PIN ให้บัญชีที่ล็อกอินอยู่ — บัญชีต้องผูกเบอร์ (`user.phone`)
  Future<void> setPin({required AuthUser user, required String pin});

  /// ตรวจ PIN เดิมของบัญชีที่ล็อกอินอยู่ก่อนเริ่มขั้นเปลี่ยน
  Future<bool> verifyCurrentPin({required AuthUser user, required String pin});

  /// เปลี่ยน PIN — ต้องยืนยัน PIN เดิมก่อน คืน false ถ้า PIN เดิมผิด
  Future<bool> changePin({
    required AuthUser user,
    required String currentPin,
    required String newPin,
  });

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

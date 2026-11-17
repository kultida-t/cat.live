/// เกณฑ์อายุตาม PDPA-03
enum AgeEligibility {
  missing,
  under13Blocked,
  minorNeedsGuardianConsent,
  adult,
}

/// Business Logic สำหรับ Auth / OTP / Age Compliance (แยกออกจาก Widget)
abstract final class AuthRules {
  static const otpTtl = Duration(minutes: 5);
  static const otpResendCooldown = Duration(seconds: 60);
  static const otpMaxAttempts = 5;
  static const otpLockDuration = Duration(minutes: 15);
  static const mockValidOtp = '123456';

  /// PIN ใช้กติกาเดียวกับ OTP: ผิดครบ 5 ครั้งล็อก 15 นาที
  static const pinMaxAttempts = otpMaxAttempts;
  static const pinLockDuration = otpLockDuration;

  /// แปลงเบอร์โทรให้เหลือเฉพาะตัวเลข (รองรับ +66 -> 0)
  static String normalizeThaiPhone(String raw) {
    var digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('66') && digits.length >= 11) {
      digits = '0${digits.substring(2)}';
    }
    return digits;
  }

  /// ตรวจสอบรูปแบบเบอร์มือถือไทย (10 หลัก ขึ้นต้นด้วย 06 / 08 / 09)
  static bool isValidThaiPhone(String raw) {
    final digits = normalizeThaiPhone(raw);
    return RegExp(r'^0[689]\d{8}$').hasMatch(digits);
  }

  /// ปิดบังตัวเลขตรงกลางสำหรับแสดงบนหน้าจอ
  static String maskThaiPhone(String raw) {
    final digits = normalizeThaiPhone(raw);
    if (digits.length != 10) return raw;
    return '${digits.substring(0, 3)}-xxx-${digits.substring(6)}';
  }

  /// ตรวจเกณฑ์อายุตาม PDPA-03: ต่ำกว่า 13 สมัครไม่ได้, 13–19 ต้องมีผู้ปกครองยินยอม
  static AgeEligibility evaluateAge({
    required int? birthYear,
    required int currentYear,
  }) {
    if (birthYear == null) return AgeEligibility.missing;
    final age = currentYear - birthYear;
    if (age < 13) return AgeEligibility.under13Blocked;
    if (age < 20) return AgeEligibility.minorNeedsGuardianConsent;
    return AgeEligibility.adult;
  }
}

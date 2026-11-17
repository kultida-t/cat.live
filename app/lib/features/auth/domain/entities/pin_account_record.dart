import 'package:equatable/equatable.dart';

import 'auth_data.dart';

/// ข้อมูลบัญชีที่ตั้ง PIN ไว้บนเครื่องนี้ — PIN ผูกกับเบอร์โทรของบัญชีนั้น
/// เก็บเฉพาะ hash กับ salt ไม่เก็บ PIN ตัวจริง และเก็บโปรไฟล์บัญชีไว้
/// เพื่อให้ล็อกอินด้วย PIN แล้วสร้าง session ของบัญชีเดิมกลับมาได้ (mock)
class PinAccountRecord extends Equatable {
  const PinAccountRecord({
    required this.userId,
    required this.phone,
    required this.salt,
    required this.pinHash,
    required this.displayName,
    required this.method,
    this.phoneMasked,
    this.email,
    this.birthYear,
    this.guardianConsentGranted = false,
  });

  final String userId;

  /// เบอร์โทรแบบตัวเลขล้วนที่ผูกกับ PIN — ใช้เป็นกุญแจหลักตอนล็อกอิน
  final String phone;

  final String salt;
  final String pinHash;
  final String displayName;
  final AuthMethod method;
  final String? phoneMasked;
  final String? email;
  final int? birthYear;
  final bool guardianConsentGranted;

  /// สร้าง AuthUser กลับจากโปรไฟล์ที่เก็บไว้ เพื่อคืนบัญชีเดิมหลังล็อกอินด้วย PIN
  AuthUser toAuthUser() {
    return AuthUser(
      id: userId,
      displayName: displayName,
      method: method,
      phone: phone,
      phoneMasked: phoneMasked,
      email: email,
      birthYear: birthYear,
      guardianConsentGranted: guardianConsentGranted,
    );
  }

  @override
  List<Object?> get props => [
    userId,
    phone,
    salt,
    pinHash,
    displayName,
    method,
    phoneMasked,
    email,
    birthYear,
    guardianConsentGranted,
  ];
}

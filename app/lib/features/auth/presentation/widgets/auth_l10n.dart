import '../../../../core/config/pet_species_config.dart';

/// ข้อความ 2 ภาษา (ไทย/EN) สำหรับหน้า Login, OTP และ Guest Mode (AUTH-01..04)
abstract final class AuthL10n {
  static String pageTitle(bool isEn) => isEn ? 'Sign in' : 'เข้าสู่ระบบ';

  static String tabSignIn(bool isEn) => isEn ? 'Sign in' : 'เข้าสู่ระบบ';

  static String tabRegister(bool isEn) => isEn ? 'Register' : 'สมัครสมาชิก';

  static String displayNameLabel(bool isEn) =>
      isEn ? 'Display name (optional)' : 'ชื่อที่แสดง (ไม่บังคับ)';

  static String displayNameHint(bool isEn) =>
      isEn ? 'e.g. Lookkaew' : 'เช่น ลูกแก้ว';

  static String backLabel(bool isEn) => isEn ? 'Back' : 'ย้อนกลับ';

  static String headline(PetSpeciesConfig species, bool isEn) => isEn
      ? 'Welcome to ${species.brandName(true)}'
      : 'ยินดีต้อนรับสู่ ${species.brandName(false)}';

  static String subheadline(PetSpeciesConfig species, bool isEn) => isEn
      ? 'Care for ${species.petNoun(true).toLowerCase()} profiles, health & community.'
      : 'ดูแลโปรไฟล์ สมุดสุขภาพ และชุมชนคนรัก${species.petNoun(false)}';

  static String birthYearLabel(bool isEn) => isEn
      ? 'Birth year (CE) for age verification'
      : 'ปีเกิด (ค.ศ.) เพื่อตรวจเกณฑ์อายุ PDPA';

  static String birthYearUnder13Error(bool isEn) => isEn
      ? 'Users under 13 years old cannot register (PDPA-03).'
      : 'ผู้ใช้อายุต่ำกว่า 13 ปีไม่สามารถสมัครใช้งานได้ (PDPA-03)';

  static String guardianConsentLabel(bool isEn) => isEn
      ? 'I am 13–19 years old and have parental/guardian consent.'
      : 'อายุ 13–19 ปี และได้รับความยินยอมจากผู้ปกครองแล้ว';

  static String guardianConsentRequiredError(bool isEn) => isEn
      ? 'Guardian consent is required for ages 13–19.'
      : 'กรุณายืนยันความยินยอมจากผู้ปกครองสำหรับอายุ 13–19 ปี';

  static String pdpaTermsLabel(bool isEn) => isEn
      ? 'I accept the Terms and Privacy Policy (PDPA)'
      : 'ยอมรับข้อกำหนดและนโยบายคุ้มครองข้อมูล (PDPA)';

  static String pdpaReadMore(bool isEn) =>
      isEn ? 'Read details' : 'อ่านรายละเอียด';

  static String pdpaSheetTitle(bool isEn) => isEn
      ? 'Terms & Privacy Policy (PDPA)'
      : 'ข้อกำหนดและนโยบายคุ้มครองข้อมูล (PDPA)';

  static String pdpaSheetClose(bool isEn) => isEn ? 'Close' : 'ปิด';

  static String pickerCancel(bool isEn) => isEn ? 'Cancel' : 'ยกเลิก';

  static String pickerDone(bool isEn) => isEn ? 'Done' : 'ตกลง';

  static String pickerTitle(bool isEn) =>
      isEn ? 'Select birth year' : 'เลือกปีเกิด';

  static String pdpaRequiredError(bool isEn) => isEn
      ? 'Please accept the Terms and Privacy Policy first.'
      : 'กรุณายอมรับเงื่อนไขและนโยบาย PDPA ก่อนดำเนินการต่อ';

  static String phoneLabel(bool isEn) =>
      isEn ? 'Phone number' : 'เบอร์โทรศัพท์มือถือ';

  static String phoneHint(bool isEn) => '081-234-5678';

  static String invalidPhoneError(bool isEn) => isEn
      ? 'Please enter a valid 10-digit Thai mobile number.'
      : 'กรุณากรอกเบอร์มือถือไทย 10 หลักให้ถูกต้อง (เช่น 0812345678)';

  static String pinLabel(bool isEn) => isEn ? '6-digit PIN' : 'รหัส PIN 6 หลัก';

  static String signInWithPinBtn(bool isEn) =>
      isEn ? 'Sign in with PIN' : 'เข้าสู่ระบบด้วย PIN';

  static String biometricBtn(bool isEn) => isEn
      ? 'Sign in with Face ID / Touch ID'
      : 'เข้าสู่ระบบด้วย Face ID / สแกนนิ้ว';

  static String switchDeviceOtpLink(bool isEn) => isEn
      ? 'New device or forgot PIN? Verify with OTP'
      : 'เปลี่ยนเครื่อง / ลืม PIN? ยืนยันด้วยรหัส OTP';

  static String invalidPinError(bool isEn) => isEn
      ? 'Incorrect PIN. Please try again.'
      : 'รหัส PIN ไม่ถูกต้อง กรุณาลองใหม่อีกครั้ง';

  static String requestOtpBtn(bool isEn) => isEn ? 'Request OTP' : 'ขอรหัส OTP';

  static String orDivider(bool isEn) =>
      isEn ? 'or continue with' : 'หรือเข้าสู่ระบบด้วย';

  static String appleBtn(bool isEn) =>
      isEn ? 'Sign in with Apple' : 'เข้าสู่ระบบด้วย Apple';

  static String googleBtn(bool isEn) =>
      isEn ? 'Continue with Google' : 'ดำเนินการต่อด้วย Google';

  static String lineBtn(bool isEn) =>
      isEn ? 'Continue with LINE' : 'ดำเนินการต่อด้วย LINE';

  static String guestBtn(bool isEn) =>
      isEn ? 'Continue as Guest' : 'เข้าใช้งานต่อแบบผู้เยี่ยมชม (Guest Mode)';

  static String guestHint(bool isEn) => isEn
      ? 'Guests can browse Feed, Nearby, and Help. Sign in anytime to post or manage profiles.'
      : 'ผู้เยี่ยมชมดูฟีด ใกล้ฉัน และช่วยเหลือได้ — เข้าสู่ระบบได้ทุกเมื่อเมื่อต้องการโพสต์หรือดูแลโปรไฟล์';

  // ขั้นตอน OTP
  static String otpTitle(bool isEn) => isEn ? 'Verify OTP' : 'ยืนยันรหัส OTP';

  static String otpSubtitle(String maskedPhone, String ref, bool isEn) => isEn
      ? 'Sent 6-digit code to $maskedPhone (Ref: $ref)'
      : 'ส่งรหัส 6 หลักไปยัง $maskedPhone แล้ว (Ref: $ref)';

  static String otpMockHelper(bool isEn) => isEn
      ? 'Mock OTP code for testing: 123456'
      : 'รหัส OTP จำลองสำหรับทดสอบ: 123456';

  static String fillMockOtp(bool isEn) => isEn ? 'Fill 123456' : 'กรอก 123456';

  static String otpInputHint(bool isEn) =>
      isEn ? '6-digit OTP' : 'กรอกรหัส OTP 6 หลัก';

  static String verifyOtpBtn(bool isEn) =>
      isEn ? 'Verify & Sign in' : 'ยืนยันและเข้าสู่ระบบ';

  static String resendOtpBtn(int cooldownSeconds, bool isEn) {
    if (cooldownSeconds > 0) {
      return isEn
          ? 'Resend in ${cooldownSeconds}s'
          : 'ขอรหัสใหม่ได้ใน $cooldownSeconds วิ';
    }
    return isEn ? 'Resend OTP' : 'ขอรหัส OTP ใหม่';
  }

  static String changePhoneBtn(bool isEn) =>
      isEn ? 'Change phone number' : 'เปลี่ยนเบอร์โทรศัพท์';

  // ขั้นตั้ง PIN หลังยืนยัน OTP (สมัครใหม่ / เครื่องใหม่ / ลืม PIN)
  static String pinSetupTitle(bool isEn) =>
      isEn ? 'Set up your PIN' : 'ตั้งรหัส PIN 6 หลัก';

  static String pinSetupSubtitle(bool isEn) => isEn
      ? 'Use this PIN to sign in faster on this device next time.'
      : 'ใช้รหัสนี้เข้าสู่ระบบบนเครื่องนี้ได้เร็วขึ้นในครั้งถัดไป';

  static String pinSetupNewLabel(bool isEn) =>
      isEn ? 'New 6-digit PIN' : 'รหัส PIN 6 หลัก';

  static String pinSetupConfirmLabel(bool isEn) =>
      isEn ? 'Confirm PIN' : 'ยืนยันรหัส PIN อีกครั้ง';

  static String pinSetupMismatchError(bool isEn) => isEn
      ? 'PINs do not match. Please enter the same PIN in both fields.'
      : 'รหัส PIN ไม่ตรงกัน กรุณากรอกให้เหมือนกันทั้งสองช่อง';

  static String pinSetupSaveBtn(bool isEn) =>
      isEn ? 'Save & continue' : 'บันทึกและเข้าใช้งาน';

  static String pinSetupLaterBtn(bool isEn) => isEn ? 'Later' : 'ไว้ทีหลัง';

  static String pinSaveFailedError(bool isEn) => isEn
      ? 'Could not save your PIN. Please try again.'
      : 'บันทึกรหัส PIN ไม่สำเร็จ กรุณาลองใหม่อีกครั้ง';

  static String noPinForPhoneError(bool isEn) => isEn
      ? 'No PIN set for this number on this device — verify with OTP instead.'
      : 'เบอร์นี้ยังไม่ได้ตั้งรหัส PIN บนเครื่องนี้ ใช้ OTP ยืนยันตัวตนแทนได้เลย';

  // หน้าจัดการ PIN ในบัญชี (ตั้งครั้งแรก / เปลี่ยน)
  static String pinManageTitle(bool hasPin, bool isEn) => hasPin
      ? (isEn ? 'Change PIN' : 'เปลี่ยนรหัส PIN')
      : (isEn ? 'Set up PIN' : 'ตั้งรหัส PIN');

  static String pinCurrentLabel(bool isEn) =>
      isEn ? 'Current PIN' : 'รหัส PIN เดิม';

  static String pinCurrentHint(bool isEn) => isEn
      ? 'Enter your current 6-digit PIN first'
      : 'กรอกรหัส PIN เดิมเพื่อยืนยันตัวตนก่อนเปลี่ยน';

  static String pinWrongCurrentError(bool isEn) => isEn
      ? 'Current PIN is incorrect. Please try again.'
      : 'รหัส PIN เดิมไม่ถูกต้อง กรุณาลองใหม่อีกครั้ง';

  static String pinNextBtn(bool isEn) => isEn ? 'Next' : 'ถัดไป';

  static String pinDoneTitle(bool hasPin, bool isEn) => hasPin
      ? (isEn ? 'PIN changed' : 'เปลี่ยนรหัส PIN เรียบร้อยแล้ว')
      : (isEn ? 'PIN set' : 'ตั้งรหัส PIN เรียบร้อยแล้ว');

  static String pinDoneSubtitle(bool isEn) => isEn
      ? 'Use this PIN to sign in on this device from now on.'
      : 'ครั้งต่อไปใช้รหัส PIN นี้เข้าสู่ระบบบนเครื่องนี้ได้เลย';

  static String doneBtn(bool isEn) => isEn ? 'Done' : 'เสร็จ';

  static String pinNoPhoneHint(bool isEn) => isEn
      ? 'PIN is available only for accounts linked to a phone number.'
      : 'ใช้รหัส PIN ได้เฉพาะบัญชีที่ผูกเบอร์โทรศัพท์เท่านั้น';

  static String otpErrorText(
    String code,
    int remainingAttempts,
    int unlockSeconds,
    bool isEn,
  ) {
    return switch (code) {
      'otp_expired' =>
        isEn
            ? 'OTP expired (5 minutes). Please request a new code.'
            : 'รหัส OTP หมดอายุแล้ว (เกิน 5 นาที) กรุณาขอรหัสใหม่',
      'otp_locked' =>
        isEn
            ? 'Too many failed attempts (5/5). Locked for ${(unlockSeconds / 60).ceil()} min.'
            : 'กรอกรหัสผิดครบ 5 ครั้ง ระบบล็อกชั่วคราว ${(unlockSeconds / 60).ceil()} นาที',
      'otp_invalid' =>
        isEn
            ? 'Incorrect OTP ($remainingAttempts attempts remaining).'
            : 'รหัส OTP ไม่ถูกต้อง (เหลือสิทธิ์อีก $remainingAttempts ครั้ง)',
      _ =>
        isEn
            ? 'Verification failed. Please try again.'
            : 'ไม่สามารถยืนยันได้ กรุณาลองใหม่อีกครั้ง',
    };
  }
}

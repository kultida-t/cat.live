import '../../../../core/config/app_text_scale.dart';
import '../../domain/entities/settings_data.dart';

/// ข้อความ 2 ภาษา (ไทย/EN) สำหรับหน้าตั้งค่าและศูนย์ช่วยเหลือ (/settings)
abstract final class SettingsL10n {
  static String pageTitle(bool isEn) =>
      isEn ? 'Settings & Help' : 'ตั้งค่าและช่วยเหลือ';
  static String backLabel(bool isEn) => isEn ? 'Back' : 'ย้อนกลับ';
  static String loadError(bool isEn) =>
      isEn ? 'Could not load settings' : 'โหลดการตั้งค่าไม่สำเร็จ';
  static String emptyTitle(bool isEn) =>
      isEn ? 'No settings available' : 'ยังไม่มีข้อมูลการตั้งค่า';
  static String emptySubtitle(bool isEn) =>
      isEn ? 'Tap retry to reload' : 'แตะลองใหม่เพื่อโหลดข้อมูลอีกครั้ง';
  static String retry(bool isEn) => isEn ? 'Retry' : 'ลองใหม่';

  // Sections
  static String sectionAccount(bool isEn) => isEn ? 'Display' : 'การแสดงผล';
  static String sectionNotifications(bool isEn) =>
      isEn ? 'Notifications' : 'การแจ้งเตือน';
  static String sectionPrivacy(bool isEn) =>
      isEn ? 'Privacy & PDPA' : 'ความเป็นส่วนตัว & PDPA';
  static String sectionSupport(bool isEn) =>
      isEn ? 'Devices, Rules & Help' : 'อุปกรณ์ กฎ และศูนย์ช่วยเหลือ';

  // Account & Display
  static String verifiedBadge(bool isEn) =>
      isEn ? 'Verified account' : 'บัญชีที่ยืนยันแล้ว';
  static String languageTitle(bool isEn) => isEn ? 'Language' : 'ภาษา';
  static String textSizeTitle(bool isEn) => isEn ? 'Text size' : 'ขนาดตัวอักษร';
  static String textSizeLabel(AppTextSizePreset preset, bool isEn) =>
      switch (preset) {
        AppTextSizePreset.small => isEn ? 'Small' : 'เล็ก',
        AppTextSizePreset.normal => isEn ? 'Normal' : 'ปกติ',
        AppTextSizePreset.large => isEn ? 'Large' : 'ใหญ่',
      };
  static String textSizeChangedToast(AppTextSizePreset preset, bool isEn) {
    final label = textSizeLabel(preset, isEn);
    return isEn ? 'Text size: $label' : 'ปรับขนาดตัวอักษรเป็น "$label" แล้ว';
  }

  // Notifications (NOTI-01 / NOTI-02)
  static String pushTitle(bool isEn) => isEn ? 'Notifications' : 'การแจ้งเตือน';
  static String pushToast(bool enabled, bool isEn) {
    if (isEn) return enabled ? 'Notifications enabled' : 'Notifications muted';
    return enabled ? 'เปิดการแจ้งเตือนแล้ว' : 'ปิดการแจ้งเตือนแล้ว';
  }

  static String quietHoursTitle(bool isEn) =>
      isEn ? 'Quiet hours' : 'โหมดเงียบ';
  static String quietHoursSubtitle(String start, String end, bool isEn) => isEn
      ? 'Mute $start–$end except meds & cat found'
      : 'ไม่แจ้งเตือน $start–$end ยกเว้นเตือนยาและพบแมว';
  static String quietHoursToast(
    bool enabled,
    String start,
    String end,
    bool isEn,
  ) {
    if (isEn) {
      return enabled
          ? 'Quiet hours enabled ($start–$end)'
          : 'Quiet hours disabled';
    }
    return enabled ? 'เปิดโหมดเงียบแล้ว ($start–$end)' : 'ปิดโหมดเงียบแล้ว';
  }

  static String quietScheduleAction(bool isEn) =>
      isEn ? 'Adjust quiet hours' : 'ปรับช่วงเวลาโหมดเงียบ';
  static String quietScheduleNote(bool isEn) => isEn
      ? 'Medication reminders and "Cat found" alerts are always delivered.'
      : 'เตือนกินยาและแจ้งเตือน "มีคนพบแมว" จะยังคงส่งถึงเสมอแม้เปิดโหมดเงียบ';

  static String notiCategoriesTitle(bool isEn) =>
      isEn ? 'Notification types' : 'จัดการประเภทการแจ้งเตือน';
  static String notiCategoriesSubtitle(
    int enabledCount,
    int total,
    bool isEn,
  ) => isEn
      ? 'Enabled $enabledCount of $total categories'
      : 'เปิดอยู่ $enabledCount จาก $total ประเภท';
  static String notiLockedBadge(bool isEn) => isEn ? 'Always on' : 'ปิดไม่ได้';
  static String notiLockedToast(bool isEn) => isEn
      ? '"Cat found" alerts cannot be turned off for your cat’s safety'
      : 'ไม่สามารถปิดแจ้งเตือน "มีคนพบแมว" ได้ เพื่อความปลอดภัยของน้องแมว';

  static String categoryTitle(NotificationCategoryKey key, bool isEn) =>
      switch (key) {
        NotificationCategoryKey.care =>
          isEn ? 'Daily care & meds' : 'เตือนการดูแล (อาหาร/น้ำ/ยา)',
        NotificationCategoryKey.catFound =>
          isEn ? 'Cat found (QR scan)' : 'มีคนพบแมว (สแกน Cat ID)',
        NotificationCategoryKey.lostCatNearby =>
          isEn ? 'Lost cats nearby' : 'แมวหายใกล้ตัว',
        NotificationCategoryKey.caregiverInvite =>
          isEn ? 'Caregiver invitations' : 'คำเชิญผู้ดูแลร่วม',
        NotificationCategoryKey.directMessage =>
          isEn ? 'Direct messages (DM)' : 'ข้อความส่วนตัว (DM)',
        NotificationCategoryKey.postInteraction =>
          isEn ? 'Likes & comments' : 'ปฏิสัมพันธ์บนโพสต์',
        NotificationCategoryKey.order =>
          isEn ? 'Tag & shop orders' : 'สถานะออเดอร์สินค้า',
        NotificationCategoryKey.teamAnnouncement =>
          isEn ? 'Team announcements' : 'ประกาศจากทีม แมว.live',
      };

  // Privacy & PDPA (PDPA-01 / PDPA-02)
  static String pdpaRowTitle(bool isEn) =>
      isEn ? 'Privacy & PDPA' : 'ความเป็นส่วนตัว & PDPA';
  static String pdpaRowSubtitle(int grantedCount, int total, bool isEn) => isEn
      ? 'Consents ($grantedCount/$total) · Data export · Policies'
      : 'ความยินยอม ($grantedCount/$total) · ขอสำเนาข้อมูล · นโยบาย';

  static String pdpaConsentTitle(PdpaConsentKey key, bool isEn) =>
      switch (key) {
        PdpaConsentKey.location =>
          isEn ? 'Location access' : 'ตำแหน่งที่ตั้ง (Location)',
        PdpaConsentKey.marketing =>
          isEn ? 'Marketing & promotions' : 'ข่าวสารการตลาดและโปรโมชัน',
        PdpaConsentKey.aiTraining =>
          isEn ? 'Use data to train Cat AI' : 'ใช้ข้อมูลช่วยฝึกฝน Cat AI',
      };

  static String pdpaConsentDesc(PdpaConsentKey key, bool isEn) => switch (key) {
    PdpaConsentKey.location =>
      isEn
          ? 'Find nearby vets, cafes, and lost cat alerts around you.'
          : 'ใช้ค้นหาคลินิก คาเฟ่ และแจ้งเตือนประกาศแมวหายรอบตัวคุณ',
    PdpaConsentKey.marketing =>
      isEn
          ? 'Receive updates about new services and partner offers.'
          : 'รับข่าวสารบริการใหม่และสิทธิพิเศษจากพาร์ทเนอร์ แมว.live',
    PdpaConsentKey.aiTraining =>
      isEn
          ? 'Help improve Cat AI health insights (anonymized data).'
          : 'ช่วยพัฒนาความแม่นยำของ Cat AI (ข้อมูลไม่ระบุตัวตน)',
  };

  static String pdpaVersionLine(String version, String updated, bool isEn) =>
      isEn
      ? 'Version $version · Updated $updated'
      : 'เวอร์ชัน $version · อัปเดต $updated';

  static String privacyPolicyTitle(bool isEn) =>
      isEn ? 'Privacy Policy' : 'นโยบายความเป็นส่วนตัว';
  static String termsTitle(bool isEn) =>
      isEn ? 'Terms of Service' : 'ข้อกำหนดการใช้งาน';
  static String dataExportBtn(bool requested, bool isEn) {
    if (requested) {
      return isEn
          ? 'Data export requested (JSON + PDF within 30 days)'
          : 'ส่งคำขอสำเนาข้อมูลแล้ว (รับ JSON + PDF ภายใน 30 วัน)';
    }
    return isEn
        ? 'Request my data copy (JSON + PDF)'
        : 'ขอสำเนาข้อมูลของฉัน (JSON + PDF)';
  }

  static String dataExportToast(bool isEn) => isEn
      ? 'Data export request submitted. You will receive JSON + PDF within 30 days.'
      : 'รับคำขอสำเนาข้อมูลแล้ว ระบบจะส่งไฟล์ JSON + PDF ให้ภายใน 30 วัน';

  // Devices, Rules & Help
  static String tagDevicesTitle(bool isEn) =>
      isEn ? 'แมว.live Tag devices' : 'อุปกรณ์ แมว.live Tag';
  static String tagDevicesSubtitle(bool isEn) => isEn
      ? 'Battery · Sound · Connection · Add tag'
      : 'แบตเตอรี่ · เสียง · การเชื่อมต่อ · เพิ่มแท็ก';
  static String communityRulesTitle(bool isEn) =>
      isEn ? 'Community rules' : 'กฎการโพสต์ในชุมชน';
  static String communityRulesSubtitle(bool isEn) => isEn
      ? 'Pet food ads allowed for partner brands only'
      : 'อาหารแมวโฆษณาได้เฉพาะแบรนด์พาร์ทเนอร์';
  static String helpCenterTitle(bool isEn) =>
      isEn ? 'Help Center & Contact' : 'ศูนย์ช่วยเหลือ & ติดต่อทีม';
  static String helpCenterSubtitle(bool isEn) => isEn
      ? 'FAQs · Report an issue · Contact support'
      : 'คำถามที่พบบ่อย · แจ้งปัญหา · ติดต่อทีมงาน';

  static String signOut(bool isEn) => isEn ? 'Sign out' : 'ออกจากระบบ';
  static String signOutConfirmTitle(bool isEn) =>
      isEn ? 'Sign out?' : 'ออกจากระบบ?';
  static String signOutConfirmBody(bool isEn) => isEn
      ? 'Your cats and health records stay safe.\nYou can sign in again anytime.'
      : 'ข้อมูลแมวและประวัติสุขภาพยังอยู่ครบ\nเข้าสู่ระบบใหม่ได้ทุกเมื่อ';
  static String cancel(bool isEn) => isEn ? 'Cancel' : 'ยกเลิก';
  static String signOutDoneToast(bool isEn) => isEn
      ? 'Demo account signed out (mock mode)'
      : 'ออกจากระบบตัวอย่างแล้ว (โหมด Mock)';
  static String versionFooter(String ver, bool isEn) =>
      isEn ? 'แมว.live version $ver' : 'แมว.live เวอร์ชัน $ver';
}

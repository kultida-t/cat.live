import '../../domain/entities/settings_data.dart';

/// แหล่งข้อมูลตัวอย่างสำหรับหน้าตั้งค่าและศูนย์ช่วยเหลือ (/settings)
class MockSettingsDataSource {
  SettingsData _current = const SettingsData(
    accountName: 'จุฑามาศ ลูกแก้ว',
    accountHandle: '@jutamas.lk',
    accountAvatarSource:
        'asset:assets/images/avatars/1494790108377-be9c29b29330.jpg',
    accountVerified: true,
    pushEnabled: true,
    quietHoursEnabled: false,
    quietStart: '22:00',
    quietEnd: '07:00',
    notificationCategories: {
      NotificationCategoryKey.care: true,
      NotificationCategoryKey.catFound: true,
      NotificationCategoryKey.lostCatNearby: true,
      NotificationCategoryKey.caregiverInvite: true,
      NotificationCategoryKey.directMessage: true,
      NotificationCategoryKey.postInteraction: true,
      NotificationCategoryKey.order: true,
      NotificationCategoryKey.teamAnnouncement: true,
    },
    pdpaConsents: [
      PdpaConsentItem(
        key: PdpaConsentKey.location,
        granted: true,
        version: 'v1.0',
        updatedAtLabel: '16 พ.ย. 2569',
      ),
      PdpaConsentItem(
        key: PdpaConsentKey.marketing,
        granted: false,
        version: 'v1.0',
        updatedAtLabel: '16 พ.ย. 2569',
      ),
      PdpaConsentItem(
        key: PdpaConsentKey.aiTraining,
        granted: false,
        version: 'v1.0',
        updatedAtLabel: '16 พ.ย. 2569',
      ),
    ],
    dataExportRequested: false,
    faqs: [
      SettingsFaqItem(
        id: 'faq-cat-id',
        questionTh: 'Cat ID สาธารณะเปิดเผยข้อมูลส่วนตัวอะไรบ้าง?',
        questionEn: 'What info is shown on my public Cat ID?',
        answerTh:
            'แสดงเฉพาะชื่อ รูปแมว และช่องทางติดต่อที่คุณเลือกเปิดไว้ในหน้า Cat ID เท่านั้น ไม่แสดงเบอร์โทรหรือที่อยู่จริงโดยไม่ได้รับอนุญาต',
        answerEn:
            'Only your cat’s name, photo, and contact channels you choose to show. Your real phone number and address stay hidden unless permitted.',
      ),
      SettingsFaqItem(
        id: 'faq-quiet',
        questionTh: 'โหมดเงียบจะปิดการแจ้งเตือนฉุกเฉินด้วยไหม?',
        questionEn: 'Does Quiet hours mute emergency alerts?',
        answerTh:
            'ไม่ครับ ช่วงโหมดเงียบ (เช่น 22:00–07:00) จะปิดเฉพาะแจ้งเตือนทั่วไป แต่เตือนกินยาและแจ้งเตือน "มีคนพบแมว" ยังส่งถึงเสมอ',
        answerEn:
            'No. Quiet hours only mute general alerts. Medication reminders and "Cat found" alerts are always delivered.',
      ),
      SettingsFaqItem(
        id: 'faq-pdpa',
        questionTh: 'ขอสำเนาข้อมูลส่วนตัว (PDPA) ใช้เวลานานแค่ไหน?',
        questionEn: 'How long does a PDPA data export take?',
        answerTh:
            'ระบบจะจัดเตรียมไฟล์สำเนาข้อมูลในรูปแบบ JSON และ PDF ส่งให้ทางอีเมลที่ผูกกับบัญชีภายใน 30 วัน',
        answerEn:
            'We prepare your data export in JSON and PDF formats and send it to your account email within 30 days.',
      ),
      SettingsFaqItem(
        id: 'faq-tag',
        questionTh: 'แมว.live Tag ผูกกับแมวมากกว่า 1 ตัวพร้อมกันได้ไหม?',
        questionEn: 'Can one แมว.live Tag link to multiple cats?',
        answerTh:
            'Tag 1 อันผูกได้กับแมว 1 ตัวเพื่อให้สแกนเจอตัวถูกตัว หาก Tag หายสามารถย้ายหรือยกเลิกการผูกในหน้าอุปกรณ์ได้',
        answerEn:
            'Each Tag links to one cat at a time for accurate scanning. You can unpair or reassign it anytime from Tag devices.',
      ),
    ],
    appVersion: '0.1',
  );

  Future<SettingsData> getSettings() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return _current;
  }

  Future<SettingsData> saveSettings(SettingsData next) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    // บังคับตาม NOTI-01: "มีคนพบแมว" ปิดไม่ได้
    final fixedCategories = Map<NotificationCategoryKey, bool>.from(
      next.notificationCategories,
    )..[NotificationCategoryKey.catFound] = true;
    _current = next.copyWith(notificationCategories: fixedCategories);
    return _current;
  }

  Future<void> requestDataExport() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    _current = _current.copyWith(dataExportRequested: true);
  }

  Future<void> submitSupportMessage({
    required String subject,
    required String message,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }
}

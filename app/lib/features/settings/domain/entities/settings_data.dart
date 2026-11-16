import 'package:equatable/equatable.dart';

/// ประเภทการแจ้งเตือน 8 หมวดตาม NOTI-01 (catFound ปิดไม่ได้เพื่อความปลอดภัย)
enum NotificationCategoryKey {
  care(isLocked: false),
  catFound(isLocked: true),
  lostCatNearby(isLocked: false),
  caregiverInvite(isLocked: false),
  directMessage(isLocked: false),
  postInteraction(isLocked: false),
  order(isLocked: false),
  teamAnnouncement(isLocked: false);

  const NotificationCategoryKey({required this.isLocked});
  final bool isLocked;
}

/// หัวข้อความยินยอม PDPA แยกเรื่องตาม PDPA-01
enum PdpaConsentKey {
  location,
  marketing,
  aiTraining,
}

/// รายการความยินยอม PDPA พร้อมเวอร์ชันและวันที่อัปเดตล่าสุด
class PdpaConsentItem extends Equatable {
  const PdpaConsentItem({
    required this.key,
    required this.granted,
    required this.version,
    required this.updatedAtLabel,
  });

  final PdpaConsentKey key;
  final bool granted;
  final String version;
  final String updatedAtLabel;

  PdpaConsentItem copyWith({
    bool? granted,
    String? version,
    String? updatedAtLabel,
  }) {
    return PdpaConsentItem(
      key: key,
      granted: granted ?? this.granted,
      version: version ?? this.version,
      updatedAtLabel: updatedAtLabel ?? this.updatedAtLabel,
    );
  }

  @override
  List<Object?> get props => [key, granted, version, updatedAtLabel];
}

/// คำถามที่พบบ่อยในศูนย์ช่วยเหลือ (SET-01)
class SettingsFaqItem extends Equatable {
  const SettingsFaqItem({
    required this.id,
    required this.questionTh,
    required this.questionEn,
    required this.answerTh,
    required this.answerEn,
  });

  final String id;
  final String questionTh;
  final String questionEn;
  final String answerTh;
  final String answerEn;

  @override
  List<Object?> get props => [id, questionTh, questionEn, answerTh, answerEn];
}

/// ข้อมูลทั้งหมดของหน้าตั้งค่าและศูนย์ช่วยเหลือ (/settings)
class SettingsData extends Equatable {
  const SettingsData({
    required this.accountName,
    required this.accountHandle,
    this.accountAvatarSource = '',
    required this.accountVerified,
    required this.pushEnabled,
    required this.quietHoursEnabled,
    required this.quietStart,
    required this.quietEnd,
    required this.notificationCategories,
    required this.pdpaConsents,
    required this.dataExportRequested,
    required this.faqs,
    required this.appVersion,
  });

  final String accountName;
  final String accountHandle;
  final String accountAvatarSource;
  final bool accountVerified;
  final bool pushEnabled;
  final bool quietHoursEnabled;
  final String quietStart;
  final String quietEnd;
  final Map<NotificationCategoryKey, bool> notificationCategories;
  final List<PdpaConsentItem> pdpaConsents;
  final bool dataExportRequested;
  final List<SettingsFaqItem> faqs;
  final String appVersion;

  SettingsData copyWith({
    String? accountName,
    String? accountHandle,
    String? accountAvatarSource,
    bool? accountVerified,
    bool? pushEnabled,
    bool? quietHoursEnabled,
    String? quietStart,
    String? quietEnd,
    Map<NotificationCategoryKey, bool>? notificationCategories,
    List<PdpaConsentItem>? pdpaConsents,
    bool? dataExportRequested,
    List<SettingsFaqItem>? faqs,
    String? appVersion,
  }) {
    return SettingsData(
      accountName: accountName ?? this.accountName,
      accountHandle: accountHandle ?? this.accountHandle,
      accountAvatarSource: accountAvatarSource ?? this.accountAvatarSource,
      accountVerified: accountVerified ?? this.accountVerified,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietStart: quietStart ?? this.quietStart,
      quietEnd: quietEnd ?? this.quietEnd,
      notificationCategories:
          notificationCategories ?? this.notificationCategories,
      pdpaConsents: pdpaConsents ?? this.pdpaConsents,
      dataExportRequested: dataExportRequested ?? this.dataExportRequested,
      faqs: faqs ?? this.faqs,
      appVersion: appVersion ?? this.appVersion,
    );
  }

  @override
  List<Object?> get props => [
        accountName,
        accountHandle,
        accountAvatarSource,
        accountVerified,
        pushEnabled,
        quietHoursEnabled,
        quietStart,
        quietEnd,
        notificationCategories,
        pdpaConsents,
        dataExportRequested,
        faqs,
        appVersion,
      ];
}

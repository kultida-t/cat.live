import 'package:equatable/equatable.dart';

/// รายการ Feature Flag ควบคุมฟีเจอร์ Phase 1 / Phase 2 ตามมติ DEC-01..11 และ OPS-04
enum AppFeatureFlag {
  /// GIFT-01..06 / DEC-06: ระบบส่งขนมแมว (Phase 2)
  treatsGifting,

  /// TRK-01 / DEC-10: ระบบ GPS Tracker ตามหาแมว (Phase 2)
  catTracker,

  /// AI-15 / DEC-10: โทรคุยกับสัตวแพทย์ AI ด้วยเสียง (Phase 2)
  aiVoiceCall,

  /// AI-16 / DEC-10: ตรวจใบหน้า/สีหน้าแมว (Phase 2)
  aiFaceCheck,

  /// F-NB-04 / DEC-04: หมวด Nearby อื่นนอกจากคลินิก/รพ.สัตว์ (Phase 2)
  nearbyExtraCategories,

  /// F-HELP-03: ระบบรับเลี้ยง / อุปการะแมว (Phase 2)
  adoptionAndSponsorship,

  /// DEC-11 / DON-01..05: ปุ่มรับเงินบริจาคจริง (ปิดจนกว่า Legal ผ่าน)
  donationsCheckout,

  /// F-CAT-07 / F-CAT-10: Memories และสถานะแมวจากไปแล้ว (Phase 2)
  catMemoriesAndMemorial,

  /// DEC-09 / TAG-02 / STORE-01: บน iOS พาไปสั่งซื้อ Tag บนเว็บภายนอก (Phase 1 = เปิด)
  tagIosExternalWebOrder,

  /// DEC-01 / F-HLT-03: ผล OCR และ Cat AI ต้องเป็น Draft ให้ผู้ใช้ยืนยันก่อนเข้า Timeline (Phase 1 = เปิด)
  aiDraftConfirmation,
}

/// ข้อมูลคำอธิบายของแต่ละ Flag (สำหรับแสดงในหน้าตั้งค่า/QA และบันทึก Decision Log)
class FeatureFlagMetadata {
  const FeatureFlagMetadata({
    required this.flag,
    required this.key,
    required this.decisionRef,
    required this.isPhase2Feature,
    required this.titleTh,
    required this.titleEn,
    required this.descriptionTh,
    required this.descriptionEn,
    required this.defaultEnabled,
  });

  final AppFeatureFlag flag;
  final String key;
  final String decisionRef;
  final bool isPhase2Feature;
  final String titleTh;
  final String titleEn;
  final String descriptionTh;
  final String descriptionEn;
  final bool defaultEnabled;

  String title(bool isEn) => isEn ? titleEn : titleTh;
  String description(bool isEn) => isEn ? descriptionEn : descriptionTh;

  static const List<FeatureFlagMetadata> catalog = [
    FeatureFlagMetadata(
      flag: AppFeatureFlag.treatsGifting,
      key: 'treats_gifting',
      decisionRef: 'DEC-06 / GIFT-01..06',
      isPhase2Feature: true,
      titleTh: 'ระบบเลี้ยงขนมแมว',
      titleEn: 'Treats Gifting System',
      descriptionTh:
          'เปิดใช้งานหน้าส่งขนม (/treats) และปุ่มส่งขนมตามฟีด/โปรไฟล์ (Phase 2)',
      descriptionEn:
          'Enable treats checkout (/treats) and gifting buttons across feed/profiles (Phase 2).',
      defaultEnabled: false,
    ),
    FeatureFlagMetadata(
      flag: AppFeatureFlag.catTracker,
      key: 'cat_tracker',
      decisionRef: 'DEC-10 / TRK-01',
      isPhase2Feature: true,
      titleTh: 'ตามหาแมว GPS Tracker',
      titleEn: 'Cat GPS Tracker',
      descriptionTh:
          'เปิดใช้งานหน้าติดตามตำแหน่งและเขตปลอดภัยของปลอกคอ (/my-cat/tracker)',
      descriptionEn:
          'Enable live collar GPS tracker and safe-zone monitoring (/my-cat/tracker).',
      defaultEnabled: false,
    ),
    FeatureFlagMetadata(
      flag: AppFeatureFlag.aiVoiceCall,
      key: 'ai_voice_call',
      decisionRef: 'DEC-10 / AI-15',
      isPhase2Feature: true,
      titleTh: 'โทรคุยกับสัตวแพทย์ AI',
      titleEn: 'Cat AI Voice Call',
      descriptionTh:
          'เปิดใช้งานปุ่มคุยด้วยเสียงแบบเรียลไทม์ในหน้า Cat AI (Phase 2)',
      descriptionEn:
          'Enable real-time voice call mode inside Cat AI (Phase 2).',
      defaultEnabled: false,
    ),
    FeatureFlagMetadata(
      flag: AppFeatureFlag.aiFaceCheck,
      key: 'ai_face_check',
      decisionRef: 'DEC-10 / AI-16',
      isPhase2Feature: true,
      titleTh: 'ตรวจสีหน้า/ใบหน้าแมว AI',
      titleEn: 'AI Cat Face Check',
      descriptionTh:
          'เปิดใช้งานเครื่องมือสแกนสีหน้าแมว 5 จุด (/cat-ai/face-check)',
      descriptionEn:
          'Enable 5-point facial pain scan tool (/cat-ai/face-check).',
      defaultEnabled: false,
    ),
    FeatureFlagMetadata(
      flag: AppFeatureFlag.nearbyExtraCategories,
      key: 'nearby_extra_categories',
      decisionRef: 'DEC-04 / F-NB-04',
      isPhase2Feature: true,
      titleTh: 'หมวด Nearby เพิ่มเติม (คาเฟ่/อาบน้ำ/ฝากเลี้ยง)',
      titleEn: 'Extra Nearby Categories',
      descriptionTh:
          'แสดงหมวดสถานที่อื่นนอกจากคลินิก/โรงพยาบาลสัตว์ในหน้าใกล้ฉัน (Phase 2)',
      descriptionEn:
          'Show cafe, grooming, and boarding categories in Nearby beyond clinics (Phase 2).',
      defaultEnabled: false,
    ),
    FeatureFlagMetadata(
      flag: AppFeatureFlag.adoptionAndSponsorship,
      key: 'adoption_sponsorship',
      decisionRef: 'F-HELP-03',
      isPhase2Feature: true,
      titleTh: 'รับเลี้ยงและอุปการะแมว',
      titleEn: 'Cat Adoption & Sponsorship',
      descriptionTh: 'เปิดหมวดและปุ่มสนใจรับเลี้ยง/อุปการะในหน้าช่วยเหลือ',
      descriptionEn:
          'Enable adoption and sponsorship actions inside Help center.',
      defaultEnabled: false,
    ),
    FeatureFlagMetadata(
      flag: AppFeatureFlag.donationsCheckout,
      key: 'donations_checkout',
      decisionRef: 'DEC-11 / DON-00',
      isPhase2Feature: true,
      titleTh: 'เปิดรับเงินบริจาคในแอป',
      titleEn: 'In-App Donations Checkout',
      descriptionTh:
          'ปิดปุ่มรับเงินบริจาคใน Phase 1 จนกว่าฝ่ายกฎหมายตรวจข้อกำหนดเรี่ยไรเสร็จ',
      descriptionEn:
          'Keep donation payment buttons disabled in Phase 1 pending legal clearance.',
      defaultEnabled: false,
    ),
    FeatureFlagMetadata(
      flag: AppFeatureFlag.catMemoriesAndMemorial,
      key: 'cat_memories_memorial',
      decisionRef: 'F-CAT-07 / F-CAT-10',
      isPhase2Feature: true,
      titleTh: 'ความทรงจำและบริการรำลึก',
      titleEn: 'Memories & Memorial Services',
      descriptionTh:
          'เปิดใช้บริการรำลึก, ฌาปนกิจ และเว็บไซต์รำลึกในเมนูบริการเสริม',
      descriptionEn:
          'Enable memorial, cremation, and tribute website items in service menu.',
      defaultEnabled: false,
    ),
    FeatureFlagMetadata(
      flag: AppFeatureFlag.tagIosExternalWebOrder,
      key: 'tag_ios_external_web_order',
      decisionRef: 'DEC-09 / STORE-01',
      isPhase2Feature: false,
      titleTh: 'iOS สั่งซื้อ Tag ผ่านเว็บภายนอก',
      titleEn: 'iOS External Web Tag Order',
      descriptionTh:
          'เปิดลิงก์สั่งซื้อแมว.live Tag บนเบราว์เซอร์ภายนอกแทนหน้าจ่ายเงินในแอป iOS',
      descriptionEn:
          'Redirect iOS Tag purchases to external browser checkout per App Store rules.',
      defaultEnabled: true,
    ),
    FeatureFlagMetadata(
      flag: AppFeatureFlag.aiDraftConfirmation,
      key: 'ai_draft_confirmation',
      decisionRef: 'DEC-01 / F-HLT-03',
      isPhase2Feature: false,
      titleTh: 'ผล AI / OCR เป็นร่างก่อนบันทึก',
      titleEn: 'AI / OCR Draft-First Rule',
      descriptionTh:
          'บังคับให้ข้อมูลสุขภาพจาก AI และ OCR แสดงเป็นร่างให้ผู้ใช้ตรวจแก้ก่อนลง Timeline',
      descriptionEn:
          'Require user confirmation on AI/OCR drafts before saving to Health Timeline.',
      defaultEnabled: true,
    ),
  ];

  static FeatureFlagMetadata of(AppFeatureFlag flag) =>
      catalog.firstWhere((item) => item.flag == flag);
}

/// สถานะชุด Feature Flags ปัจจุบัน (พร้อมรองรับข้อมูลแพลตฟอร์ม, เวอร์ชัน และ Force Update)
class FeatureFlagsSnapshot extends Equatable {
  const FeatureFlagsSnapshot({
    required this.flags,
    required this.platform,
    required this.appVersion,
    required this.minSupportedVersion,
    required this.updatedAt,
    this.overriddenFlags = const {},
  });

  final Map<AppFeatureFlag, bool> flags;
  final String platform;
  final String appVersion;
  final String minSupportedVersion;
  final DateTime updatedAt;
  final Set<AppFeatureFlag> overriddenFlags;

  bool isEnabled(AppFeatureFlag flag) =>
      flags[flag] ?? FeatureFlagMetadata.of(flag).defaultEnabled;

  FeatureFlagsSnapshot copyWith({
    Map<AppFeatureFlag, bool>? flags,
    String? platform,
    String? appVersion,
    String? minSupportedVersion,
    DateTime? updatedAt,
    Set<AppFeatureFlag>? overriddenFlags,
  }) {
    return FeatureFlagsSnapshot(
      flags: flags ?? this.flags,
      platform: platform ?? this.platform,
      appVersion: appVersion ?? this.appVersion,
      minSupportedVersion: minSupportedVersion ?? this.minSupportedVersion,
      updatedAt: updatedAt ?? this.updatedAt,
      overriddenFlags: overriddenFlags ?? this.overriddenFlags,
    );
  }

  @override
  List<Object?> get props => [
    flags,
    platform,
    appVersion,
    minSupportedVersion,
    updatedAt,
    overriddenFlags,
  ];
}

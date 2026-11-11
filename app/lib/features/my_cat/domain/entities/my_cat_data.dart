import 'package:equatable/equatable.dart';

/// เพศของแมวบนโปรไฟล์
enum CatGender {
  female('เพศเมีย'),
  male('เพศผู้');

  const CatGender(this.label);
  final String label;
}

/// สถานะสุขภาพบนบัตร Cat ID
enum CatHealthBadge {
  good('ดี'),
  watch('เฝ้าระวัง'),
  poor('ไม่ดี');

  const CatHealthBadge(this.label);
  final String label;
}

/// สถานะตำแหน่งของปลอกคอ/แท็กตามหาแมว
enum CatTrackerStatus {
  safe('อยู่ในเขตปลอดภัย'),
  outOfZone('ออกนอกเขตปลอดภัย'),
  noCollar('ยังไม่มีปลอกคอ');

  const CatTrackerStatus(this.defaultLabel);
  final String defaultLabel;
}

/// ระดับสิทธิ์เมื่อชวนผู้ดูแลเพิ่ม
enum CaregiverInviteRole {
  caregiver(
    'carer',
    'ผู้ดูแล',
    'ติ๊กงานดูแลรายวัน ดูและเพิ่มบันทึกสุขภาพ',
    'Caregiver',
    'Tick off daily care, view and add health notes',
  ),
  helper(
    'helper',
    'ผู้ช่วยชั่วคราว',
    'ดูแลแทนช่วงไม่อยู่บ้าน เห็นเฉพาะงานวันนี้และยา',
    'Temporary helper',
    "Cat-sitting while you're away; sees only today's tasks and meds",
  ),
  viewer(
    'viewer',
    'ดูอย่างเดียว',
    'ดูโปรไฟล์และสุขภาพ แก้ไขอะไรไม่ได้',
    'View only',
    "Can view profile and health, can't edit",
  );

  const CaregiverInviteRole(
    this.slug,
    this.label,
    this.description,
    this.enLabel,
    this.enDescription,
  );
  final String slug;
  final String label;
  final String description;
  final String enLabel;
  final String enDescription;
}

/// ช่องทางรับเงินบริจาค
enum DonationMethod {
  promptPay('พร้อมเพย์'),
  bankAccount('บัญชีธนาคาร');

  const DonationMethod(this.label);
  final String label;
}

/// ระดับการมองเห็นโปรไฟล์เจ้าของ
enum ProfileVisibility {
  everyone('ทุกคน'),
  followersOnly('เฉพาะผู้ติดตาม');

  const ProfileVisibility(this.label);
  final String label;
}

/// รายการงานดูแลประจำวันในแท็บ "ดูแลวันนี้"
class CareTaskItem extends Equatable {
  const CareTaskItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.isDone,
  });

  final String id;
  final String title;
  final String subtitle;
  final bool isDone;

  CareTaskItem copyWith({
    String? id,
    String? title,
    String? subtitle,
    bool? isDone,
  }) {
    return CareTaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      isDone: isDone ?? this.isDone,
    );
  }

  @override
  List<Object?> get props => [id, title, subtitle, isDone];
}

/// รายการบันทึกสุขภาพย่อในแท็บ "สุขภาพ"
class CatHealthHighlight extends Equatable {
  const CatHealthHighlight({
    required this.id,
    required this.title,
    required this.dateLabel,
    this.isAlert = false,
  });

  final String id;
  final String title;
  final String dateLabel;
  final bool isAlert;

  @override
  List<Object?> get props => [id, title, dateLabel, isAlert];
}

/// ผู้ดูแลในบ้านของแมวตัวนั้น
class CatCaregiver extends Equatable {
  const CatCaregiver({
    required this.id,
    required this.name,
    required this.roleLabel,
    required this.avatarSource,
    required this.avatarBg,
  });

  final String id;
  final String name;
  final String roleLabel;
  final String avatarSource;
  final int avatarBg;

  CatCaregiver copyWith({
    String? id,
    String? name,
    String? roleLabel,
    String? avatarSource,
    int? avatarBg,
  }) {
    return CatCaregiver(
      id: id ?? this.id,
      name: name ?? this.name,
      roleLabel: roleLabel ?? this.roleLabel,
      avatarSource: avatarSource ?? this.avatarSource,
      avatarBg: avatarBg ?? this.avatarBg,
    );
  }

  @override
  List<Object?> get props => [id, name, roleLabel, avatarSource, avatarBg];
}

/// รูปภาพในอัลบั้มของแมวแต่ละตัว
class CatPhotoItem extends Equatable {
  const CatPhotoItem({
    required this.id,
    required this.imageSource,
    required this.caption,
    required this.relativeTime,
    this.likeCount = 0,
    this.commentCount = 0,
    this.repostCount = 0,
    this.shareCount = 0,
    this.isLiked = false,
    this.isReposted = false,
    this.isSaved = false,
  });

  final String id;
  final String imageSource;
  final String caption;
  final String relativeTime;
  final int likeCount;
  final int commentCount;
  final int repostCount;
  final int shareCount;
  final bool isLiked;
  final bool isReposted;
  final bool isSaved;

  CatPhotoItem copyWith({
    String? id,
    String? imageSource,
    String? caption,
    String? relativeTime,
    int? likeCount,
    int? commentCount,
    int? repostCount,
    int? shareCount,
    bool? isLiked,
    bool? isReposted,
    bool? isSaved,
  }) {
    return CatPhotoItem(
      id: id ?? this.id,
      imageSource: imageSource ?? this.imageSource,
      caption: caption ?? this.caption,
      relativeTime: relativeTime ?? this.relativeTime,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      repostCount: repostCount ?? this.repostCount,
      shareCount: shareCount ?? this.shareCount,
      isLiked: isLiked ?? this.isLiked,
      isReposted: isReposted ?? this.isReposted,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  @override
  List<Object?> get props => [
    id,
    imageSource,
    caption,
    relativeTime,
    likeCount,
    commentCount,
    repostCount,
    shareCount,
    isLiked,
    isReposted,
    isSaved,
  ];
}

/// ความคิดเห็นใต้รูปภาพของแมวในมุมมองรูปเต็มจอ
class CatPhotoComment extends Equatable {
  const CatPhotoComment({
    required this.id,
    required this.author,
    required this.body,
    required this.time,
    required this.avatar,
    required this.avatarBg,
    required this.likes,
    this.replyToHandle,
    this.liked = false,
  });

  final String id;
  final String author;
  final String body;
  final String time;
  final String avatar;
  final int avatarBg;
  final int likes;
  final String? replyToHandle;
  final bool liked;

  CatPhotoComment copyWith({int? likes, bool? liked}) => CatPhotoComment(
    id: id,
    author: author,
    body: body,
    time: time,
    avatar: avatar,
    avatarBg: avatarBg,
    likes: likes ?? this.likes,
    replyToHandle: replyToHandle,
    liked: liked ?? this.liked,
  );

  @override
  List<Object?> get props => [
    id,
    author,
    body,
    time,
    avatar,
    avatarBg,
    likes,
    replyToHandle,
    liked,
  ];
}

/// สีบัตรประจำตัวแมว (Cat ID Card) 7 ธีม ตรงตามเว็บ www.แมว.live
enum CatIdSkin {
  honey('น้ำผึ้ง', 'Honey'),
  peach('พีช', 'Peach'),
  mint('มิ้นต์', 'Mint'),
  sky('ฟ้า', 'Sky'),
  lavender('ลาเวนเดอร์', 'Lavender'),
  pink('ชมพู', 'Pink'),
  night('กลางคืน', 'Night');

  const CatIdSkin(this.thLabel, this.enLabel);
  final String thLabel;
  final String enLabel;
}

/// ความถี่ในการอัปเดตตำแหน่งของแท็ก
enum TrackerUpdateFrequency {
  batterySaver(
    'ประหยัดแบต',
    'Battery saver',
    'ทุก 10 นาที · แบตอยู่ ~14 วัน',
    'Every 10 min · battery ~14 days',
  ),
  normal(
    'ปกติ',
    'Normal',
    'ทุก 2 นาที · แบตอยู่ ~7 วัน',
    'Every 2 min · battery ~7 days',
  ),
  realtime(
    'เรียลไทม์',
    'Real-time',
    'ทุก 10 วินาที · แบตอยู่ ~1 วัน',
    'Every 10 sec · battery ~1 day',
  );

  const TrackerUpdateFrequency(
    this.thLabel,
    this.enLabel,
    this.thSummary,
    this.enSummary,
  );
  final String thLabel;
  final String enLabel;
  final String thSummary;
  final String enSummary;
}

/// ระดับเสียงปลอกคอแท็ก
enum TrackerCollarVolume {
  quiet('เบา', 'Quiet'),
  medium('กลาง', 'Medium'),
  loud('ดัง', 'Loud');

  const TrackerCollarVolume(this.thLabel, this.enLabel);
  final String thLabel;
  final String enLabel;
}

/// จุดแวะในไทม์ไลน์เส้นทางวันนี้ของแมว
class TrackerRouteStop extends Equatable {
  const TrackerRouteStop({
    required this.placeTh,
    required this.placeEn,
    required this.timeTh,
    required this.timeEn,
  });

  final String placeTh;
  final String placeEn;
  final String timeTh;
  final String timeEn;

  @override
  List<Object?> get props => [placeTh, placeEn, timeTh, timeEn];
}

/// ข้อมูลฮาร์ดแวร์และการตั้งค่าของอุปกรณ์ แมว.live Tag
class CatTrackerDevice extends Equatable {
  const CatTrackerDevice({
    required this.tagNumber,
    required this.collarColorHex,
    required this.signalGood,
    required this.lastSyncedTh,
    required this.lastSyncedEn,
    this.frequency = TrackerUpdateFrequency.normal,
    this.volume = TrackerCollarVolume.medium,
    this.nightLed = true,
    this.saveBatteryAtHome = true,
    this.lowBatteryAlert = true,
    required this.firmwareVersion,
    required this.latestFirmwareVersion,
    required this.serialCode,
  });

  final int tagNumber;
  final int collarColorHex;
  final bool signalGood;
  final String lastSyncedTh;
  final String lastSyncedEn;
  final TrackerUpdateFrequency frequency;
  final TrackerCollarVolume volume;
  final bool nightLed;
  final bool saveBatteryAtHome;
  final bool lowBatteryAlert;
  final String firmwareVersion;
  final String latestFirmwareVersion;
  final String serialCode;

  bool get hasFirmwareUpdate => firmwareVersion != latestFirmwareVersion;

  CatTrackerDevice copyWith({
    int? tagNumber,
    int? collarColorHex,
    bool? signalGood,
    String? lastSyncedTh,
    String? lastSyncedEn,
    TrackerUpdateFrequency? frequency,
    TrackerCollarVolume? volume,
    bool? nightLed,
    bool? saveBatteryAtHome,
    bool? lowBatteryAlert,
    String? firmwareVersion,
    String? latestFirmwareVersion,
    String? serialCode,
  }) {
    return CatTrackerDevice(
      tagNumber: tagNumber ?? this.tagNumber,
      collarColorHex: collarColorHex ?? this.collarColorHex,
      signalGood: signalGood ?? this.signalGood,
      lastSyncedTh: lastSyncedTh ?? this.lastSyncedTh,
      lastSyncedEn: lastSyncedEn ?? this.lastSyncedEn,
      frequency: frequency ?? this.frequency,
      volume: volume ?? this.volume,
      nightLed: nightLed ?? this.nightLed,
      saveBatteryAtHome: saveBatteryAtHome ?? this.saveBatteryAtHome,
      lowBatteryAlert: lowBatteryAlert ?? this.lowBatteryAlert,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      latestFirmwareVersion:
          latestFirmwareVersion ?? this.latestFirmwareVersion,
      serialCode: serialCode ?? this.serialCode,
    );
  }

  @override
  List<Object?> get props => [
    tagNumber,
    collarColorHex,
    signalGood,
    lastSyncedTh,
    lastSyncedEn,
    frequency,
    volume,
    nightLed,
    saveBatteryAtHome,
    lowBatteryAlert,
    firmwareVersion,
    latestFirmwareVersion,
    serialCode,
  ];
}

/// ข้อมูลการติดตามและเขตปลอดภัยของแมวหนึ่งตัว (/my-cat/tracker)
class CatTrackerInfo extends Equatable {
  const CatTrackerInfo({
    this.hasTag = false,
    this.latitude = 13.7796,
    this.longitude = 100.5447,
    this.locationTh = '',
    this.locationEn = '',
    this.listSummaryTh = '',
    this.listSummaryEn = '',
    this.distanceMeters = 0,
    this.lastUpdatedTh = '',
    this.lastUpdatedEn = '',
    this.detailTimeTh = '',
    this.detailTimeEn = '',
    this.batteryPercent = 0,
    this.safeZoneRadiusMeters = 100,
    this.alertOnLeaveZone = true,
    this.lostMode = false,
    this.showContactNumber = true,
    this.contactPhone = '081-234-5678',
    this.shareWithCommunity = false,
    this.routeStops = const [],
    this.device,
  });

  final bool hasTag;
  final double latitude;
  final double longitude;
  final String locationTh;
  final String locationEn;
  final String listSummaryTh;
  final String listSummaryEn;
  final int distanceMeters;
  final String lastUpdatedTh;
  final String lastUpdatedEn;
  final String detailTimeTh;
  final String detailTimeEn;
  final int batteryPercent;
  final int safeZoneRadiusMeters;
  final bool alertOnLeaveZone;
  final bool lostMode;
  final bool showContactNumber;
  final String contactPhone;
  final bool shareWithCommunity;
  final List<TrackerRouteStop> routeStops;
  final CatTrackerDevice? device;

  CatTrackerInfo copyWith({
    bool? hasTag,
    double? latitude,
    double? longitude,
    String? locationTh,
    String? locationEn,
    String? listSummaryTh,
    String? listSummaryEn,
    int? distanceMeters,
    String? lastUpdatedTh,
    String? lastUpdatedEn,
    String? detailTimeTh,
    String? detailTimeEn,
    int? batteryPercent,
    int? safeZoneRadiusMeters,
    bool? alertOnLeaveZone,
    bool? lostMode,
    bool? showContactNumber,
    String? contactPhone,
    bool? shareWithCommunity,
    List<TrackerRouteStop>? routeStops,
    CatTrackerDevice? device,
  }) {
    return CatTrackerInfo(
      hasTag: hasTag ?? this.hasTag,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationTh: locationTh ?? this.locationTh,
      locationEn: locationEn ?? this.locationEn,
      listSummaryTh: listSummaryTh ?? this.listSummaryTh,
      listSummaryEn: listSummaryEn ?? this.listSummaryEn,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      lastUpdatedTh: lastUpdatedTh ?? this.lastUpdatedTh,
      lastUpdatedEn: lastUpdatedEn ?? this.lastUpdatedEn,
      detailTimeTh: detailTimeTh ?? this.detailTimeTh,
      detailTimeEn: detailTimeEn ?? this.detailTimeEn,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      safeZoneRadiusMeters: safeZoneRadiusMeters ?? this.safeZoneRadiusMeters,
      alertOnLeaveZone: alertOnLeaveZone ?? this.alertOnLeaveZone,
      lostMode: lostMode ?? this.lostMode,
      showContactNumber: showContactNumber ?? this.showContactNumber,
      contactPhone: contactPhone ?? this.contactPhone,
      shareWithCommunity: shareWithCommunity ?? this.shareWithCommunity,
      routeStops: routeStops ?? this.routeStops,
      device: device ?? this.device,
    );
  }

  @override
  List<Object?> get props => [
    hasTag,
    latitude,
    longitude,
    locationTh,
    locationEn,
    listSummaryTh,
    listSummaryEn,
    distanceMeters,
    lastUpdatedTh,
    lastUpdatedEn,
    detailTimeTh,
    detailTimeEn,
    batteryPercent,
    safeZoneRadiusMeters,
    alertOnLeaveZone,
    lostMode,
    showContactNumber,
    contactPhone,
    shareWithCommunity,
    routeStops,
    device,
  ];
}

/// รายละเอียดเพิ่มเติมสำหรับบัตร Cat ID (/my-cat/profile)
class CatIdCardDetails extends Equatable {
  const CatIdCardDetails({
    this.coatColor = 'ไม่ระบุ',
    this.birthDateLabel = '',
    this.lastVaccineDate = 'ยังไม่มีบันทึก',
    this.lastVaccineName = '',
    this.nextDueDate = 'ยังไม่มีนัด',
    this.nextDueDetail = '',
    this.bloodType = 'ยังไม่ได้ตรวจ',
    this.allergy = 'ไม่มี',
    this.chronicConditions = 'ไม่มี',
    this.watchNote = '',
    this.issuedDateLabel = 'วันนี้',
    this.defaultSkin = CatIdSkin.honey,
  });

  final String coatColor;
  final String birthDateLabel;
  final String lastVaccineDate;
  final String lastVaccineName;
  final String nextDueDate;
  final String nextDueDetail;
  final String bloodType;
  final String allergy;
  final String chronicConditions;
  final String watchNote;
  final String issuedDateLabel;
  final CatIdSkin defaultSkin;

  @override
  List<Object?> get props => [
    coatColor,
    birthDateLabel,
    lastVaccineDate,
    lastVaccineName,
    nextDueDate,
    nextDueDetail,
    bloodType,
    allergy,
    chronicConditions,
    watchNote,
    issuedDateLabel,
    defaultSkin,
  ];
}

/// ข้อมูลโปรไฟล์แมวหนึ่งตัว
class CatProfile extends Equatable {
  const CatProfile({
    required this.id,
    required this.publicId,
    required this.name,
    required this.breed,
    required this.gender,
    required this.neutered,
    required this.ageLabel,
    required this.weightKg,
    required this.recordCount,
    required this.adoptedYear,
    required this.avatarSource,
    required this.avatarBg,
    required this.healthBadge,
    required this.trackerStatus,
    required this.trackerLabel,
    required this.photos,
    required this.careTasks,
    required this.healthReminderTitle,
    required this.healthReminderSubtitle,
    required this.healthHighlights,
    required this.caregivers,
    this.idCard = const CatIdCardDetails(),
    this.trackerInfo = const CatTrackerInfo(),
  });

  final String id;
  final String publicId;
  final String name;
  final String breed;
  final CatGender gender;
  final bool neutered;
  final String ageLabel;
  final double weightKg;
  final int recordCount;
  final int adoptedYear;
  final String avatarSource;
  final int avatarBg;
  final CatHealthBadge healthBadge;
  final CatTrackerStatus trackerStatus;
  final String trackerLabel;
  final List<CatPhotoItem> photos;
  final List<CareTaskItem> careTasks;
  final String healthReminderTitle;
  final String healthReminderSubtitle;
  final List<CatHealthHighlight> healthHighlights;
  final List<CatCaregiver> caregivers;
  final CatIdCardDetails idCard;
  final CatTrackerInfo trackerInfo;

  String get summarySubtitle =>
      '$breed · ${gender.label} · ${neutered ? 'ทำหมันแล้ว' : 'ยังไม่ทำหมัน'}';

  String get weightText => weightKg == weightKg.truncateToDouble()
      ? weightKg.toStringAsFixed(0)
      : weightKg.toStringAsFixed(1);

  int get completedCareCount => careTasks.where((t) => t.isDone).length;

  CatProfile copyWith({
    String? id,
    String? publicId,
    String? name,
    String? breed,
    CatGender? gender,
    bool? neutered,
    String? ageLabel,
    double? weightKg,
    int? recordCount,
    int? adoptedYear,
    String? avatarSource,
    int? avatarBg,
    CatHealthBadge? healthBadge,
    CatTrackerStatus? trackerStatus,
    String? trackerLabel,
    List<CatPhotoItem>? photos,
    List<CareTaskItem>? careTasks,
    String? healthReminderTitle,
    String? healthReminderSubtitle,
    List<CatHealthHighlight>? healthHighlights,
    List<CatCaregiver>? caregivers,
    CatIdCardDetails? idCard,
    CatTrackerInfo? trackerInfo,
  }) {
    return CatProfile(
      id: id ?? this.id,
      publicId: publicId ?? this.publicId,
      name: name ?? this.name,
      breed: breed ?? this.breed,
      gender: gender ?? this.gender,
      neutered: neutered ?? this.neutered,
      ageLabel: ageLabel ?? this.ageLabel,
      weightKg: weightKg ?? this.weightKg,
      recordCount: recordCount ?? this.recordCount,
      adoptedYear: adoptedYear ?? this.adoptedYear,
      avatarSource: avatarSource ?? this.avatarSource,
      avatarBg: avatarBg ?? this.avatarBg,
      healthBadge: healthBadge ?? this.healthBadge,
      trackerStatus: trackerStatus ?? this.trackerStatus,
      trackerLabel: trackerLabel ?? this.trackerLabel,
      photos: photos ?? this.photos,
      careTasks: careTasks ?? this.careTasks,
      healthReminderTitle: healthReminderTitle ?? this.healthReminderTitle,
      healthReminderSubtitle:
          healthReminderSubtitle ?? this.healthReminderSubtitle,
      healthHighlights: healthHighlights ?? this.healthHighlights,
      caregivers: caregivers ?? this.caregivers,
      idCard: idCard ?? this.idCard,
      trackerInfo: trackerInfo ?? this.trackerInfo,
    );
  }

  @override
  List<Object?> get props => [
    id,
    publicId,
    name,
    breed,
    gender,
    neutered,
    ageLabel,
    weightKg,
    recordCount,
    adoptedYear,
    avatarSource,
    avatarBg,
    healthBadge,
    trackerStatus,
    trackerLabel,
    photos,
    careTasks,
    healthReminderTitle,
    healthReminderSubtitle,
    healthHighlights,
    caregivers,
    idCard,
    trackerInfo,
  ];
}

/// ข้อมูลบัญชีรับเงินบริจาคของเจ้าของ (แสดงแบบซ่อนเลขในหน้าสาธารณะ)
class OwnerDonationAccount extends Equatable {
  const OwnerDonationAccount({
    required this.method,
    required this.accountNumber,
    required this.accountName,
  });

  final DonationMethod method;
  final String accountNumber;
  final String accountName;

  String get maskedLabel {
    final digits = accountNumber.replaceAll(RegExp(r'\D'), '');
    final tail = digits.length >= 4
        ? digits.substring(digits.length - 4)
        : digits;
    return '${method.label} ••••$tail';
  }

  OwnerDonationAccount copyWith({
    DonationMethod? method,
    String? accountNumber,
    String? accountName,
  }) {
    return OwnerDonationAccount(
      method: method ?? this.method,
      accountNumber: accountNumber ?? this.accountNumber,
      accountName: accountName ?? this.accountName,
    );
  }

  @override
  List<Object?> get props => [method, accountNumber, accountName];
}

/// การตั้งค่าความเป็นส่วนตัวของเจ้าของ
class OwnerPrivacySettings extends Equatable {
  const OwnerPrivacySettings({
    required this.visibility,
    required this.showMyCats,
    required this.showDistrict,
    required this.allowMessages,
  });

  final ProfileVisibility visibility;
  final bool showMyCats;
  final bool showDistrict;
  final bool allowMessages;

  OwnerPrivacySettings copyWith({
    ProfileVisibility? visibility,
    bool? showMyCats,
    bool? showDistrict,
    bool? allowMessages,
  }) {
    return OwnerPrivacySettings(
      visibility: visibility ?? this.visibility,
      showMyCats: showMyCats ?? this.showMyCats,
      showDistrict: showDistrict ?? this.showDistrict,
      allowMessages: allowMessages ?? this.allowMessages,
    );
  }

  @override
  List<Object?> get props => [
    visibility,
    showMyCats,
    showDistrict,
    allowMessages,
  ];
}

/// การตั้งค่าการแจ้งเตือนและโหมดเงียบ
class OwnerNotificationSettings extends Equatable {
  const OwnerNotificationSettings({
    required this.pushEnabled,
    required this.quietHoursEnabled,
    required this.nearbyAlerts,
    required this.careReminders,
    required this.locale,
  });

  final bool pushEnabled;
  final bool quietHoursEnabled;
  final bool nearbyAlerts;
  final bool careReminders;
  final String locale;

  OwnerNotificationSettings copyWith({
    bool? pushEnabled,
    bool? quietHoursEnabled,
    bool? nearbyAlerts,
    bool? careReminders,
    String? locale,
  }) {
    return OwnerNotificationSettings(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      nearbyAlerts: nearbyAlerts ?? this.nearbyAlerts,
      careReminders: careReminders ?? this.careReminders,
      locale: locale ?? this.locale,
    );
  }

  @override
  List<Object?> get props => [
    pushEnabled,
    quietHoursEnabled,
    nearbyAlerts,
    careReminders,
    locale,
  ];
}

/// ข้อมูลโปรไฟล์เจ้าของบัญชี (รวมส่วนส่วนตัวที่เจ้าของเห็นคนเดียว)
class OwnerProfile extends Equatable {
  const OwnerProfile({
    required this.id,
    required this.handle,
    required this.displayName,
    required this.bio,
    required this.district,
    required this.memberSince,
    required this.avatarSource,
    required this.avatarBg,
    required this.followerCount,
    required this.helpedCount,
    required this.unreadMessagesCount,
    required this.isPhoneVerified,
    required this.isIdVerified,
    required this.donationAccount,
    required this.treatAddress,
    required this.privacy,
    required this.notifications,
  });

  final String id;
  final String handle;
  final String displayName;
  final String bio;
  final String district;
  final String memberSince;
  final String avatarSource;
  final int avatarBg;
  final int followerCount;
  final int helpedCount;
  final int unreadMessagesCount;
  final bool isPhoneVerified;
  final bool isIdVerified;
  final OwnerDonationAccount donationAccount;
  final String treatAddress;
  final OwnerPrivacySettings privacy;
  final OwnerNotificationSettings notifications;

  int get completedVerificationSteps {
    var count = 0;
    if (isPhoneVerified) count++;
    if (isIdVerified) count++;
    if (donationAccount.accountNumber.trim().isNotEmpty) count++;
    return count;
  }

  OwnerProfile copyWith({
    String? id,
    String? handle,
    String? displayName,
    String? bio,
    String? district,
    String? memberSince,
    String? avatarSource,
    int? avatarBg,
    int? followerCount,
    int? helpedCount,
    int? unreadMessagesCount,
    bool? isPhoneVerified,
    bool? isIdVerified,
    OwnerDonationAccount? donationAccount,
    String? treatAddress,
    OwnerPrivacySettings? privacy,
    OwnerNotificationSettings? notifications,
  }) {
    return OwnerProfile(
      id: id ?? this.id,
      handle: handle ?? this.handle,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      district: district ?? this.district,
      memberSince: memberSince ?? this.memberSince,
      avatarSource: avatarSource ?? this.avatarSource,
      avatarBg: avatarBg ?? this.avatarBg,
      followerCount: followerCount ?? this.followerCount,
      helpedCount: helpedCount ?? this.helpedCount,
      unreadMessagesCount: unreadMessagesCount ?? this.unreadMessagesCount,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      isIdVerified: isIdVerified ?? this.isIdVerified,
      donationAccount: donationAccount ?? this.donationAccount,
      treatAddress: treatAddress ?? this.treatAddress,
      privacy: privacy ?? this.privacy,
      notifications: notifications ?? this.notifications,
    );
  }

  @override
  List<Object?> get props => [
    id,
    handle,
    displayName,
    bio,
    district,
    memberSince,
    avatarSource,
    avatarBg,
    followerCount,
    helpedCount,
    unreadMessagesCount,
    isPhoneVerified,
    isIdVerified,
    donationAccount,
    treatAddress,
    privacy,
    notifications,
  ];
}

/// ชุดข้อมูลหน้าแมวและฉัน (เจ้าของ + แมวทุกตัว)
class MyCatBundle extends Equatable {
  const MyCatBundle({required this.owner, required this.cats});

  final OwnerProfile owner;
  final List<CatProfile> cats;

  MyCatBundle copyWith({OwnerProfile? owner, List<CatProfile>? cats}) {
    return MyCatBundle(owner: owner ?? this.owner, cats: cats ?? this.cats);
  }

  @override
  List<Object?> get props => [owner, cats];
}

import 'package:equatable/equatable.dart';

/// แท็บมุมมองหลักในหน้าช่วยเหลือ (/help)
enum HelpMainTab { nearby, myPosts }

/// หมวดหมู่ประกาศช่วยเหลือ
enum HelpCategory { lost, found, helpRequest, adoption, foster }

/// สถานะของประกาศ
enum HelpPostStatus { active, resolved, closed }

/// ข้อมูลการระดมทุน/บริจาคในการ์ดประกาศ
class DonationInfo extends Equatable {
  const DonationInfo({
    required this.raisedBaht,
    required this.targetBaht,
    required this.purposeTh,
    required this.purposeEn,
    this.donorAvatars = const [],
    this.donorCount = 0,
    this.supportersTextTh,
    this.supportersTextEn,
    this.isClosed = false,
  });

  final int raisedBaht;
  final int targetBaht;
  final String purposeTh;
  final String purposeEn;
  final List<String> donorAvatars;
  final int donorCount;
  final String? supportersTextTh;
  final String? supportersTextEn;
  final bool isClosed;

  int get remainingBaht => (targetBaht - raisedBaht).clamp(0, targetBaht);

  double get progress =>
      targetBaht <= 0 ? 0 : (raisedBaht / targetBaht).clamp(0.0, 1.0);

  int get percent => (progress * 100).round();

  String purpose(bool isEn) => isEn ? purposeEn : purposeTh;
  String? supportersText(bool isEn) =>
      isEn ? supportersTextEn : supportersTextTh;

  DonationInfo copyWith({bool? isClosed}) {
    return DonationInfo(
      raisedBaht: raisedBaht,
      targetBaht: targetBaht,
      purposeTh: purposeTh,
      purposeEn: purposeEn,
      donorAvatars: donorAvatars,
      donorCount: donorCount,
      supportersTextTh: supportersTextTh,
      supportersTextEn: supportersTextEn,
      isClosed: isClosed ?? this.isClosed,
    );
  }

  @override
  List<Object?> get props => [
        raisedBaht,
        targetBaht,
        purposeTh,
        purposeEn,
        donorAvatars,
        donorCount,
        supportersTextTh,
        supportersTextEn,
        isClosed,
      ];
}

/// ประกาศช่วยเหลือแมวแต่ละรายการ
class HelpPost extends Equatable {
  const HelpPost({
    required this.id,
    required this.titleTh,
    required this.titleEn,
    required this.category,
    required this.imageAsset,
    required this.locationTh,
    required this.locationEn,
    this.imageFilePath,
    required this.distanceKm,
    required this.timeAgoTh,
    required this.timeAgoEn,
    this.rewardTh,
    this.rewardEn,
    required this.summaryTh,
    required this.summaryEn,
    required this.detailTraitsTh,
    required this.detailTraitsEn,
    this.secretMarkTh,
    this.secretMarkEn,
    required this.contactInfoTh,
    required this.contactInfoEn,
    this.donation,
    this.status = HelpPostStatus.active,
    this.isMine = false,
    this.clueSent = false,
    this.allowsChatClues = true,
    this.isUrgent = false,
    this.shortNameTh,
    this.shortNameEn,
    this.postedBy = 'mint.ari',
    this.ownerNameTh = 'คุณมิ้นท์',
    this.ownerNameEn = 'Mint',
  });

  final String id;
  final String titleTh;
  final String titleEn;
  final HelpCategory category;
  final String imageAsset;
  final String? imageFilePath;
  final String locationTh;
  final String locationEn;
  final double distanceKm;
  final String timeAgoTh;
  final String timeAgoEn;
  final String? rewardTh;
  final String? rewardEn;
  final String summaryTh;
  final String summaryEn;
  final String detailTraitsTh;
  final String detailTraitsEn;
  final String? secretMarkTh;
  final String? secretMarkEn;
  final String contactInfoTh;
  final String contactInfoEn;
  final DonationInfo? donation;
  final HelpPostStatus status;
  final bool isMine;
  final bool clueSent;
  final bool allowsChatClues;
  final bool isUrgent;
  final String? shortNameTh;
  final String? shortNameEn;
  final String postedBy;
  final String ownerNameTh;
  final String ownerNameEn;

  String title(bool isEn) => isEn ? titleEn : titleTh;
  String shortName(bool isEn) =>
      (isEn ? shortNameEn : shortNameTh) ?? title(isEn);
  String location(bool isEn) => isEn ? locationEn : locationTh;
  String timeAgo(bool isEn) => isEn ? timeAgoEn : timeAgoTh;
  String? reward(bool isEn) => isEn ? rewardEn : rewardTh;
  String summary(bool isEn) => isEn ? summaryEn : summaryTh;
  String detailTraits(bool isEn) => isEn ? detailTraitsEn : detailTraitsTh;
  String? secretMark(bool isEn) => isEn ? secretMarkEn : secretMarkTh;
  String contactInfo(bool isEn) => isEn ? contactInfoEn : contactInfoTh;
  String ownerName(bool isEn) => isEn ? ownerNameEn : ownerNameTh;

  HelpPost copyWith({
    String? titleTh,
    String? titleEn,
    HelpCategory? category,
    String? imageAsset,
    String? locationTh,
    String? locationEn,
    double? distanceKm,
    String? timeAgoTh,
    String? timeAgoEn,
    String? rewardTh,
    String? rewardEn,
    String? summaryTh,
    String? summaryEn,
    String? detailTraitsTh,
    String? detailTraitsEn,
    String? secretMarkTh,
    String? secretMarkEn,
    String? contactInfoTh,
    String? contactInfoEn,
    DonationInfo? donation,
    HelpPostStatus? status,
    bool? isMine,
    bool? clueSent,
    bool? allowsChatClues,
  }) {
    return HelpPost(
      id: id,
      titleTh: titleTh ?? this.titleTh,
      titleEn: titleEn ?? this.titleEn,
      category: category ?? this.category,
      imageAsset: imageAsset ?? this.imageAsset,
      locationTh: locationTh ?? this.locationTh,
      locationEn: locationEn ?? this.locationEn,
      distanceKm: distanceKm ?? this.distanceKm,
      timeAgoTh: timeAgoTh ?? this.timeAgoTh,
      timeAgoEn: timeAgoEn ?? this.timeAgoEn,
      rewardTh: rewardTh ?? this.rewardTh,
      rewardEn: rewardEn ?? this.rewardEn,
      summaryTh: summaryTh ?? this.summaryTh,
      summaryEn: summaryEn ?? this.summaryEn,
      detailTraitsTh: detailTraitsTh ?? this.detailTraitsTh,
      detailTraitsEn: detailTraitsEn ?? this.detailTraitsEn,
      secretMarkTh: secretMarkTh ?? this.secretMarkTh,
      secretMarkEn: secretMarkEn ?? this.secretMarkEn,
      contactInfoTh: contactInfoTh ?? this.contactInfoTh,
      contactInfoEn: contactInfoEn ?? this.contactInfoEn,
      donation: donation ?? this.donation,
      status: status ?? this.status,
      isMine: isMine ?? this.isMine,
      clueSent: clueSent ?? this.clueSent,
      allowsChatClues: allowsChatClues ?? this.allowsChatClues,
      isUrgent: isUrgent,
      shortNameTh: shortNameTh,
      shortNameEn: shortNameEn,
      postedBy: postedBy,
      ownerNameTh: ownerNameTh,
      ownerNameEn: ownerNameEn,
    );
  }

  @override
  List<Object?> get props => [
        id,
        titleTh,
        titleEn,
        category,
        imageAsset,
        locationTh,
        locationEn,
        distanceKm,
        timeAgoTh,
        timeAgoEn,
        rewardTh,
        rewardEn,
        summaryTh,
        summaryEn,
        detailTraitsTh,
        detailTraitsEn,
        secretMarkTh,
        secretMarkEn,
        contactInfoTh,
        contactInfoEn,
        donation,
        status,
        isMine,
        clueSent,
        allowsChatClues,
      ];
}

/// อาการวิกฤตในหน้าต่างฉุกเฉิน
class EmergencySymptom extends Equatable {
  const EmergencySymptom({required this.titleTh, required this.titleEn});

  final String titleTh;
  final String titleEn;

  String title(bool isEn) => isEn ? titleEn : titleTh;

  @override
  List<Object?> get props => [titleTh, titleEn];
}

/// โรงพยาบาลสัตว์ 24 ชม. ที่แนะนำในหน้าต่างฉุกเฉิน
class EmergencyHospital extends Equatable {
  const EmergencyHospital({
    required this.nameTh,
    required this.nameEn,
    required this.distanceKm,
    required this.hoursTh,
    required this.hoursEn,
    required this.phone,
  });

  final String nameTh;
  final String nameEn;
  final double distanceKm;
  final String hoursTh;
  final String hoursEn;
  final String phone;

  String name(bool isEn) => isEn ? nameEn : nameTh;
  String hours(bool isEn) => isEn ? hoursEn : hoursTh;

  @override
  List<Object?> get props => [nameTh, nameEn, distanceKm, hoursTh, hoursEn, phone];
}

/// ประวัติการช่วยเหลือของผู้ใช้
class MyRescueRecord extends Equatable {
  const MyRescueRecord({
    required this.id,
    required this.titleTh,
    required this.titleEn,
    required this.catNameTh,
    required this.catNameEn,
    required this.dateTh,
    required this.dateEn,
    required this.typeTh,
    required this.typeEn,
    this.amountBaht = 0,
  });

  final String id;
  final String titleTh;
  final String titleEn;
  final String catNameTh;
  final String catNameEn;
  final String dateTh;
  final String dateEn;
  final String typeTh;
  final String typeEn;
  final int amountBaht;

  String title(bool isEn) => isEn ? titleEn : titleTh;
  String catName(bool isEn) => isEn ? catNameEn : catNameTh;
  String date(bool isEn) => isEn ? dateEn : dateTh;
  String type(bool isEn) => isEn ? typeEn : typeTh;

  @override
  List<Object?> get props => [id, titleTh, catNameTh, dateTh, typeTh, amountBaht];
}

/// ข้อมูลทั้งหมดของหน้าช่วยเหลือ
class HelpSnapshot extends Equatable {
  const HelpSnapshot({
    required this.posts,
    required this.symptoms,
    required this.hospital,
    required this.rescueRecords,
  });

  final List<HelpPost> posts;
  final List<EmergencySymptom> symptoms;
  final EmergencyHospital hospital;
  final List<MyRescueRecord> rescueRecords;

  HelpSnapshot copyWith({
    List<HelpPost>? posts,
    List<EmergencySymptom>? symptoms,
    EmergencyHospital? hospital,
    List<MyRescueRecord>? rescueRecords,
  }) {
    return HelpSnapshot(
      posts: posts ?? this.posts,
      symptoms: symptoms ?? this.symptoms,
      hospital: hospital ?? this.hospital,
      rescueRecords: rescueRecords ?? this.rescueRecords,
    );
  }

  @override
  List<Object?> get props => [posts, symptoms, hospital, rescueRecords];
}

/// ข้อมูลสำหรับสร้างประกาศใหม่
class CreateHelpPostInput {
  const CreateHelpPostInput({
    required this.category,
    required this.title,
    this.catName,
    required this.summary,
    required this.location,
    this.timeLabel,
    this.secretMark,
    this.imageAsset = 'assets/images/help/mochi.jpg',
    this.imageFilePath,
    this.allowsChatClues = true,
    this.shareToFeed = true,
    this.enableDonation = false,
    this.targetBaht = 0,
    this.donationPurpose,
  });

  final HelpCategory category;
  final String title;
  final String? catName;
  final String summary;
  final String location;
  final String? timeLabel;
  final String? secretMark;
  final String imageAsset;
  final String? imageFilePath;
  final bool allowsChatClues;
  final bool shareToFeed;
  final bool enableDonation;
  final int targetBaht;
  final String? donationPurpose;
}

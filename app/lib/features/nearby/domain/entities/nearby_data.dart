import 'package:equatable/equatable.dart';

/// พื้นที่ตัวอย่างสำหรับหน้าใกล้ฉัน (รองรับตำแหน่งปัจจุบันที่อิงพิกัดอารีย์เป็นค่าเริ่มต้น)
enum NearbyAreaId { myLocation, ari, thonglor, latPhrao71 }

/// หมวดหมู่บนแถบตัวกรองของหน้าใกล้ฉัน
enum NearbyCategory {
  cafe,
  clinic,
  shop,
  announcements,
  grooming,
  boarding,
}

/// ประเภทของสถานที่สำหรับสีหมุดและป้ายบนแผนที่
enum NearbyPlaceType { clinic, shop, grooming, boarding, cafe }

/// ประเภทของประกาศแมวใกล้คุณ
enum NearbyAnnouncementType { lostCat, foundCat, communityCat }

/// สถานที่ใกล้คุณ
class NearbyPlace extends Equatable {
  const NearbyPlace({
    required this.id,
    required this.areaId,
    required this.nameTh,
    required this.nameEn,
    required this.type,
    required this.rating,
    required this.reviewCount,
    required this.distanceKm,
    required this.isOpen,
    required this.statusTextTh,
    required this.statusTextEn,
    required this.phone,
    required this.latitude,
    required this.longitude,
    required this.imageSource,
    this.isEmergency24h = false,
    this.shortEmergencyNameTh,
    this.shortEmergencyNameEn,
  });

  final String id;
  final NearbyAreaId areaId;
  final String nameTh;
  final String nameEn;
  final NearbyPlaceType type;
  final double rating;
  final int reviewCount;
  final double distanceKm;
  final bool isOpen;
  final String statusTextTh;
  final String statusTextEn;
  final String phone;
  final double latitude;
  final double longitude;
  final String imageSource;
  final bool isEmergency24h;
  final String? shortEmergencyNameTh;
  final String? shortEmergencyNameEn;

  String name(bool isEn) => isEn ? nameEn : nameTh;
  String statusText(bool isEn) => isEn ? statusTextEn : statusTextTh;
  String emergencyShortName(bool isEn) =>
      isEn ? (shortEmergencyNameEn ?? nameEn) : (shortEmergencyNameTh ?? nameTh);

  bool matchesCategory(NearbyCategory category) {
    return switch (category) {
      NearbyCategory.cafe => type == NearbyPlaceType.cafe,
      NearbyCategory.clinic => type == NearbyPlaceType.clinic,
      NearbyCategory.shop => type == NearbyPlaceType.shop,
      NearbyCategory.grooming => type == NearbyPlaceType.grooming,
      NearbyCategory.boarding => type == NearbyPlaceType.boarding,
      NearbyCategory.announcements => false,
    };
  }

  @override
  List<Object?> get props => [
    id,
    areaId,
    nameTh,
    nameEn,
    type,
    rating,
    reviewCount,
    distanceKm,
    isOpen,
    statusTextTh,
    statusTextEn,
    phone,
    latitude,
    longitude,
    imageSource,
    isEmergency24h,
    shortEmergencyNameTh,
    shortEmergencyNameEn,
  ];
}

/// ประกาศแมวใกล้คุณ (แมวหาย / พบแมว / แมวชุมชน)
class NearbyAnnouncement extends Equatable {
  const NearbyAnnouncement({
    required this.id,
    required this.areaId,
    required this.type,
    required this.titleTh,
    required this.titleEn,
    required this.timeTextTh,
    required this.timeTextEn,
    required this.distanceKm,
    required this.latitude,
    required this.longitude,
    required this.imageSource,
  });

  final String id;
  final NearbyAreaId areaId;
  final NearbyAnnouncementType type;
  final String titleTh;
  final String titleEn;
  final String timeTextTh;
  final String timeTextEn;
  final double distanceKm;
  final double latitude;
  final double longitude;
  final String imageSource;

  String title(bool isEn) => isEn ? titleEn : titleTh;
  String timeText(bool isEn) => isEn ? timeTextEn : timeTextTh;

  @override
  List<Object?> get props => [
    id,
    areaId,
    type,
    titleTh,
    titleEn,
    timeTextTh,
    timeTextEn,
    distanceKm,
    latitude,
    longitude,
    imageSource,
  ];
}

/// ข้อมูลพื้นที่หนึ่งโซน (จุดศูนย์กลางแผนที่ + รายการสถานที่ + ประกาศ)
class NearbyAreaDataset extends Equatable {
  const NearbyAreaDataset({
    required this.areaId,
    required this.centerLat,
    required this.centerLng,
    required this.places,
    required this.announcements,
  });

  final NearbyAreaId areaId;
  final double centerLat;
  final double centerLng;
  final List<NearbyPlace> places;
  final List<NearbyAnnouncement> announcements;

  @override
  List<Object?> get props => [
    areaId,
    centerLat,
    centerLng,
    places,
    announcements,
  ];
}

/// ข้อมูลรวมสำหรับหน้าใกล้ฉัน
class NearbySnapshot extends Equatable {
  const NearbySnapshot({
    required this.datasets,
    required this.bookmarkedPlaceIds,
  });

  final Map<NearbyAreaId, NearbyAreaDataset> datasets;
  final Set<String> bookmarkedPlaceIds;

  NearbyAreaDataset datasetFor(NearbyAreaId areaId) {
    final effective = areaId == NearbyAreaId.myLocation
        ? NearbyAreaId.ari
        : areaId;
    return datasets[effective] ?? datasets.values.first;
  }

  @override
  List<Object?> get props => [datasets, bookmarkedPlaceIds];
}

/// แปลงระยะทางเป็นข้อความสั้น (เช่น `350 ม.` / `1.2 กม.`)
String formatNearbyDistance(double km, {required bool isEn}) {
  if (km < 1.0) {
    final meters = (km * 1000).round();
    return isEn ? '$meters m' : '$meters ม.';
  }
  final formatted = km.toStringAsFixed(1);
  return isEn ? '$formatted km' : '$formatted กม.';
}

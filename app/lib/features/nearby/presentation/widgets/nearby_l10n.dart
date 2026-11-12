import '../../domain/entities/nearby_data.dart';

/// ข้อความ UI ของหน้าใกล้ฉัน (/nearby) รองรับทั้งภาษาไทยและภาษาอังกฤษ
abstract final class NearbyL10n {
  static String title(bool isEn) => isEn ? 'Nearby' : 'ใกล้ฉัน';
  static String settingsLabel(bool isEn) =>
      isEn ? 'Nearby settings' : 'ตั้งค่าใกล้ฉัน';
  static String searchHint(bool isEn) =>
      isEn ? 'Search places or notices' : 'ค้นหาสถานที่หรือประกาศ';
  static String radiusPill(int km, bool isEn) =>
      isEn ? 'Within $km km' : 'ในรัศมี $km กม.';
  static String radiusOption(int km, bool isEn) =>
      isEn ? '$km km' : '$km กม.';

  static String areaTriggerLabel(
    NearbyAreaId areaId,
    bool isEn, {
    bool hasRealLocation = false,
  }) {
    return switch (areaId) {
      NearbyAreaId.myLocation => hasRealLocation
          ? (isEn ? 'My location' : 'ตำแหน่งของฉัน')
          : (isEn ? 'Ari' : 'อารีย์'),
      NearbyAreaId.ari => isEn ? 'Ari' : 'อารีย์',
      NearbyAreaId.thonglor => isEn ? 'Thonglor' : 'ทองหล่อ',
      NearbyAreaId.latPhrao71 => isEn ? 'Lat Phrao 71' : 'ลาดพร้าว 71',
    };
  }

  static String areaOptionLabel(NearbyAreaId areaId, bool isEn) {
    return switch (areaId) {
      NearbyAreaId.myLocation =>
        isEn ? 'My current location' : 'ตำแหน่งของฉันตอนนี้',
      NearbyAreaId.ari => isEn ? 'Ari' : 'อารีย์',
      NearbyAreaId.thonglor => isEn ? 'Thonglor' : 'ทองหล่อ',
      NearbyAreaId.latPhrao71 => isEn ? 'Lat Phrao 71' : 'ลาดพร้าว 71',
    };
  }

  static String myLocationHint(bool isEn) =>
      isEn ? 'Tap to allow location access' : 'แตะเพื่ออนุญาตให้ใช้ตำแหน่ง';
  static String areaSubtitle(NearbyAreaId areaId, bool isEn) {
    return switch (areaId) {
      NearbyAreaId.myLocation => myLocationHint(isEn),
      NearbyAreaId.ari => isEn
          ? 'Phaya Thai, Bangkok · 2 Lost · 14 Community'
          : 'พญาไท, กรุงเทพฯ · แมวหาย 2 · แมวชุมชน 14',
      NearbyAreaId.thonglor => isEn
          ? 'Watthana, Bangkok · 1 Lost · 8 Community'
          : 'วัฒนา, กรุงเทพฯ · แมวหาย 1 · แมวชุมชน 8',
      NearbyAreaId.latPhrao71 => isEn
          ? 'Wang Thonglang, Bangkok · 3 Lost · 21 Community'
          : 'วังทองหลาง, กรุงเทพฯ · แมวหาย 3 · แมวชุมชน 21',
    };
  }

  static String myLocationSubheader(bool isEn) =>
      isEn ? 'My location' : 'ตำแหน่งของฉัน';
  static String otherAreasSubheader(bool isEn) =>
      isEn ? 'Other areas' : 'ดูพื้นที่อื่น';

  static String categoryLabel(NearbyCategory category, bool isEn) {
    return switch (category) {
      NearbyCategory.cafe => isEn ? 'Cat Café' : 'คาเฟ่',
      NearbyCategory.clinic => isEn ? 'Vet Clinic' : 'คลินิก',
      NearbyCategory.shop => isEn ? 'Pet Shop' : 'ร้านสัตว์เลี้ยง',
      NearbyCategory.announcements => isEn ? 'Notices' : 'ประกาศใกล้ฉัน',
      NearbyCategory.grooming => isEn ? 'Grooming' : 'อาบน้ำตัดขน',
      NearbyCategory.boarding => isEn ? 'Cat Boarding' : 'รับฝากแมว',
    };
  }

  static String placeTypeLabel(NearbyPlaceType type, bool isEn) {
    return switch (type) {
      NearbyPlaceType.clinic => isEn ? 'Vet Clinic' : 'คลินิก',
      NearbyPlaceType.shop => isEn ? 'Pet Shop' : 'ร้านค้า',
      NearbyPlaceType.grooming => isEn ? 'Grooming' : 'อาบน้ำ-ตัดขน',
      NearbyPlaceType.boarding => isEn ? 'Cat Boarding' : 'รับฝาก',
      NearbyPlaceType.cafe => isEn ? 'Pet-friendly' : 'Pet-friendly',
    };
  }

  static String announcementTypeLabel(
    NearbyAnnouncementType type,
    bool isEn,
  ) {
    return switch (type) {
      NearbyAnnouncementType.lostCat => isEn ? 'Lost Cat' : 'แมวหาย',
      NearbyAnnouncementType.foundCat => isEn ? 'Found Cat' : 'พบแมว',
      NearbyAnnouncementType.communityCat =>
        isEn ? 'Community Cat' : 'แมวชุมชน',
    };
  }

  static String mapDisclaimer(bool isEn) =>
      isEn ? 'Pins show sample data' : 'หมุดเป็นข้อมูลตัวอย่าง';
  static String fullscreenBtn(bool isEn) => isEn ? 'Full map' : 'เต็มจอ';
  static String listBtn(bool isEn) => isEn ? 'List view' : 'ดูรายการ';
  static String recenterBtn(bool isEn) =>
      isEn ? 'Use my location' : 'ใช้ตำแหน่งของฉัน';
  static String closeBtn(bool isEn) => isEn ? 'Close' : 'ปิด';

  static String emergency24h(bool isEn) =>
      isEn ? '24h Emergency' : 'ฉุกเฉิน 24 ชม.';
  static String callBtn(bool isEn) => isEn ? 'Call' : 'โทร';

  static String placesSectionTitle({
    required int count,
    required bool isExpanded,
    required bool isEn,
  }) {
    if (isExpanded) {
      return isEn ? 'Places near you ($count)' : 'สถานที่ใกล้คุณ $count แห่ง';
    }
    return isEn ? 'Places near you' : 'สถานที่ใกล้คุณ';
  }

  static String placeDistance(double km, {required bool isEn}) {
    final formatted = km.toStringAsFixed(1);
    return isEn ? '$formatted km' : '$formatted กม.';
  }

  static String announcementsSectionTitle({
    required bool isAnnouncementCategory,
    required bool isEn,
  }) {
    if (isAnnouncementCategory) {
      return isEn ? 'Notices near you' : 'ประกาศใกล้คุณ';
    }
    return isEn ? 'Cats near you' : 'แมวใกล้คุณ';
  }

  static String seeAll(bool isEn) => isEn ? 'See all' : 'ดูทั้งหมด';
  static String collapse(bool isEn) => isEn ? 'Show less' : 'ย่อ';
  static String viewNotice(bool isEn) => isEn ? 'View notice' : 'ดูประกาศ';

  static String emptyMessage(bool isEn) => isEn
      ? 'No places or notices match your search in this area'
      : 'ไม่พบข้อมูลที่ตรงกับการค้นหาในพื้นที่นี้';
  static String errorMessage(bool isEn) => isEn
      ? 'Could not load nearby places right now'
      : 'ไม่สามารถโหลดข้อมูลใกล้ฉันได้ในขณะนี้';
  static String retryBtn(bool isEn) => isEn ? 'Try again' : 'ลองใหม่';

  static String settingsAreaHeader(bool isEn) => isEn ? 'Area' : 'พื้นที่';
  static String settingsRadiusHeader(bool isEn) =>
      isEn ? 'Search radius' : 'รัศมีค้นหา';
  static String settingsShowAnnouncementsTitle(bool isEn) =>
      isEn ? 'Show cat notices on map' : 'แสดงประกาศแมวบนแผนที่';
  static String settingsShowAnnouncementsSub(bool isEn) => isEn
      ? 'Lost cats, found cats, and cats needing help'
      : 'แมวหาย แมวหาบ้าน และแมวที่ต้องการความช่วยเหลือ';
  static String doneBtn(bool isEn) => isEn ? 'Done' : 'เสร็จ';

  static String savedToast(String name, bool saved, bool isEn) {
    if (isEn) {
      return saved ? 'Saved $name' : 'Removed $name from saved';
    }
    return saved ? 'บันทึก $name แล้ว' : 'นำ $name ออกจากรายการที่บันทึกแล้ว';
  }

  static String locationUpdatedToast(
    bool isEn, {
    double? lat,
    double? lng,
  }) {
    if (lat != null && lng != null) {
      final coords = '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
      return isEn
          ? 'Updated location ($coords)'
          : 'อัปเดตตำแหน่งแล้ว ($coords)';
    }
    return isEn ? 'Updated to your current location' : 'อัปเดตตำแหน่งของคุณแล้ว';
  }
  static String locationDeniedToast(bool isEn) => isEn
      ? 'Please allow location permission'
      : 'กรุณาอนุญาตการเข้าถึงตำแหน่ง';
  static String phoneCopiedToast(String phone, bool isEn) => isEn
      ? 'Copied $phone (dialer unavailable here)'
      : 'คัดลอกเบอร์ $phone แล้ว (เครื่องจำลองโทรออกไม่ได้)';
}

import '../../domain/entities/help_data.dart';

/// ข้อความสองภาษา (ไทย / EN) สำหรับหน้าช่วยเหลือ (/help) และชีตที่เกี่ยวข้อง
abstract final class HelpL10n {
  static String pageTitle(bool isEn) => isEn ? 'Help' : 'ช่วยเหลือ';

  static String tabNearby(bool isEn) => isEn ? 'Near you' : 'ใกล้คุณ';
  static String tabMyPosts(bool isEn) => isEn ? 'My posts' : 'ประกาศของฉัน';
  static String allCategories(bool isEn) => isEn ? 'All' : 'ทั้งหมด';

  static String categoryLabel(HelpCategory c, bool isEn) => switch (c) {
        HelpCategory.lost => isEn ? 'Lost' : 'แมวหาย',
        HelpCategory.found => isEn ? 'Found' : 'พบแมว',
        HelpCategory.helpRequest => isEn ? 'Help' : 'ขอช่วย',
        HelpCategory.adoption => isEn ? 'Adopt' : 'รับเลี้ยง',
        HelpCategory.foster => isEn ? 'Foster' : 'อุปการะ',
      };

  static String categoryFullLabel(HelpCategory c, bool isEn) => switch (c) {
        HelpCategory.lost => isEn ? 'Lost cat' : 'แมวหาย',
        HelpCategory.found => isEn ? 'Found cat' : 'พบแมว',
        HelpCategory.helpRequest => isEn ? 'Request help' : 'ขอความช่วยเหลือ',
        HelpCategory.adoption => isEn ? 'Adoption' : 'รับเลี้ยง',
        HelpCategory.foster => isEn ? 'Foster care' : 'อุปการะ',
      };

  static String statusLabel(HelpPostStatus s, bool isEn) => switch (s) {
        HelpPostStatus.active => isEn ? 'Active' : 'กำลังประกาศ',
        HelpPostStatus.resolved => isEn ? 'Resolved' : 'พบแล้ว / ช่วยแล้ว',
        HelpPostStatus.closed => isEn ? 'Closed' : 'ปิดประกาศ',
      };

  static String distanceText(double km, bool isEn) {
    if (km < 1.0) {
      final meters = (km * 1000).round();
      return isEn ? '$meters m away' : 'ห่าง $meters ม.';
    }
    final formatted = km.toStringAsFixed(1);
    return isEn ? '$formatted km away' : 'ห่าง $formatted กม.';
  }

  static String sendClue(bool isEn) => isEn ? 'Report clue' : 'แจ้งเบาะแส';
  static String clueSent(bool isEn) => isEn ? '✓ Sent' : '✓ ส่งแล้ว';
  static String clueSentToast(String title, bool isEn) => isEn
      ? 'Clue sent to $title owner'
      : 'ส่งแจ้งเบาะแสให้เจ้าของ "$title" แล้ว';

  static String contactFinder(bool isEn) =>
      isEn ? 'Contact finder' : 'ติดต่อผู้พบ';
  static String interestedAdopt(bool isEn) =>
      isEn ? 'Interested in adopting' : 'สนใจรับเลี้ยง';
  static String fosterAction(bool isEn) => isEn ? 'Foster' : 'รับอุปการะ';
  static String supportCase(String shortName, bool isEn) =>
      isEn ? 'Help "$shortName"' : 'ช่วย "$shortName"';
  static String urgentBadge(bool isEn) => isEn ? 'Urgent' : 'ด่วน';
  static String postedByText(String handle, bool isEn) =>
      isEn ? 'Posted by $handle' : 'โพสต์โดย $handle';
  static String remainingBahtText(String formattedBaht, bool isEn) =>
      isEn ? '฿$formattedBaht left' : 'อีก ฿$formattedBaht';
  static String donorsCountText(int count, bool isEn) =>
      isEn ? '$count helpers' : '$count คนช่วย';
  static String donateClosed(bool isEn) =>
      isEn ? 'Donations closed' : 'ปิดรับบริจาคแล้ว';
  static String viewDetails(bool isEn) =>
      isEn ? 'View details' : 'ดูรายละเอียด';
  static String collapseDetails(bool isEn) => isEn ? 'Less' : 'ย่อ';

  static String safetyFootnote(bool isEn) => isEn
      ? 'Locations in posts are approximate for safety.'
      : 'ตำแหน่งในประกาศแสดงแบบประมาณเพื่อความปลอดภัย';

  // ปุ่มลอย
  static String emergencyButton(bool isEn) => isEn ? 'Emergency' : 'ฉุกเฉิน';
  static String emergencyBannerHint(bool isEn) => isEn
      ? 'Cat emergency · Call 24h vet clinic'
      : 'แมวป่วยฉุกเฉิน · โทรด่วนรพ.สัตว์ใกล้ฉัน';
  static String createPostButton(bool isEn) =>
      isEn ? 'Create post' : 'สร้างประกาศ';

  // ป๊อปอัปฉุกเฉิน
  static String emergencyModalTitle(bool isEn) =>
      isEn ? 'Cat Emergency?' : 'แมวป่วยฉุกเฉิน?';
  static String emergencySymptomsHeading(bool isEn) => isEn
      ? 'Go to vet immediately if you see these signs'
      : 'พาไปโรงพยาบาลทันที ถ้ามีอาการเหล่านี้';
  static String emergencyNearestHospitalLabel(bool isEn) =>
      isEn ? 'Nearest right now' : 'ใกล้ที่สุดตอนนี้';
  static String navigateLabel(bool isEn) => isEn ? 'Navigate' : 'นำทาง';
  static String callEmergencyNow(bool isEn) =>
      isEn ? 'Call 24h vet clinic now' : 'โทรด่วน · รพ.สัตว์ใกล้ฉัน';
  static String viewOnMapLabel(bool isEn) =>
      isEn ? 'View on map' : 'ดูบนแผนที่';
  static String askCatAiLabel(bool isEn) =>
      isEn ? 'Ask Cat AI' : 'ถาม Cat AI';
  static String nearbyClinicsTitle(bool isEn) =>
      isEn ? 'Vet clinics near you' : 'รพ.สัตว์ใกล้คุณ';
  static String backToSymptoms(bool isEn) =>
      isEn ? 'Emergency signs' : 'ดูอาการฉุกเฉิน';
  static String callButton(bool isEn) => isEn ? 'Call' : 'โทร';
  static String clinicFootnote(bool isEn) => isEn
      ? 'Call ahead before leaving · Sample numbers in prototype'
      : 'โทรแจ้งอาการก่อนออกเดินทาง · เบอร์ตัวอย่างในต้นแบบ';
  static String close(bool isEn) => isEn ? 'Close' : 'ปิด';
  static String phoneCopiedToast(String phone, bool isEn) => isEn
      ? 'Copied $phone'
      : 'คัดลอกเบอร์ $phone แล้ว';

  // สร้างประกาศ Step 1 & Step 2
  static String choosePostTypeTitle(bool isEn) =>
      isEn ? 'What is this post about?' : 'แจ้งประกาศเรื่องอะไร?';
  static String lostSub(bool isEn) => isEn
      ? 'Ask people nearby to help search'
      : 'ให้คนแถวนี้ช่วยตามหา';
  static String foundSub(bool isEn) => isEn
      ? 'AI helps match with lost cat posts'
      : 'AI ช่วยจับคู่กับประกาศแมวหาย';
  static String helpRequestSub(bool isEn) => isEn
      ? 'Injured stray, trapped kitten, etc.'
      : 'แมวจรบาดเจ็บ ลูกแมวติดอยู่ ฯลฯ';

  static String createFormTitle(HelpCategory c, bool isEn) => switch (c) {
        HelpCategory.lost => isEn ? 'Report lost cat' : 'แจ้งแมวหาย',
        HelpCategory.found => isEn ? 'Report found cat' : 'แจ้งพบแมว',
        HelpCategory.helpRequest =>
          isEn ? 'Request help' : 'ขอความช่วยเหลือ',
        _ => categoryFullLabel(c, isEn),
      };
  static String whichMyCatLost(bool isEn) =>
      isEn ? 'Which of your cats is lost?' : 'แมวของฉันตัวไหนหาย?';
  static String catPhotoLabel(bool isEn) => isEn ? 'Cat photo' : 'รูปแมว';
  static String pickFromGallery(bool isEn) =>
      isEn ? 'Select from gallery' : 'เลือกรูปจากแกลลอรี่';
  static String pickPhotoHint(bool isEn) => isEn
      ? 'Clear face & markings · No house number or license plate'
      : 'เห็นหน้าและลายชัด ๆ · ไม่ติดเลขที่บ้านหรือทะเบียนรถ';
  static String enterTitleHint(bool isEn) =>
      isEn ? 'Enter cat name & appearance first' : 'ใส่ชื่อแมวและลักษณะก่อน';
  static String selectMyCatLabel(bool isEn) =>
      isEn ? 'Select my cat profile' : 'เลือกโปรไฟล์แมวของคุณ';
  static String otherCat(bool isEn) => isEn ? 'Other' : 'ตัวอื่น';
  static String uploadCatPhoto(bool isEn) =>
      isEn ? 'Tap to select cat photo' : 'แตะเพื่อเลือกรูปแมว';
  static String photoSelected(bool isEn) =>
      isEn ? 'Photo attached' : 'แนบรูปภาพเรียบร้อยแล้ว';
  static String titleAndTraitsLabel(bool isEn) =>
      isEn ? 'Cat name & appearance *' : 'ชื่อแมวและลักษณะ *';
  static String whatHappenedLabel(bool isEn) =>
      isEn ? 'What happened *' : 'เกิดอะไรขึ้น *';
  static String catNameOptionalLabel(bool isEn) =>
      isEn ? 'Cat name (optional)' : 'ชื่อแมว (ถ้ามี)';
  static String detailsLabel(bool isEn) =>
      isEn ? 'More details' : 'รายละเอียดเพิ่มเติม';
  static String locationLabel(bool isEn) =>
      isEn ? 'Area / Location *' : 'บริเวณที่หาย / เกิดเหตุ *';
  static String lostTimeLabel(bool isEn) => isEn ? 'Lost / seen time' : 'หายเมื่อ';
  static String secretMarkLabel(bool isEn) => isEn
      ? 'Secret identifying mark (owner verification)'
      : 'จุดสังเกตลับ (สำหรับยืนยันความเป็นเจ้าของ)';
  static String allowChatCluesLabel(bool isEn) => isEn
      ? 'Receive clues via Cat.live chat immediately'
      : 'เปิดรับเบาะแสผ่านแชต แมว.live ทันที';
  static String enableDonationLabel(bool isEn) =>
      isEn ? 'Open fundraising / donations' : 'เปิดรับบริจาค';
  static String targetBahtLabel(bool isEn) =>
      isEn ? 'Target amount (฿)' : 'เป้าหมาย ฿';
  static String donationPurposeLabel(bool isEn) => isEn
      ? 'Purpose (e.g. surgery & medication)'
      : 'ใช้ทำอะไร เช่น ค่าผ่าตัดและยา';

  static String previewBeforePost(bool isEn) =>
      isEn ? 'Preview before posting' : 'ดูตัวอย่างก่อนโพสต์';
  static String previewTitle(bool isEn) =>
      isEn ? 'Post preview' : 'ตัวอย่างประกาศที่จะแสดง';
  static String confirmAndPost(bool isEn) =>
      isEn ? 'Confirm & post' : 'ยืนยันและโพสต์ประกาศ';
  static String postCreatedToast(bool isEn) =>
      isEn ? 'Help post published' : 'โพสต์ประกาศช่วยเหลือเรียบร้อยแล้ว';
  static String fillRequiredToast(bool isEn) => isEn
      ? 'Please fill required title and location'
      : 'กรุณากรอกข้อมูลสำคัญและบริเวณที่เกิดเหตุให้ครบ';

  // แท็บประกาศของฉัน & ประวัติช่วยเหลือ
  static String managePost(bool isEn) => isEn ? 'Manage >' : 'จัดการ >';
  static String myRescueHistoryBtn(bool isEn) =>
      isEn ? 'My rescue history' : 'การช่วยเหลือของฉัน';
  static String markResolved(bool isEn) =>
      isEn ? 'Mark as found / helped' : 'เปลี่ยนสถานะ: พบแล้ว / ช่วยแล้ว';
  static String closePost(bool isEn) => isEn ? 'Close post' : 'ปิดประกาศ';
  static String reopenPost(bool isEn) => isEn ? 'Reopen post' : 'เปิดประกาศอีกครั้ง';
  static String editPost(bool isEn) => isEn ? 'Edit post' : 'แก้ไขข้อมูล';
  static String resharePost(bool isEn) => isEn ? 'Share again' : 'แชร์ประกาศซ้ำ';
  static String saveChanges(bool isEn) => isEn ? 'Save' : 'บันทึก';
  static String statusUpdatedToast(bool isEn) =>
      isEn ? 'Post status updated' : 'อัปเดตสถานะประกาศแล้ว';
  static String postUpdatedToast(bool isEn) =>
      isEn ? 'Post details updated' : 'บันทึกการแก้ไขประกาศแล้ว';

  static String rescueStatsCases(bool isEn) =>
      isEn ? 'Cases helped' : 'เคสที่เคยช่วย';
  static String rescueStatsDonated(bool isEn) =>
      isEn ? 'Total donated' : 'ยอดบริจาคสะสม';
  static String rescueCatsTitle(bool isEn) =>
      isEn ? 'Cats you helped' : 'รายชื่อแมวที่เคยช่วย';
  static String rescueTimelineTitle(bool isEn) =>
      isEn ? 'Rescue history timeline' : 'บันทึกการช่วยเหลือย้อนหลัง';

  // ตั้งค่า / ฟิลเตอร์
  static String filterSheetTitle(bool isEn) =>
      isEn ? 'Help settings' : 'ตั้งค่าช่วยเหลือ';
  static String radiusTitle(bool isEn) =>
      isEn ? 'Post radius around Ari' : 'รัศมีประกาศรอบอารีย์';
  static String notifyNearbyTitle(bool isEn) =>
      isEn ? 'Notify new nearby posts' : 'แจ้งเตือนประกาศใหม่ใกล้ฉัน';
  static String notifyNearbySub(bool isEn) => isEn
      ? 'Lost, found, and help cases within your selected radius'
      : 'แมวหาย พบแมว และเคสขอความช่วยเหลือในรัศมีที่เลือก';
  static String doneButton(bool isEn) => isEn ? 'Done' : 'เสร็จ';

  // Empty & Error
  static String emptyNearbyTitle(bool isEn) =>
      isEn ? 'No posts in this filter' : 'ไม่พบประกาศในหมวดหมู่นี้';
  static String emptyNearbySubtitle(bool isEn) => isEn
      ? 'Try expanding the radius or switching category'
      : 'ลองขยายรัศมีค้นหา หรือเลือกดูหมวดอื่นได้เลยครับ';
  static String emptyMyPostsTitle(bool isEn) =>
      isEn ? 'No posts created yet' : 'ยังไม่มีประกาศของคุณ';
  static String emptyMyPostsSubtitle(bool isEn) => isEn
      ? 'Tap "+ Create post" below whenever you need help'
      : 'กดปุ่ม "+ สร้างประกาศ" ด้านล่างเมื่อต้องการขอความช่วยเหลือ';
  static String resetFilters(bool isEn) =>
      isEn ? 'Show all posts' : 'แสดงประกาศทั้งหมด';
  static String loadErrorTitle(bool isEn) =>
      isEn ? 'Unable to load help posts' : 'โหลดประกาศช่วยเหลือไม่สำเร็จ';
  static String retry(bool isEn) => isEn ? 'Retry' : 'ลองใหม่';
}

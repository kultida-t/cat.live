/// ข้อความภาษาไทย/อังกฤษสำหรับหน้า แมว.live Tag (/tag) — ตรงตามเว็บจริง www.แมว.live/tag
abstract final class TagL10n {
  static String pageTitle(bool isEn) => 'แมว.live Tag';
  static String backLabel(bool isEn) => isEn ? 'Back' : 'ย้อนกลับ';
  static String loadError(bool isEn) =>
      isEn ? 'Could not load tag details' : 'โหลดข้อมูลแท็กไม่สำเร็จ';
  static String emptyTitle(bool isEn) =>
      isEn ? 'No tag details yet' : 'ยังไม่มีข้อมูลสินค้า';
  static String emptySubtitle(bool isEn) => isEn
      ? 'Tag details are currently unavailable.'
      : 'ยังไม่มีรายละเอียด แมว.live Tag ในขณะนี้';
  static String retry(bool isEn) => isEn ? 'Try again' : 'ลองใหม่';

  // Hero
  static String heroHeadline(bool isEn) =>
      isEn ? 'Lost cat\nNever search blindly' : 'น้องหลง\nไม่ต้องหลงหา';
  static String heroCaption(bool isEn) => isEn
      ? 'Clip it to the collar and the app\nshows roughly where your cat is'
      : 'ติดไว้กับปลอกคอ แล้วให้แอป\nช่วยบอกว่าน้องอยู่แถวไหน';

  // Section 2: ปลอกคอคู่แท็ก
  static String collarTitle(bool isEn) =>
      isEn ? 'A collar to match the tag' : 'ปลอกคอคู่แท็ก';
  static String collarSubtitle(bool isEn) => isEn
      ? 'Soft fabric pouch holds the tag snugly'
      : 'สายปลอกคอนุ่มพร้อมซองใส่แท็กเข้าชุดกัน';

  // Section 3: ใช้ง่ายใน 3 ขั้น
  static String stepsTitle(bool isEn) =>
      isEn ? 'Easy in 3 steps' : 'ใช้ง่ายใน 3 ขั้น';
  static String stepsSubtitle(bool isEn) =>
      isEn ? 'Set up once, use every day' : 'ตั้งค่าครั้งเดียว ใช้ได้ทุกวัน';
  static List<(String title, String desc)> steps(bool isEn) => isEn
      ? const [
          ('Clip on', 'Slide into the pouch'),
          ('Pair the app', 'Tap to add in the app'),
          ('See location', 'on the map'),
        ]
      : const [
          ('ติดปลอกคอ', 'สอดลงซอง'),
          ('จับคู่แอป', 'แตะเพิ่มในแอป'),
          ('ดูตำแหน่ง', 'บนแผนที่'),
        ];

  // Section 4: ทั้งบ้านช่วยกันดูแลน้อง
  static String familyTitle(bool isEn) => isEn
      ? 'The whole family looks after your cat'
      : 'ทั้งบ้านช่วยกันดูแลน้อง';
  static String familySubtitle(bool isEn) =>
      isEn ? 'Works with the แมว.live app' : 'ทำงานคู่กับแอป แมว.live';
  static List<(String title, String desc)> familyCards(bool isEn) => isEn
      ? const [
          ('Share with family', 'Caregivers see it too'),
          ('See location', 'Latest on the map'),
          ('Search together', 'Turn on Lost mode'),
        ]
      : const [
          ('แชร์ทั้งบ้าน', 'ผู้ดูแลเห็นด้วย'),
          ('ดูตำแหน่ง', 'ล่าสุดบนแผนที่'),
          ('ช่วยกันหา', 'เปิดโหมดแมวหาย'),
        ];
  static String mockTagTitle(bool isEn) =>
      isEn ? "Somjeed's Tag" : 'Tag ของส้มจี๊ด';
  static String mockOwnerStatus(bool isEn) =>
      isEn ? 'You are the owner' : 'คุณเป็นเจ้าของ';
  static String mockCoCaregivers(bool isEn) =>
      isEn ? 'Co-caregivers' : 'ผู้ดูแลร่วม';
  static List<String> mockCaregiverNames(bool isEn) =>
      isEn ? const ['Mom', 'Ton', 'Mew'] : const ['แม่', 'พี่ต้น', 'น้องมิว'];
  static String mockCanViewLocation(bool isEn) =>
      isEn ? 'Can view location' : 'ดูตำแหน่งได้';
  static String mockMapPinShort(bool isEn) => isEn ? 'Som' : 'ส้ม';
  static String mockMapTime(bool isEn) =>
      isEn ? 'Last seen · 5m ago' : 'ตำแหน่งล่าสุด · 5 นาทีที่แล้ว';
  static String mockLostModeBadge(bool isEn) =>
      isEn ? 'Lost mode' : 'โหมดแมวหาย';
  static String mockLostModeHeading(bool isEn) =>
      isEn ? 'Searching for Somjeed' : 'กำลังตามหา ส้มจี๊ด';
  static String mockNotifiedCaregivers(bool isEn) =>
      isEn ? 'Caregivers notified' : 'แจ้งผู้ดูแลแล้ว';
  static String mockNearbyHelp(bool isEn) =>
      isEn ? 'Nearby helpers alerted' : 'ให้คนแถวนี้ช่วยหา';

  // Section 5: เรียกแล้วได้ยินเสียง
  static String soundTitle(bool isEn) =>
      isEn ? 'Call it, hear it' : 'เรียกแล้วได้ยินเสียง';
  static String soundDesc(bool isEn) => isEn
      ? 'Hiding under the bed or behind a cabinet? Make the tag play a sound and follow it'
      : 'น้องมุดใต้เตียงหรือหลังตู้? กดให้แท็กส่งเสียง แล้ว\nเดินตามเสียงไปหาได้เลย';
  static String soundPlayingBadge(bool isEn) =>
      isEn ? 'Playing sound' : 'กำลังส่งเสียง';
  static String soundButton(bool isEn) => isEn ? 'Play sound' : 'ส่งเสียง';
  static String sampleCatName(bool isEn) => isEn ? 'Somjeed' : 'ส้มจี๊ด';

  // Section 6: ใกล้แล้ว เจอแล้ว
  static String closeTitle(bool isEn) =>
      isEn ? 'Getting close, found it' : 'ใกล้แล้ว เจอแล้ว';
  static String closeDesc(bool isEn) => isEn
      ? 'Up close, the app shows distance and direction, with a flashlight and sound button on one screen'
      : 'เมื่ออยู่ใกล้ แอปบอกระยะและทิศทาง พร้อมไฟฉายและปุ่มเรียกเสียงในหน้าเดียว';
  static String searchingBadge(bool isEn) =>
      isEn ? 'Searching' : 'กำลังตามหา';
  static String distanceSample(bool isEn) => isEn ? '3 m' : '3 ม.';
  static String directionHint(bool isEn) =>
      isEn ? 'To your right' : 'ไปทางขวามือของคุณ';
  static String closeLabel(bool isEn) => isEn ? 'Compass' : 'เข็มทิศ';
  static String flashlightLabel(bool isEn) => isEn ? 'Flashlight' : 'ไฟฉาย';
  static String soundShortLabel(bool isEn) => isEn ? 'Sound' : 'เสียง';
  static String flashlightOnToast(bool isEn) =>
      isEn ? 'Flashlight turned on (preview)' : 'เปิดไฟฉายแล้ว (ตัวอย่าง)';
  static String flashlightOffToast(bool isEn) =>
      isEn ? 'Flashlight turned off' : 'ปิดไฟฉายแล้ว';
  static String soundPlayingToast(bool isEn) =>
      isEn ? 'Playing tag chime on Somjeed' : 'กำลังส่งเสียงเรียกแท็กของ ส้มจี๊ด';

  // Section 7: ทำงานยังไง
  static String howTitle(bool isEn) => isEn ? 'How it works' : 'ทำงานยังไง';
  static String howDesc(bool isEn) => isEn
      ? 'The tag keeps sending a signal; phones with the แมว.live app nearby relay its location anonymously'
      : 'แท็กส่งสัญญาณเรื่อย ๆ มือถือที่มีแอป แมว.live ผ่านมาใกล้ ช่วยส่งตำแหน่งต่อ แบบไม่ระบุตัวตน';
  static List<String> howNodes(bool isEn) => isEn
      ? const ['Tag', 'Phones relay it', 'Your map']
      : const ['แท็ก', 'มือถือช่วยส่ง', 'แผนที่ของคุณ'];

  // Section 8: เห็นแค่คนในบ้าน
  static String privacyTitle(bool isEn) =>
      isEn ? 'Only your household sees it' : 'เห็นแค่คนในบ้าน';
  static String privacyDesc(bool isEn) => isEn
      ? "Only you and caregivers you invite can see it. People who relay it don't know whose cat it is"
      : 'เห็นได้แค่คุณ และผู้ดูแลที่คุณเชิญ คนที่ช่วยส่งต่อ ไม่รู้ว่าเป็นแมวของใคร';

  // Section 9: เป็นของน้องคนเดียว
  static String customTitle(bool isEn) =>
      isEn ? 'Made just for your cat' : 'เป็นของน้องคนเดียว';
  static String customDesc(bool isEn) => isEn
      ? 'Engrave a name or cat face on the tag and pick any collar color'
      : 'สลักชื่อหรือหน้าแมวบนแท็ก เลือกสีปลอกคอได้ตามใจ';
  static List<String> engraveSamples(bool isEn) => isEn
      ? const ['Somjeed', 'Cat face', 'Khaopun', 'Cat face', 'Mochi', 'Cat face']
      : const ['ส้มจี๊ด', 'หน้าแมว', 'ข้าวปั้น', 'หน้าแมว', 'โมจิ', 'หน้าแมว'];

  // Section 10: เล็ก เบา แต่ไว้ใจได้
  static String highlightsTitle(bool isEn) =>
      isEn ? 'Small, light, dependable' : 'เล็ก เบา แต่ไว้ใจได้';
  static List<(String title, String desc)> highlights(bool isEn) => isEn
      ? const [
          ('Long battery', 'Replaceable battery'),
          ('Water-resistant', 'Fine in the rain'),
          ('Very light', "Won't weigh down the neck"),
        ]
      : const [
          ('แบตอึด', 'ถ่านเปลี่ยนเองได้'),
          ('กันน้ำ', 'ตากฝนได้สบาย'),
          ('เบามาก', 'ไม่ถ่วงคอน้อง'),
        ];

  // Section 11: รายละเอียดสินค้า
  static String specsTitle(bool isEn) =>
      isEn ? 'Product specs' : 'รายละเอียดสินค้า';
  static String specsSubtitle(bool isEn, int price) => isEn
      ? 'แมว.live Tag · Starting from ฿$price'
      : 'แมว.live Tag · ราคาเริ่มต้น ฿$price';
  static String disclaimer(bool isEn) => isEn
      ? "The app shows the last location the tag sent, to help find a lost cat. It isn't continuous real-time tracking"
      : 'แอปแสดงตำแหน่งล่าสุดที่แท็กส่งมา ใช้ช่วยตามหาเมื่อน้องพลัดหลง ไม่ใช่การติดตามแบบเรียลไทม์ตลอดเวลา';

  // Fixed Bottom CTA & Order Summary Sheet
  static String fromLabel(bool isEn) => isEn ? 'From' : 'เริ่มต้น';
  static String buyNow(bool isEn) => isEn ? 'Buy now' : 'ซื้อเลย';
  static String orderSheetTitle(bool isEn) =>
      isEn ? 'Your Tag & Collar Selection' : 'สรุปแบบที่เลือกไว้';
  static String orderSheetTagLabel(bool isEn) => isEn ? 'Tag color' : 'สีตัวเรือน';
  static String orderSheetCollarLabel(bool isEn) =>
      isEn ? 'Collar color' : 'สีปลอกคอ';
  static String orderSheetNote(bool isEn) => isEn
      ? 'Collar & Tag checkout (/collars) is coming in the next phase.'
      : 'หน้าสั่งซื้อปลอกคอและแท็ก (/collars) กำลังพัฒนา จะเปิดใช้งานในเฟสถัดไป';
  static String close(bool isEn) => isEn ? 'Close' : 'ปิด';
}

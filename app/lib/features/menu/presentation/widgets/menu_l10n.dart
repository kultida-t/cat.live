import '../../domain/entities/menu_data.dart';

/// ข้อความ 2 ภาษา (ไทย/EN) สำหรับหน้าเมนูหลัก (/menu)
abstract final class MenuL10n {
  static String closeLabel(bool isEn) => isEn ? 'Close menu' : 'ปิดเมนู';
  static String servicesHeading(bool isEn) => isEn ? 'Services' : 'บริการเสริม';
  static String settingsHeading(bool isEn) => isEn ? 'Settings' : 'ตั้งค่า';
  static String comingSoonBadge(bool isEn) =>
      isEn ? 'Coming soon' : 'เร็ว ๆ นี้';

  static String serviceTitle(MenuServiceAction action, bool isEn) =>
      switch (action) {
        MenuServiceAction.tag => 'แมว.live Tag',
        MenuServiceAction.treats => isEn ? 'Send treats' : 'เลี้ยงอาหารน้อง ๆ',
        MenuServiceAction.memorial =>
          isEn ? 'Memorial Services' : 'บริการรำลึก',
        MenuServiceAction.memorialCremation =>
          isEn ? 'Cat cremation' : 'ฌาปนกิจแมว',
        MenuServiceAction.memorialSite =>
          isEn ? 'Memorial website' : 'เว็บไซต์รำลึก',
        MenuServiceAction.printCatId =>
          isEn ? 'Order Cat ID / QR Tag' : 'สั่งพิมพ์ Cat ID / ป้าย QR',
        MenuServiceAction.pedigree => isEn ? 'Pedigree' : 'ใบเพ็ดดีกรี',
        MenuServiceAction.insurance =>
          isEn ? 'Cat health insurance' : 'ประกันสุขภาพแมว',
      };

  static String? serviceSubtitle(MenuServiceAction action, bool isEn) =>
      switch (action) {
        MenuServiceAction.tag =>
          isEn ? 'Finder tag + comfy collar' : 'แท็กตามหาแมว + ปลอกคอใส่สบาย',
        MenuServiceAction.treats =>
          isEn
              ? 'Buy food & treats for cats you love'
              : 'ซื้ออาหารและขนม ส่งต่อให้แมวที่คุณชอบ',
        MenuServiceAction.memorial =>
          isEn ? 'Care for your cat’s memories' : 'ดูแลความทรงจำของน้อง',
        MenuServiceAction.memorialCremation =>
          isEn ? 'Find providers near you' : 'ค้นหาผู้ให้บริการใกล้คุณ',
        MenuServiceAction.memorialSite =>
          isEn ? 'Create an online memory page' : 'สร้างหน้าความทรงจำออนไลน์',
        MenuServiceAction.printCatId =>
          isEn
              ? 'Collar tag · Scan to contact owner'
              : 'ป้ายห้อยคอ สแกนแล้วติดต่อเจ้าของ',
        MenuServiceAction.pedigree => null,
        MenuServiceAction.insurance => null,
      };

  static String notifications(bool isEn) =>
      isEn ? 'Notifications' : 'การแจ้งเตือน';
  static String quietHours(bool isEn) => isEn ? 'Quiet hours' : 'โหมดเงียบ';
  static String quietHoursSubtitle(bool isEn) => isEn
      ? 'Mute 22:00–07:00 except emergencies'
      : 'ไม่แจ้งเตือน 22:00–07:00 ยกเว้นเรื่องฉุกเฉิน';
  static String tagDevices(bool isEn) =>
      isEn ? 'แมว.live Tag devices' : 'อุปกรณ์ แมว.live Tag';
  static String tagDevicesSubtitle(bool isEn) => isEn
      ? 'Battery · Sound · Pairing · Add tag'
      : 'แบตเตอรี่ · เสียง · การเชื่อมต่อ · เพิ่มแท็ก';
  static String postingRules(bool isEn) =>
      isEn ? 'Community posting rules' : 'กฎการโพสต์ในชุมชน';
  static String postingRulesSubtitle(bool isEn) => isEn
      ? 'Only partner brands may advertise cat food'
      : 'อาหารแมวโฆษณาได้เฉพาะแบรนด์พาร์ทเนอร์';
  static String privacy(bool isEn) => isEn ? 'Privacy' : 'ความเป็นส่วนตัว';
  static String privacySubtitle(bool isEn) =>
      isEn ? 'PDPA · Public Cat ID fields' : 'PDPA · ข้อมูลบน Cat ID สาธารณะ';
  static String helpContact(bool isEn) =>
      isEn ? 'Help & Contact' : 'ช่วยเหลือ & ติดต่อทีม';
  static String language(bool isEn) => isEn ? 'Language' : 'ภาษา';
  static String signOut(bool isEn) => isEn ? 'Sign out' : 'ออกจากระบบ';
  static String version(String ver, bool isEn) =>
      isEn ? 'แมว.live version $ver' : 'แมว.live เวอร์ชัน $ver';

  static String emptyTitle(bool isEn) =>
      isEn ? 'No menu items yet' : 'ยังไม่มีรายการเมนู';
  static String emptySubtitle(bool isEn) => isEn
      ? 'Tap retry to load services and settings'
      : 'แตะลองใหม่เพื่อโหลดบริการและการตั้งค่า';
  static String retry(bool isEn) => isEn ? 'Try again' : 'ลองใหม่';
  static String loadError(bool isEn) =>
      isEn ? 'Could not load menu' : 'โหลดเมนูไม่สำเร็จ';
}

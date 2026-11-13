/// ข้อความภาษาไทย / EN สำหรับหน้าเลี้ยงขนมแมว (/treats)
abstract final class TreatsL10n {
  static String pageTitle(bool en) => en ? 'Send Cat Treats' : 'เลี้ยงขนมแมว';
  static String backLabel(bool en) => en ? 'Back' : 'ย้อนกลับ';
  static String closeLabel(bool en) => en ? 'Close' : 'ปิด';

  static String whoTitle(bool en) =>
      en ? 'Which cat to send to?' : 'ส่งให้แมวตัวไหน';
  static String seeAll(bool en) => en ? 'See all' : 'ดูทั้งหมด';
  static String sheetTitle(bool en, int count) =>
      en ? 'Which cat to send to · $count' : 'ส่งให้แมวตัวไหน · $count';
  static String searchHint(bool en) =>
      en ? 'Search cat or account name' : 'ค้นหาชื่อแมวหรือบัญชี';
  static String searchEmpty(bool en) =>
      en ? 'No cats found' : 'ไม่พบแมวชื่อนี้';

  static String pickTitle(bool en) => en ? 'Choose treats' : 'เลือกขนม';
  static String drag360Hint(bool en) =>
      en ? 'Drag to rotate pack 360°' : 'ลากหมุนดูแพ็กได้ 360°';
  static String inCartBadge(bool en, int count) =>
      en ? 'In cart $count' : 'ในตะกร้า $count';
  static String decreaseQty(bool en) => en ? 'Decrease quantity' : 'ลดจำนวน';
  static String increaseQty(bool en) => en ? 'Increase quantity' : 'เพิ่มจำนวน';
  static String addToCart(bool en, String formattedPrice) =>
      en ? 'Add to cart · ฿$formattedPrice' : 'ใส่ตะกร้า · ฿$formattedPrice';
  static String removeItem(bool en, String name) =>
      en ? 'Remove $name' : 'เอา $name ออก';

  static String privacyNotice(bool en, String name) => en
      ? 'maew.live delivers directly to the address set by $name\'s owner. Addresses stay private and are never shown to you.'
      : 'แมว.live จะจัดส่งถึงที่อยู่ที่เจ้าของ$nameตั้งไว้โดยตรง ที่อยู่เป็นข้อมูลส่วนตัว คุณจะไม่เห็นที่อยู่ของเจ้าของ';

  static String messageLabel(bool en, String name) =>
      en ? 'Message to $name' : 'ข้อความถึง $name';
  static String messageHint(bool en) => en
      ? 'e.g. Love your videos, stay healthy! 🐾'
      : 'เช่น ชอบดูคลิปน้องมาก ขอให้แข็งแรงนะ 🐾';

  static String footerSummary(bool en, int count) =>
      en ? '$count items · Free shipping' : 'รวม $count ชิ้น · ส่งฟรี';
  static String sendTreatsTo(bool en, String name) =>
      en ? 'Send treats to $name' : 'ส่งขนมให้ $name';

  // หน้าชำระเงิน QR
  static String paymentTitle(bool en) => en ? 'Payment' : 'ชำระเงิน';
  static String paymentAmountLabel(bool en, int count) =>
      en ? 'Amount due · $count items' : 'ยอดชำระ · $count ชิ้น';
  static String regenerateQr(bool en) =>
      en ? 'Generate new QR' : 'สร้าง QR ใหม่';
  static String payeeLabel(bool en) => en ? 'Payee' : 'ผู้รับเงิน';
  static String expiresIn(bool en, String mm, String ss) =>
      en ? 'Expires in $mm:$ss' : 'หมดอายุใน $mm:$ss';
  static String qrExpired(bool en) => en ? 'QR expired' : 'QR หมดอายุแล้ว';
  static String scanHint(bool en) => en
      ? 'Screenshot QR and scan to pay in your banking app'
      : 'แคป QR แล้วสแกนจ่ายในแอปธนาคาร';
  static String paidCta(bool en) => en ? 'I have paid' : 'ชำระเงินแล้ว';

  // หน้าสำเร็จ
  static String successTitle(bool en, String name) =>
      en ? 'Treats sent to $name!' : 'ส่งขนมให้ $name แล้ว';
  static String successSubtitle(bool en, int count) => en
      ? 'The owner will be notified, and we will deliver $count treats within 2–3 days.'
      : 'เจ้าของจะได้รับแจ้งเตือน และเราจะจัดส่งขนม $count ชิ้นไปให้ภายใน 2–3 วัน';
  static String sendToAnother(bool en) =>
      en ? 'Send treats to another cat' : 'เลี้ยงขนมแมวตัวอื่น';
  static String backToPrevious(bool en, {required bool fromFeed}) => fromFeed
      ? (en ? 'Back to feed' : 'กลับไปที่ฟีด')
      : (en ? 'Back to previous page' : 'กลับหน้าก่อนหน้า');

  // สถานะโหลดพลาด / ว่าง
  static String loadError(bool en) =>
      en ? 'Could not load treats' : 'โหลดหน้าเลี้ยงขนมไม่สำเร็จ';
  static String emptyTitle(bool en) =>
      en ? 'No treats available right now' : 'ยังไม่มีรายการขนมในขณะนี้';
  static String emptySubtitle(bool en) =>
      en ? 'Please try again in a moment.' : 'ลองโหลดใหม่อีกครั้งในภายหลัง';
  static String retry(bool en) => en ? 'Try again' : 'ลองใหม่';
}

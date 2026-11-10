/// ค่าตั้งต้นของแอปที่ใช้ร่วมกันหลายฟีเจอร์
abstract final class AppConfig {
  /// โดเมนเว็บ (punycode ของ www.แมว.live) ใช้สร้างลิงก์โพสต์ที่แชร์ออกไป
  static const webOrigin = 'https://www.xn--y3cm0f.live';

  static String postUrl(String postId) => '$webOrigin/p/$postId';
}

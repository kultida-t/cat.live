/// กฎชุมชน: ห้ามโฆษณา/ขายอาหารแมวยกเว้นแบรนด์พาร์ทเนอร์ — ตรวจแบบคำสำคัญเบื้องต้น
/// (เหมือนเว็บ prototype: ต้องมีทั้งคำเกี่ยวกับอาหารแมว และคำเชิงขาย/โฆษณา)
/// การตรวจจริงต้องทำซ้ำที่ backend ด้วย ห้ามเชื่อแค่ฝั่งแอป
abstract final class FoodAdPolicy {
  static final _food = RegExp(
    r'อาหารแมว|อาหารเม็ด|อาหารเปียก|ขนมแมว|แคทฟู้ด|cat\s*food|kibble|ทูน่าแมว|ครีมแมวเลีย|แมวเลีย',
    caseSensitive: false,
  );
  static final _sell = RegExp(
    r'ขาย|ราคา|ลดราคา|โปร|ส่วนลด|โค้ด|สั่งซื้อ|สั่งได้|พรีออเดอร์|ส่งฟรี|inbox|ทักแชท|ไลน์|line|shopee|lazada|บาท|฿|sale|promo',
    caseSensitive: false,
  );

  static bool looksLikeCatFoodAd(String caption) =>
      _food.hasMatch(caption) && _sell.hasMatch(caption);
}

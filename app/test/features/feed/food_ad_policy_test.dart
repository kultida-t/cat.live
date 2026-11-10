import 'package:catlive/features/feed/domain/policies/food_ad_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('คำเกี่ยวกับอาหารแมว + คำขาย → เข้าข่ายโฆษณา', () {
    expect(
      FoodAdPolicy.looksLikeCatFoodAd('ขายอาหารแมว ลดราคา 99 บาท ทักไลน์'),
      isTrue,
    );
    expect(FoodAdPolicy.looksLikeCatFoodAd('Cat Food SALE ส่งฟรี'), isTrue);
  });

  test('พูดถึงอาหารแมวเฉย ๆ ไม่ใช่โฆษณา', () {
    expect(
      FoodAdPolicy.looksLikeCatFoodAd('น้องกินอาหารแมวหมดชามเลย'),
      isFalse,
    );
  });

  test('คำขายอย่างเดียวโดยไม่เกี่ยวอาหารแมว ผ่านได้', () {
    expect(FoodAdPolicy.looksLikeCatFoodAd('ขายบ้านแมว ราคา 500 บาท'), isFalse);
  });

  test('ข้อความธรรมดา ผ่าน', () {
    expect(
      FoodAdPolicy.looksLikeCatFoodAd(
        'ตื่นมาเจอนอนกอดตุ๊กตา วันหยุดที่ดีที่สุด',
      ),
      isFalse,
    );
  });
}

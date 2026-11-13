/// ทรงของแพ็กเกจขนมสำหรับพรีวิวหมุน 360 องศา
enum TreatPackShape { pouch, jar, box }

/// รายการขนมแมวสำหรับเลือกใส่ตะกร้า
class TreatItem {
  const TreatItem({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.shortName,
    required this.shortNameEn,
    required this.subLabel,
    required this.subLabelEn,
    required this.size,
    required this.sizeEn,
    required this.price,
    required this.packLabel,
    required this.packSize,
    required this.packColorHex,
    required this.packShape,
  });

  final String id;
  final String name;
  final String nameEn;
  final String shortName;
  final String shortNameEn;
  final String subLabel;
  final String subLabelEn;
  final String size;
  final String sizeEn;
  final int price;
  final String packLabel;
  final String packSize;
  final int packColorHex;
  final TreatPackShape packShape;
}

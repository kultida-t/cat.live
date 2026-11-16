/// ตัวเลือกสีของแท็กและปลอกคอ แมว.live Tag
class TagColorOption {
  const TagColorOption({
    required this.id,
    required this.nameTh,
    required this.nameEn,
    required this.colorValue,
  });

  final String id;
  final String nameTh;
  final String nameEn;
  final int colorValue;
}

/// แถวรายละเอียดสเปกสินค้า
class TagSpecItem {
  const TagSpecItem({
    required this.labelTh,
    required this.labelEn,
    required this.valueTh,
    required this.valueEn,
  });

  final String labelTh;
  final String labelEn;
  final String valueTh;
  final String valueEn;
}

/// ข้อมูลสินค้าและตัวเลือกสีทั้งหมดของหน้า แมว.live Tag (/tag)
class TagProductData {
  const TagProductData({
    required this.priceThb,
    required this.tagColors,
    required this.collarColors,
    required this.engraveColors,
    required this.specs,
  });

  final int priceThb;
  final List<TagColorOption> tagColors;
  final List<TagColorOption> collarColors;
  final List<TagColorOption> engraveColors;
  final List<TagSpecItem> specs;
}

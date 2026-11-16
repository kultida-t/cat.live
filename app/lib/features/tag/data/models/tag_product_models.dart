import '../../domain/entities/tag_product_data.dart';

/// แปลงข้อมูล JSON ของตัวเลือกสีจาก API เป็น Entity
class TagColorOptionDto {
  const TagColorOptionDto({
    required this.id,
    required this.nameTh,
    required this.nameEn,
    required this.colorValue,
  });

  final String id;
  final String nameTh;
  final String nameEn;
  final int colorValue;

  factory TagColorOptionDto.fromJson(Map<String, dynamic> json) {
    final hex = (json['hex'] as String? ?? '#328F87').replaceFirst('#', '');
    final parsed = int.tryParse(hex, radix: 16) ?? 0x328F87;
    return TagColorOptionDto(
      id: json['id'] as String? ?? '',
      nameTh: json['name_th'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? '',
      colorValue: hex.length == 6 ? (0xFF000000 | parsed) : parsed,
    );
  }

  TagColorOption toEntity() => TagColorOption(
    id: id,
    nameTh: nameTh,
    nameEn: nameEn,
    colorValue: colorValue,
  );
}

/// แปลงข้อมูล JSON ของหน้า แมว.live Tag จาก API เป็น Entity
class TagProductDto {
  const TagProductDto({
    required this.priceThb,
    required this.tagColors,
    required this.collarColors,
    required this.engraveColors,
    required this.specs,
  });

  final int priceThb;
  final List<TagColorOptionDto> tagColors;
  final List<TagColorOptionDto> collarColors;
  final List<TagColorOptionDto> engraveColors;
  final List<TagSpecItem> specs;

  factory TagProductDto.fromJson(Map<String, dynamic> json) {
    List<TagColorOptionDto> parseColors(String key) {
      final raw = json[key] as List<dynamic>? ?? const [];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(TagColorOptionDto.fromJson)
          .toList();
    }

    final rawSpecs = json['specs'] as List<dynamic>? ?? const [];
    final specs = rawSpecs.whereType<Map<String, dynamic>>().map((e) {
      return TagSpecItem(
        labelTh: e['label_th'] as String? ?? '',
        labelEn: e['label_en'] as String? ?? '',
        valueTh: e['value_th'] as String? ?? '',
        valueEn: e['value_en'] as String? ?? '',
      );
    }).toList();

    return TagProductDto(
      priceThb: (json['price_thb'] as num?)?.toInt() ?? 990,
      tagColors: parseColors('tag_colors'),
      collarColors: parseColors('collar_colors'),
      engraveColors: parseColors('engrave_colors'),
      specs: specs,
    );
  }

  TagProductData toEntity() => TagProductData(
    priceThb: priceThb,
    tagColors: tagColors.map((e) => e.toEntity()).toList(),
    collarColors: collarColors.map((e) => e.toEntity()).toList(),
    engraveColors: engraveColors.map((e) => e.toEntity()).toList(),
    specs: specs,
  );
}

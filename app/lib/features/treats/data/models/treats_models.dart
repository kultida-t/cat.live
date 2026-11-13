import '../../domain/entities/treat_item.dart';
import '../../domain/entities/treat_recipient.dart';
import '../../domain/entities/treats_data.dart';

class TreatRecipientModel {
  const TreatRecipientModel({
    required this.id,
    required this.handle,
    required this.name,
    required this.avatarUrl,
    required this.avatarBg,
    required this.hasCat,
  });

  final String id;
  final String handle;
  final String name;
  final String avatarUrl;
  final int avatarBg;
  final bool hasCat;

  factory TreatRecipientModel.fromJson(Map<String, dynamic> json) {
    return TreatRecipientModel(
      id: json['id'] as String? ?? '',
      handle: json['handle'] as String? ?? '',
      name: json['name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String? ?? '',
      avatarBg: json['avatar_bg'] as int? ?? 0xFFFCE7D6,
      hasCat: json['has_cat'] as bool? ?? false,
    );
  }

  TreatRecipient toEntity() => TreatRecipient(
    id: id,
    handle: handle,
    name: name,
    avatarUrl: avatarUrl,
    avatarBg: avatarBg,
    hasCat: hasCat,
  );
}

class TreatItemModel {
  const TreatItemModel({
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
  final String packShape;

  factory TreatItemModel.fromJson(Map<String, dynamic> json) {
    return TreatItemModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? '',
      shortName: json['short_name'] as String? ?? '',
      shortNameEn: json['short_name_en'] as String? ?? '',
      subLabel: json['sub_label'] as String? ?? '',
      subLabelEn: json['sub_label_en'] as String? ?? '',
      size: json['size'] as String? ?? '',
      sizeEn: json['size_en'] as String? ?? '',
      price: (json['price'] as num?)?.toInt() ?? 0,
      packLabel: json['pack_label'] as String? ?? '',
      packSize: json['pack_size'] as String? ?? '',
      packColorHex: json['pack_color_hex'] as int? ?? 0xFF76B9C8,
      packShape: json['pack_shape'] as String? ?? 'pouch',
    );
  }

  TreatItem toEntity() => TreatItem(
    id: id,
    name: name,
    nameEn: nameEn.isNotEmpty ? nameEn : name,
    shortName: shortName,
    shortNameEn: shortNameEn.isNotEmpty ? shortNameEn : shortName,
    subLabel: subLabel,
    subLabelEn: subLabelEn.isNotEmpty ? subLabelEn : subLabel,
    size: size,
    sizeEn: sizeEn.isNotEmpty ? sizeEn : size,
    price: price,
    packLabel: packLabel,
    packSize: packSize,
    packColorHex: packColorHex,
    packShape: switch (packShape) {
      'jar' => TreatPackShape.jar,
      'box' => TreatPackShape.box,
      _ => TreatPackShape.pouch,
    },
  );
}

class TreatsDataModel {
  const TreatsDataModel({required this.recipients, required this.treats});

  final List<TreatRecipientModel> recipients;
  final List<TreatItemModel> treats;

  factory TreatsDataModel.fromJson(Map<String, dynamic> json) {
    final rawRecipients = json['recipients'] as List<dynamic>? ?? const [];
    final rawTreats = json['treats'] as List<dynamic>? ?? const [];
    return TreatsDataModel(
      recipients: rawRecipients
          .whereType<Map<String, dynamic>>()
          .map(TreatRecipientModel.fromJson)
          .toList(),
      treats: rawTreats
          .whereType<Map<String, dynamic>>()
          .map(TreatItemModel.fromJson)
          .toList(),
    );
  }

  TreatsData toEntity() => TreatsData(
    recipients: recipients.map((r) => r.toEntity()).toList(),
    treats: treats.map((t) => t.toEntity()).toList(),
  );
}

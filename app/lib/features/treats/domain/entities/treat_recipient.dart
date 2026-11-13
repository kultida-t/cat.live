/// ผู้รับขนมแมว (บัญชี/แมวที่เลือกส่งขนมให้ได้)
class TreatRecipient {
  const TreatRecipient({
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
}

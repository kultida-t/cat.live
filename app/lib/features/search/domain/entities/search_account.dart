/// บัญชีผู้ใช้ที่แสดงในผลลัพธ์การค้นหา
class SearchAccount {
  const SearchAccount({
    required this.id,
    required this.handle,
    required this.name,
    required this.avatarUrl,
    required this.avatarBg,
  });

  final String id;
  final String handle;
  final String name;
  final String avatarUrl;
  final int avatarBg;

  String get displayName => name.isNotEmpty ? name : handle;
}

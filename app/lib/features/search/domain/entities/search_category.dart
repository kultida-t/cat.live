/// หมวดหมู่ในหน้าค้นหา — ตรงตามเว็บต้นแบบ www.แมว.live/search
enum SearchCategory {
  all('all'),
  daily('daily'),
  health('health'),
  learn('learn'),
  nearby('nearby'),
  rescue('rescue');

  const SearchCategory(this.id);

  final String id;

  static SearchCategory fromId(String raw) {
    return SearchCategory.values.firstWhere(
      (value) => value.id == raw,
      orElse: () => SearchCategory.all,
    );
  }
}

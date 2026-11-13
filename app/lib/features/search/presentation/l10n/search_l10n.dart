import '../../domain/entities/search_category.dart';

/// ข้อความ 2 ภาษา (ไทย / EN) สำหรับหน้าค้นหา (/search)
class SearchL10n {
  const SearchL10n(this.locale);

  final String locale;

  bool get isEn => locale == 'en';

  String get backLabel => isEn ? 'Back' : 'ย้อนกลับ';
  String get searchLabel => isEn ? 'Search' : 'ค้นหา';
  String get searchPlaceholder => isEn
      ? 'Search cats, people, or topics'
      : 'ค้นหาแมว คน หรือเรื่องที่สงสัย';
  String get clearSearchLabel => isEn ? 'Clear search' : 'ล้างคำค้นหา';

  String categoryLabel(SearchCategory category) {
    if (!isEn) {
      switch (category) {
        case SearchCategory.all:
          return 'ทั้งหมด';
        case SearchCategory.daily:
          return 'ชีวิตแมว';
        case SearchCategory.health:
          return 'สุขภาพ';
        case SearchCategory.learn:
          return 'ความรู้';
        case SearchCategory.nearby:
          return 'ใกล้ฉัน';
        case SearchCategory.rescue:
          return 'ช่วยแมว';
      }
    }
    switch (category) {
      case SearchCategory.all:
        return 'All';
      case SearchCategory.daily:
        return 'Cat Life';
      case SearchCategory.health:
        return 'Health';
      case SearchCategory.learn:
        return 'Knowledge';
      case SearchCategory.nearby:
        return 'Nearby';
      case SearchCategory.rescue:
        return 'Rescue';
    }
  }

  String postCategoryLabel(SearchCategory category, String fallbackThai) {
    if (!isEn) return fallbackThai;
    switch (category) {
      case SearchCategory.all:
        return 'All';
      case SearchCategory.daily:
        return 'Cat Life';
      case SearchCategory.health:
        return 'Q&A · Health';
      case SearchCategory.learn:
        return 'Knowledge';
      case SearchCategory.nearby:
        return 'Nearby';
      case SearchCategory.rescue:
        return 'Rescue';
    }
  }

  String get trendingTitle => isEn ? 'Trending searches' : 'คำค้นยอดนิยม';
  String get accountsTitle => isEn ? 'Accounts' : 'บัญชี';
  String get recommendedPosts => isEn ? 'Recommended posts' : 'โพสต์แนะนำ';
  String postsCount(int count) => isEn ? 'Posts ($count)' : 'โพสต์ ($count)';

  String emptyPrefix(String trimmedQuery) {
    if (isEn) {
      return trimmedQuery.isEmpty
          ? 'No posts found.\nTry another keyword or '
          : 'No results for “$trimmedQuery”\nTry another word or ';
    }
    return trimmedQuery.isEmpty
        ? 'ไม่พบโพสต์ในหมวดนี้\nลองเลือกหมวดอื่น หรือ '
        : 'ไม่พบผลลัพธ์สำหรับ “$trimmedQuery”\nลองใช้คำอื่น หรือ ';
  }

  String get askCatAi => isEn ? 'Ask Cat AI' : 'ถาม Cat AI';
}

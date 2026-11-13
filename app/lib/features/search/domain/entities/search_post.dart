import 'search_category.dart';

/// โพสต์แนะนำ / ผลลัพธ์โพสต์ในหน้าค้นหา
class SearchPost {
  const SearchPost({
    required this.id,
    required this.category,
    required this.categoryLabel,
    required this.caption,
    required this.authorName,
    required this.authorHandle,
    required this.timeText,
    required this.thumbnailUrl,
    required this.thumbnailAlt,
    this.place = '',
  });

  final String id;
  final SearchCategory category;
  final String categoryLabel;
  final String caption;
  final String authorName;
  final String authorHandle;
  final String timeText;
  final String thumbnailUrl;
  final String thumbnailAlt;
  final String place;
}

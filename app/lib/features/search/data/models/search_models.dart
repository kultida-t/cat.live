import '../../domain/entities/search_account.dart';
import '../../domain/entities/search_category.dart';
import '../../domain/entities/search_data.dart';
import '../../domain/entities/search_post.dart';

class SearchAccountModel {
  const SearchAccountModel({
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

  factory SearchAccountModel.fromJson(Map<String, dynamic> json) {
    return SearchAccountModel(
      id: json['id'] as String? ?? json['handle'] as String,
      handle: json['handle'] as String,
      name: json['name'] as String? ?? '',
      avatarUrl:
          json['avatar_url'] as String? ?? json['avatar'] as String? ?? '',
      avatarBg: json['avatar_bg'] as int? ?? 0xFFF6EFE6,
    );
  }

  SearchAccount toEntity() => SearchAccount(
    id: id,
    handle: handle,
    name: name,
    avatarUrl: avatarUrl,
    avatarBg: avatarBg,
  );
}

class SearchPostModel {
  const SearchPostModel({
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
  final String category;
  final String categoryLabel;
  final String caption;
  final String authorName;
  final String authorHandle;
  final String timeText;
  final String thumbnailUrl;
  final String thumbnailAlt;
  final String place;

  factory SearchPostModel.fromJson(Map<String, dynamic> json) {
    return SearchPostModel(
      id: json['id'] as String,
      category: json['category'] as String? ?? 'daily',
      categoryLabel: json['category_label'] as String? ?? '',
      caption: json['caption'] as String? ?? '',
      authorName: json['author_name'] as String? ?? '',
      authorHandle: json['author_handle'] as String? ?? '',
      timeText: json['time_text'] as String? ?? '',
      thumbnailUrl: json['thumbnail_url'] as String? ?? '',
      thumbnailAlt: json['thumbnail_alt'] as String? ?? '',
      place: json['place'] as String? ?? '',
    );
  }

  SearchPost toEntity() => SearchPost(
    id: id,
    category: SearchCategory.fromId(category),
    categoryLabel: categoryLabel,
    caption: caption,
    authorName: authorName,
    authorHandle: authorHandle,
    timeText: timeText,
    thumbnailUrl: thumbnailUrl,
    thumbnailAlt: thumbnailAlt,
    place: place,
  );
}

class SearchDataModel {
  const SearchDataModel({
    required this.trendingKeywords,
    required this.accounts,
    required this.posts,
  });

  final List<String> trendingKeywords;
  final List<SearchAccountModel> accounts;
  final List<SearchPostModel> posts;

  factory SearchDataModel.fromJson(Map<String, dynamic> json) {
    return SearchDataModel(
      trendingKeywords: ((json['trending_keywords'] as List?) ?? const [])
          .cast<String>(),
      accounts: ((json['accounts'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(SearchAccountModel.fromJson)
          .toList(),
      posts: ((json['posts'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(SearchPostModel.fromJson)
          .toList(),
    );
  }

  SearchData toEntity() => SearchData(
    trendingKeywords: trendingKeywords,
    accounts: accounts.map((a) => a.toEntity()).toList(),
    posts: posts.map((p) => p.toEntity()).toList(),
  );
}

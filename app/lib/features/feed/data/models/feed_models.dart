import '../../domain/entities/feed_user.dart';
import '../../domain/entities/post.dart';

/// DTO ที่ตรงกับ JSON จาก API — แปลงเป็น entity ของ domain ที่นี่ที่เดียว
/// (รูปแบบ JSON อ้างอิง docs/data-schema.md ตาราง posts/comments/likes/saves/follows)

class FeedUserModel {
  const FeedUserModel({
    required this.id,
    required this.handle,
    required this.avatarUrl,
    required this.avatarBg,
    required this.hasUnseenStory,
  });

  factory FeedUserModel.fromJson(Map<String, dynamic> json) => FeedUserModel(
    id: json['id'] as String,
    handle: json['handle'] as String,
    avatarUrl: json['avatar_url'] as String,
    avatarBg: json['avatar_bg'] as int,
    hasUnseenStory: json['has_unseen_story'] as bool? ?? false,
  );

  final String id;
  final String handle;
  final String avatarUrl;
  final int avatarBg;
  final bool hasUnseenStory;

  FeedUser toEntity() => FeedUser(
    id: id,
    handle: handle,
    avatar: avatarUrl,
    avatarBg: avatarBg,
    hasUnseenStory: hasUnseenStory,
  );
}

class PostModel {
  const PostModel({required this.json});

  factory PostModel.fromJson(Map<String, dynamic> json) =>
      PostModel(json: json);

  final Map<String, dynamic> json;

  Post toEntity() {
    final likedBy = json['liked_by'] as Map<String, dynamic>;
    return Post(
      id: json['id'] as String,
      type: json['type'] == 'lost_cat' ? PostType.lostCat : PostType.normal,
      author: FeedUserModel.fromJson(json['author'] as Map<String, dynamic>)
          .toEntity(),
      subtitle: json['subtitle'] as String?,
      subtitleHasPin: json['subtitle_has_pin'] as bool? ?? false,
      caption: json['caption'] as String,
      media: (json['media'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(
            (m) => PostMedia(
              url: m['url'] as String,
              alt: m['alt'] as String? ?? '',
              isVideo: m['kind'] == 'video',
            ),
          )
          .toList(),
      likeCount: json['like_count'] as int,
      commentCount: json['comment_count'] as int,
      shareCount: json['share_count'] as int? ?? 0,
      likedBy: LikedBy(
        handle: likedBy['handle'] as String,
        avatars: (likedBy['avatars'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map((a) => (url: a['url'] as String, bg: a['bg'] as int))
            .toList(),
      ),
      previewComments: (json['preview_comments'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(
            (c) => CommentPreview(
              authorHandle: c['author_handle'] as String,
              body: c['body'] as String,
            ),
          )
          .toList(),
      postedAgoText: json['posted_ago_text'] as String,
      isFollowingAuthor: json['is_following_author'] as bool? ?? false,
      isLiked: json['is_liked'] as bool? ?? false,
      isSaved: json['is_saved'] as bool? ?? false,
      isOwn: json['is_own'] as bool? ?? false,
    );
  }
}

class FeedPageModel {
  const FeedPageModel({required this.posts, this.nextCursor});

  factory FeedPageModel.fromJson(Map<String, dynamic> json) => FeedPageModel(
    posts: (json['posts'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(PostModel.fromJson)
        .toList(),
    nextCursor: json['next_cursor'] as int?,
  );

  final List<PostModel> posts;
  final int? nextCursor;

  FeedPage toEntity() => FeedPage(
    posts: posts.map((p) => p.toEntity()).toList(),
    nextCursor: nextCursor,
  );
}

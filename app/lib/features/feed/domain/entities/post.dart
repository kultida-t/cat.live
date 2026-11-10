import 'package:equatable/equatable.dart';

import 'feed_user.dart';

enum PostType { normal, lostCat }

class PostMedia extends Equatable {
  const PostMedia({required this.url, required this.alt, this.isVideo = false});

  final String url;
  final String alt;
  final bool isVideo;

  @override
  List<Object?> get props => [url, alt, isVideo];
}

class CommentPreview extends Equatable {
  const CommentPreview({required this.authorHandle, required this.body});

  final String authorHandle;
  final String body;

  @override
  List<Object?> get props => [authorHandle, body];
}

class LikedBy extends Equatable {
  const LikedBy({required this.handle, required this.avatars});

  final String handle;
  final List<({String url, int bg})> avatars;

  @override
  List<Object?> get props => [handle, avatars];
}

class Post extends Equatable {
  const Post({
    required this.id,
    required this.type,
    required this.author,
    required this.caption,
    required this.media,
    required this.likeCount,
    required this.commentCount,
    required this.shareCount,
    required this.likedBy,
    required this.previewComments,
    required this.postedAgoText,
    required this.isFollowingAuthor,
    required this.isLiked,
    required this.isSaved,
    required this.isOwn,
    this.subtitle,
    this.subtitleHasPin = false,
  });

  final String id;
  final PostType type;
  final FeedUser author;
  final String? subtitle;
  final bool subtitleHasPin;
  final String caption;
  final List<PostMedia> media;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final LikedBy likedBy;
  final List<CommentPreview> previewComments;
  final String postedAgoText;
  final bool isFollowingAuthor;
  final bool isLiked;
  final bool isSaved;
  final bool isOwn;

  Post copyWith({
    int? likeCount,
    bool? isFollowingAuthor,
    bool? isLiked,
    bool? isSaved,
  }) {
    return Post(
      id: id,
      type: type,
      author: author,
      subtitle: subtitle,
      subtitleHasPin: subtitleHasPin,
      caption: caption,
      media: media,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount,
      shareCount: shareCount,
      likedBy: likedBy,
      previewComments: previewComments,
      postedAgoText: postedAgoText,
      isFollowingAuthor: isFollowingAuthor ?? this.isFollowingAuthor,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      isOwn: isOwn,
    );
  }

  @override
  List<Object?> get props => [
    id,
    type,
    author,
    subtitle,
    subtitleHasPin,
    caption,
    media,
    likeCount,
    commentCount,
    shareCount,
    likedBy,
    previewComments,
    postedAgoText,
    isFollowingAuthor,
    isLiked,
    isSaved,
    isOwn,
  ];
}

class FeedPage extends Equatable {
  const FeedPage({required this.posts, this.nextCursor});

  final List<Post> posts;
  final int? nextCursor;

  @override
  List<Object?> get props => [posts, nextCursor];
}

import 'package:equatable/equatable.dart';

import 'feed_user.dart';

class Comment extends Equatable {
  const Comment({
    required this.id,
    required this.author,
    required this.text,
    required this.timeText,
    required this.likeCount,
    required this.isLiked,
    this.replyToHandle,
  });

  final String id;
  final FeedUser author;
  final String text;

  /// เวลาแบบอ่านง่ายจากเซิร์ฟเวอร์ เช่น "2 ชม." / "เมื่อสักครู่"
  final String timeText;
  final int likeCount;
  final bool isLiked;
  final String? replyToHandle;

  Comment copyWith({int? likeCount, bool? isLiked}) => Comment(
    id: id,
    author: author,
    text: text,
    timeText: timeText,
    likeCount: likeCount ?? this.likeCount,
    isLiked: isLiked ?? this.isLiked,
    replyToHandle: replyToHandle,
  );

  @override
  List<Object?> get props => [
    id,
    author,
    text,
    timeText,
    likeCount,
    isLiked,
    replyToHandle,
  ];
}

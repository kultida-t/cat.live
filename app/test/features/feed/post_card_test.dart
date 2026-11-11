import 'package:catlive/features/feed/domain/entities/feed_user.dart';
import 'package:catlive/features/feed/domain/entities/post.dart';
import 'package:catlive/features/feed/presentation/widgets/post_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PostCard แสดงยอดแชร์จาก shareCount โดยไม่คำนวณจากยอดถูกใจ', (
    tester,
  ) async {
    const post = Post(
      id: 'p-share',
      type: PostType.normal,
      categoryLabel: 'ชีวิตแมว',
      author: FeedUser(
        id: 'noon',
        handle: 'noon.mochi',
        avatar: 'asset:assets/images/avatars/1592194996308-7b43878e84a6.jpg',
        avatarBg: 0xFFFCE7D6,
        hasUnseenStory: true,
      ),
      caption: 'ทดสอบยอดแชร์',
      media: [
        PostMedia(
          url: 'asset:assets/images/posts/1759588032622-1388cf9505ad.jpg',
          alt: 'แมวส้ม',
        ),
      ],
      likeCount: 500,
      commentCount: 24,
      shareCount: 7,
      likedBy: LikedBy(handle: 'tonkla_meow', avatars: []),
      previewComments: [],
      postedAgoText: '2 ชม.ที่แล้ว',
      isFollowingAuthor: true,
      isLiked: false,
      isSaved: false,
      isOwn: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PostCard(
              post: post,
              onToggleLike: (_) {},
              onToggleSave: (_) {},
              onToggleFollow: (_) {},
              onOpenMenu: (_) {},
              onOpenComments: (_) {},
              onShare: (_) {},
              onComingSoon: (_) {},
            ),
          ),
        ),
      ),
    );

    // 500 * 0.02 = 10 แต่ต้องแสดง 7 ตามค่า shareCount จริง
    expect(find.text('7'), findsOneWidget);
    expect(find.text('10'), findsNothing);
  });
}

import 'package:catlive/features/feed/data/datasources/mock_feed_data_source.dart';
import 'package:catlive/features/feed/data/models/feed_models.dart';
import 'package:catlive/features/feed/domain/entities/feed_tab.dart';
import 'package:catlive/features/feed/domain/entities/post.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'แปลง JSON จาก API เป็น Post — ฟิลด์ครบและค่า default ของฟิลด์ที่ไม่ส่งมา',
    () {
      final post = PostModel.fromJson({
        'id': 'x1',
        'type': 'lost_cat',
        'author': {
          'id': 'u',
          'handle': 'a.b',
          'avatar_url': 'https://img/a.jpg',
          'avatar_bg': 0xFFFFFFFF,
        },
        'caption': 'หาแมว',
        'media': [
          {'url': 'https://img/1.jpg', 'alt': 'รูป', 'kind': 'video'},
        ],
        'like_count': 1,
        'comment_count': 2,
        'liked_by': {'handle': 'z', 'avatars': <Map<String, dynamic>>[]},
        'posted_ago_text': 'เมื่อกี้',
      }).toEntity();

      expect(post.type, PostType.lostCat);
      expect(post.media.single.isVideo, isTrue);
      expect(post.shareCount, 0);
      expect(post.previewComments, isEmpty);
      expect(post.isLiked, isFalse);
      expect(post.author.hasUnseenStory, isFalse);
    },
  );

  test(
    'ข้อมูล mock แบ่งหน้า — limit 2 ได้ 3 หน้า และหน้าสุดท้ายไม่มี cursor ต่อ',
    () async {
      final source = MockFeedDataSource(latency: Duration.zero);

      final p1 = await source.fetchPosts(tab: FeedTab.all, cursor: 0, limit: 2);
      final p2 = await source.fetchPosts(
        tab: FeedTab.all,
        cursor: p1.nextCursor!,
        limit: 2,
      );
      final p3 = await source.fetchPosts(
        tab: FeedTab.all,
        cursor: p2.nextCursor!,
        limit: 2,
      );

      expect([p1.posts.length, p2.posts.length, p3.posts.length], [2, 2, 1]);
      expect(p3.nextCursor, isNull);
    },
  );

  test(
    'โพสต์ในฟีดและ mock แสดงรูปได้ไม่เกิน 3 รูปตามเงื่อนไขการอัปโหลด',
    () async {
      final capped = PostModel.fromJson({
        'id': 'x2',
        'type': 'normal',
        'author': {
          'id': 'u',
          'handle': 'a.b',
          'avatar_url': 'https://img/a.jpg',
          'avatar_bg': 0xFFFFFFFF,
        },
        'caption': 'หลายรูป',
        'media': [
          for (var i = 1; i <= 5; i++)
            {'url': 'https://img/$i.jpg', 'alt': 'r$i'},
        ],
        'like_count': 0,
        'comment_count': 0,
        'liked_by': {'handle': 'z', 'avatars': <Map<String, dynamic>>[]},
        'posted_ago_text': 'เมื่อกี้',
      }).toEntity();
      expect(capped.media.length, 3);

      final source = MockFeedDataSource(latency: Duration.zero);
      final page = await source.fetchPosts(
        tab: FeedTab.all,
        cursor: 0,
        limit: 5,
      );
      for (final post in page.posts) {
        expect(post.toEntity().media.length, lessThanOrEqualTo(3));
      }
    },
  );
}

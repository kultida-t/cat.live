import '../../../../core/error/failure.dart';
import '../../domain/entities/feed_tab.dart';
import '../../domain/entities/new_post.dart';
import '../models/feed_models.dart';
import 'feed_remote_data_source.dart';
import 'mock_accounts.dart';

const _avatarDir = 'asset:assets/images/avatars';
const _postDir = 'asset:assets/images/posts';

Map<String, dynamic> _media(String photo, String alt) => {
  'url': '$_postDir/$photo.jpg',
  'alt': alt,
  'kind': 'image',
};

Map<String, dynamic> _likeAvatar(String photo, int bg) => {
  'url': '$_avatarDir/$photo.jpg',
  'bg': bg,
};

final _noon = mockAccountJson('noon');
final _vet = mockAccountJson('vet');
final _muk = mockAccountJson('muk');
final _rescue = mockAccountJson('rescue');
final _guy = mockAccountJson('guy');

final _likedFirst = [
  _likeAvatar('1533738363-b7f9aef128ce', 0xFFEAF3FF),
  _likeAvatar('1511044568932-338cba0ad803', 0xFFFFF1E6),
  _likeAvatar('1787404200329-78b2aaee13c1', 0xFFD5F0EB),
];
final _likedSecond = [
  _likeAvatar('1543852786-1cf6624b9987', 0xFFEDE4FB),
  _likeAvatar('1533738363-b7f9aef128ce', 0xFFEAF3FF),
  _likeAvatar('1511044568932-338cba0ad803', 0xFFFFF1E6),
];

/// ข้อมูลตัวอย่างชุดเดียวกับเว็บ prototype (www.แมว.live) ในรูป JSON เดียวกับที่ API จะส่ง
List<Map<String, dynamic>> _seedPosts() => [
  {
    'id': 'p1',
    'type': 'normal',
    'category_label': 'ชีวิตแมว',
    'author': _noon,
    'subtitle': 'กับน้องโมจิ',
    'subtitle_has_pin': true,
    'caption': 'ตื่นมาเจอนอนกอดตุ๊กตาแบบนี้ วันหยุดที่ดีที่สุดแล้ว 🧸',
    'media': [
      _media('1759588032622-1388cf9505ad', 'แมวส้มนอนหลับบนเตียง'),
      _media('1764708844823-00d2188dafd8', 'แมวขนฟูนั่งริมหน้าต่าง'),
      _media('1511044568932-338cba0ad803', 'แมวเปอร์เซียหลับ'),
    ],
    'like_count': 128,
    'comment_count': 24,
    'share_count': 3,
    'liked_by': {'handle': 'tonkla_meow', 'avatars': _likedFirst},
    'preview_comments': [
      {'author_handle': 'somjeed.daily', 'body': 'น่ารักมากกก ขอกอดด้วย'},
    ],
    'posted_ago_text': '30 นาทีที่แล้ว',
    'is_following_author': true,
    'is_liked': true,
    'is_saved': false,
    'is_own': false,
  },
  {
    'id': 'p2',
    'type': 'normal',
    'category_label': 'ความรู้',
    'author': _vet,
    'subtitle': 'ความรู้',
    'subtitle_has_pin': false,
    'caption': 'แมวควรกินน้ำวันละเท่าไหร่? ประมาณ 40–60 มล. ต่อน้ำหนักตัว 1 กก. ปัดดูวิธีสังเกตว่าน้องดื่มน้อยเกินไป 👉',
    'media': [
      _media('1478098711619-5ab0b478d6e6', 'แมวลายสลิดระยะใกล้'),
      _media('1574144611937-0df059b5ef3e', 'ลูกแมวลายสลิดสีเงิน'),
      _media('1533738363-b7f9aef128ce', 'แมวรัสเซียนบลูใส่แว่นกันแดด'),
    ],
    'like_count': 542,
    'comment_count': 61,
    'share_count': 11,
    'liked_by': {'handle': 'tonkla_meow', 'avatars': _likedFirst},
    'preview_comments': <Map<String, dynamic>>[],
    'posted_ago_text': '1 ชม.ที่แล้ว',
    'is_following_author': true,
    'is_liked': false,
    'is_saved': true,
    'is_own': false,
  },
  {
    'id': 'p3',
    'type': 'normal',
    'category_label': 'คำถาม · สุขภาพ',
    'author': _guy,
    'subtitle': 'คำถาม · สุขภาพ',
    'subtitle_has_pin': false,
    'caption': 'แมวอายุ 12 ปี กินน้ำเยอะขึ้นกว่าปกติ ควรพาไปตรวจอะไรบ้างครับ',
    'media': [
      _media('1514888286974-6c03e2ca1dba', 'แมวขาวดำนอนบนเก้าอี้ไม้ไผ่'),
    ],
    'like_count': 16,
    'comment_count': 8,
    'share_count': 0,
    'liked_by': {'handle': 'maew.vetnote', 'avatars': _likedSecond},
    'preview_comments': [
      {
        'author_handle': 'maew.vetnote',
        'body': 'ลองให้หมอตรวจเลือดดูค่าไตกับน้ำตาลค่ะ',
      },
    ],
    'posted_ago_text': '2 ชม.ที่แล้ว',
    'is_following_author': false,
    'is_liked': false,
    'is_saved': false,
    'is_own': false,
  },
  {
    'id': 'p4',
    'type': 'normal',
    'category_label': 'ใกล้ฉัน',
    'author': _muk,
    'subtitle': 'อารีย์ · ห่างจากคุณ 900 ม.',
    'subtitle_has_pin': true,
    'caption':
        'คาเฟ่แถวอารีย์เปิดโซนให้พาแมวมาได้แล้ว มีที่นั่งแยกเงียบ ๆ ด้วย',
    'media': [
      _media('1495360010541-f48722b34f7d', 'แมวลายสลิดบนบันได'),
      _media('1765714714461-174be7eaad85', 'แมวส้มนั่งบนระเบียงไม้'),
    ],
    'like_count': 87,
    'comment_count': 12,
    'share_count': 2,
    'liked_by': {'handle': 'maew.vetnote', 'avatars': _likedSecond},
    'preview_comments': <Map<String, dynamic>>[],
    'posted_ago_text': '4 ชม.ที่แล้ว',
    'is_following_author': false,
    'is_liked': false,
    'is_saved': true,
    'is_own': false,
  },
  {
    'id': 'p5',
    'type': 'normal',
    'category_label': 'ช่วยแมว',
    'author': _rescue,
    'subtitle': 'ลาดพร้าว 71',
    'subtitle_has_pin': true,
    'caption': 'พบลูกแมว 3 ตัวหลังตลาด ต้องการบ้านอุปการะชั่วคราว ใครสะดวกทักมาได้เลยค่ะ 🙏',
    'media': [
      _media('1561948955-570b270e7c36', 'ลูกแมวสีขาว'),
      _media('1774876267601-501fa7d17ac7', 'แมวโผล่จากรูกล่องกระดาษ'),
      _media('1573865526739-10659fec78a5', 'แมวส้มขาว'),
    ],
    'like_count': 233,
    'comment_count': 45,
    'share_count': 5,
    'liked_by': {'handle': 'maew.vetnote', 'avatars': _likedSecond},
    'preview_comments': <Map<String, dynamic>>[],
    'posted_ago_text': '5 ชม.ที่แล้ว',
    'is_following_author': true,
    'is_liked': false,
    'is_saved': false,
    'is_own': false,
  },
];

/// ทะเบียนบัญชีทั้งหมด + สถานะติดตามเริ่มต้น — ตรงกับเว็บ prototype
List<Map<String, dynamic>> _seedAccounts() => [
  for (final key in mockAccountKeys)
    {
      ...mockAccountJson(key),
      'is_following': mockInitialFollowing.contains(key),
    },
];

const _commentTemplates = [
  ('noon', 'น่ารักมากกก 🥹', '2 ชม.', 12),
  (
    'vet',
    'ถ้ามีอาการซึมหรือไม่กินข้าวเกิน 24 ชม. แนะนำให้พาไปหาหมอนะคะ',
    '1 ชม.',
    34,
  ),
  ('pim', 'บ้านเราก็เป็นแบบนี้เลยค่ะ 555', '45 นาที', 3),
  ('tonkla', 'ขอบคุณที่แชร์ครับ มีประโยชน์มาก', '30 นาที', 5),
  ('nat', 'แวะมาที่ร้านได้นะคะ มีมุมให้น้องแมวพักด้วย', '12 นาที', 1),
];

/// ข้อมูล mock ในหน่วยความจำ — ใช้ช่วงยังไม่มี backend (ตามแนวทาง "ทำหน้าจอให้เห็นก่อน")
class MockFeedDataSource implements FeedRemoteDataSource {
  MockFeedDataSource({this.latency = const Duration(milliseconds: 400)})
    : _posts = _seedPosts(),
      _accounts = _seedAccounts() {
    // ให้ยอด comment_count บนการ์ดตรงกับจำนวนคอมเมนต์จริงที่เปิดดูในชีตเสมอ
    for (final p in _posts) {
      final id = p['id'] as String;
      p['comment_count'] = _commentsOf(id).length;
    }
  }

  final Duration latency;
  List<Map<String, dynamic>> _posts;
  final List<Map<String, dynamic>> _accounts;
  final _hiddenIds = <String>{};
  final _hiddenAccountIds = <String>{};
  final _comments = <String, List<Map<String, dynamic>>>{};
  var _sequence = 0;

  Future<void> _delay() => Future<void>.delayed(latency);

  @override
  Future<FeedPageModel> fetchPosts({
    required FeedTab tab,
    required int cursor,
    required int limit,
  }) async {
    await _delay();
    final filtered = _posts.where((p) {
      if (_hiddenIds.contains(p['id'])) return false;
      final authorId = (p['author'] as Map<String, dynamic>)['id'];
      if (_hiddenAccountIds.contains(authorId)) return false;
      return switch (tab) {
        FeedTab.all => true,
        FeedTab.following => p['is_following_author'] == true,
        FeedTab.saved => p['is_saved'] == true,
      };
    }).toList();
    final page = filtered
        .skip(cursor)
        .take(limit)
        .map(PostModel.fromJson)
        .toList();
    final next = cursor + limit < filtered.length ? cursor + limit : null;
    return FeedPageModel(posts: page, nextCursor: next);
  }

  @override
  Future<List<FeedUserModel>> fetchStoryUsers() async {
    await _delay();
    return [
      mockAccountJson('noon'),
      mockAccountJson('vet'),
      mockAccountJson('muk'),
      mockAccountJson('rescue'),
      mockAccountJson('som', unseen: false),
      mockAccountJson('guy', unseen: false),
    ].map(FeedUserModel.fromJson).toList();
  }

  @override
  Future<List<FeedUserModel>> fetchAccounts() async {
    await _delay();
    return _accounts.map(FeedUserModel.fromJson).toList();
  }

  @override
  Future<PostModel> toggleLike(String postId) async {
    await _delay();
    final post = _find(postId);
    final liked = !(post['is_liked'] as bool);
    post['is_liked'] = liked;
    post['like_count'] = (post['like_count'] as int) + (liked ? 1 : -1);
    return PostModel.fromJson(post);
  }

  @override
  Future<PostModel> toggleSave(String postId) async {
    await _delay();
    final post = _find(postId);
    post['is_saved'] = !(post['is_saved'] as bool);
    return PostModel.fromJson(post);
  }

  @override
  Future<void> toggleFollow(String userId) async {
    await _delay();
    for (final a in _accounts) {
      if (a['id'] == userId) {
        a['is_following'] = !(a['is_following'] as bool);
      }
    }
    for (final p in _posts) {
      if ((p['author'] as Map<String, dynamic>)['id'] == userId) {
        p['is_following_author'] = !(p['is_following_author'] as bool);
      }
    }
  }

  @override
  Future<void> hidePost(String postId) async {
    await _delay();
    _hiddenIds.add(postId);
  }

  @override
  Future<void> hideAccountPosts(String userId) async {
    await _delay();
    _hiddenAccountIds.add(userId);
  }

  @override
  Future<void> reportPost(String postId, String reason) => _delay();

  @override
  Future<void> deletePost(String postId) async {
    await _delay();
    _posts = _posts.where((p) => p['id'] != postId).toList();
  }

  @override
  Future<PostModel> fetchPost(String postId) async {
    await _delay();
    final post = _posts.where((p) => p['id'] == postId).firstOrNull;
    if (post == null) throw const NotFoundFailure('ไม่พบโพสต์นี้');
    return PostModel.fromJson(post);
  }

  @override
  Future<PostModel> createPost(NewPost draft) async {
    await _delay();
    final post = <String, dynamic>{
      'id': 'new-${++_sequence}-${DateTime.now().millisecondsSinceEpoch}',
      'type': 'normal',
      'category_label': 'ชีวิตแมว',
      'author': mockAccountJson(mockMe),
      'subtitle': 'ชีวิตแมว',
      'subtitle_has_pin': false,
      'caption': draft.caption,
      'media': [
        for (final m in draft.media)
          {
            'url': m.source,
            'alt': m.name,
            'kind': m.isVideo ? 'video' : 'image',
            'seconds': m.seconds,
          },
      ],
      'like_count': 0,
      'comment_count': 0,
      'share_count': 0,
      'liked_by': {'handle': '', 'avatars': <Map<String, dynamic>>[]},
      'preview_comments': <Map<String, dynamic>>[],
      'posted_ago_text': 'เมื่อสักครู่',
      'is_following_author': true,
      'is_liked': false,
      'is_saved': false,
      'is_own': true,
    };
    _posts = [post, ..._posts];
    return PostModel.fromJson(post);
  }

  /// คอมเมนต์ตัวอย่างสร้างตามสูตร: คอมเมนต์เด่นของโพสต์ก่อน แล้วตามด้วยคอมเมนต์ของบัญชีอื่น
  List<Map<String, dynamic>> _seedComments(Map<String, dynamic> post) {
    final id = post['id'] as String;
    final authorKey = (post['author'] as Map<String, dynamic>)['id'] as String;
    final preview = (post['preview_comments'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final count = (id == 'p1' || id == 'p2' || id == 'p5') ? 5 : 3;
    Map<String, dynamic> comment(
      String idSuffix,
      String account,
      String text,
      String time,
      int likes,
    ) => {
      'id': '$id-$idSuffix',
      'author': mockAccountJson(account),
      'text': text,
      'time_text': time,
      'like_count': likes,
      'is_liked': false,
    };
    return [
      if (preview.isNotEmpty)
        comment(
          'top',
          mockKeyOfHandle(preview.first['author_handle'] as String),
          preview.first['body'] as String,
          '3 ชม.',
          18,
        ),
      for (final (i, t)
          in _commentTemplates
              .where((t) => t.$1 != authorKey)
              .take(count)
              .indexed)
        comment('$i', t.$1, t.$2, t.$3, t.$4),
    ];
  }

  List<Map<String, dynamic>> _commentsOf(String postId) =>
      _comments.putIfAbsent(postId, () => _seedComments(_find(postId)));

  @override
  Future<List<CommentModel>> fetchComments(String postId) async {
    await _delay();
    return _commentsOf(postId).map(CommentModel.fromJson).toList();
  }

  @override
  Future<CommentModel> addComment(
    String postId,
    String text, {
    String? replyToHandle,
  }) async {
    await _delay();
    final post = _find(postId);
    final comment = <String, dynamic>{
      'id': 'c-${++_sequence}',
      'author': mockAccountJson(mockMe),
      'text': text,
      'time_text': 'เมื่อสักครู่',
      'like_count': 0,
      'is_liked': false,
      'reply_to_handle': replyToHandle,
    };
    _commentsOf(postId).add(comment);
    post['comment_count'] = (post['comment_count'] as int) + 1;
    return CommentModel.fromJson(comment);
  }

  @override
  Future<CommentModel> toggleCommentLike(
    String postId,
    String commentId,
  ) async {
    await _delay();
    final comment = _commentsOf(postId).firstWhere(
      (c) => c['id'] == commentId,
      orElse: () => throw const NotFoundFailure('ไม่พบความคิดเห็นนี้'),
    );
    final liked = !(comment['is_liked'] as bool);
    comment['is_liked'] = liked;
    comment['like_count'] = (comment['like_count'] as int) + (liked ? 1 : -1);
    return CommentModel.fromJson(comment);
  }

  Map<String, dynamic> _find(String postId) => _posts.firstWhere(
    (p) => p['id'] == postId,
    orElse: () => throw StateError('ไม่พบโพสต์ $postId'),
  );
}

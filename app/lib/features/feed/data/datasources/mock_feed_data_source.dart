import '../../domain/entities/feed_tab.dart';
import '../models/feed_models.dart';
import 'feed_remote_data_source.dart';

const _avatarDir = 'asset:assets/images/avatars';
const _postDir = 'asset:assets/images/posts';

Map<String, dynamic> _user(
  String id,
  String handle,
  String photo,
  int bg, {
  bool unseen = true,
}) => {
  'id': id,
  'handle': handle,
  'avatar_url': '$_avatarDir/$photo.jpg',
  'avatar_bg': bg,
  'has_unseen_story': unseen,
};

Map<String, dynamic> _media(String photo, String alt) => {
  'url': '$_postDir/$photo.jpg',
  'alt': alt,
  'kind': 'image',
};

Map<String, dynamic> _likeAvatar(String photo, int bg) => {
  'url': '$_avatarDir/$photo.jpg',
  'bg': bg,
};

final _noon = _user(
  'u1',
  'noon.mochi',
  '1592194996308-7b43878e84a6',
  0xFFFCE7D6,
);
final _vet = _user('u2', 'maew.vetnote', '1543852786-1cf6624b9987', 0xFFEDE4FB);
final _muk = _user('u3', 'muk.ari', '1787404200329-78b2aaee13c1', 0xFFD5F0EB);
final _rescue = _user(
  'u4',
  'rescue.bkk',
  '1503777119540-ce54b422baff',
  0xFFFDE2EC,
);
final _somjeed = _user(
  'u5',
  'somjeed.daily',
  '1596854407944-bf87f6fdd49e',
  0xFFFFF1C9,
  unseen: false,
);
final _guy = _user(
  'u6',
  'guy.oldcat',
  '1574158622682-e40e69881006',
  0xFFDCEBFF,
  unseen: false,
);

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
    'author': _noon,
    'subtitle': 'กับน้องโมจิ',
    'subtitle_has_pin': true,
    'caption': 'ตื่นมาเจอนอนกอดตุ๊กตาแบบนี้ วันหยุดที่ดีที่สุดแล้ว 🧸',
    'media': [
      _media('1759588032622-1388cf9505ad', 'แมวส้มนอนหลับบนเตียง'),
      _media('1764708844823-00d2188dafd8', 'แมวขนฟูนั่งริมหน้าต่าง'),
      _media('1511044568932-338cba0ad803', 'แมวเปอร์เซียหลับ'),
      _media('1571566882372-1598d88abd90', 'แมวส้มบิดขี้เกียจ'),
    ],
    'like_count': 128,
    'comment_count': 24,
    'share_count': 3,
    'liked_by': {'handle': 'tonkla_meow', 'avatars': _likedFirst},
    'preview_comments': [
      {'author_handle': 'somjeed.daily', 'body': 'น่ารักมากกก ขอกอดด้วย'},
    ],
    'posted_ago_text': '2 ชม.ที่แล้ว',
    'is_following_author': true,
    'is_liked': true,
    'is_saved': false,
    'is_own': false,
  },
  {
    'id': 'p2',
    'type': 'normal',
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
    'posted_ago_text': '4 ชม.ที่แล้ว',
    'is_following_author': true,
    'is_liked': false,
    'is_saved': true,
    'is_own': false,
  },
  {
    'id': 'p3',
    'type': 'normal',
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
    'posted_ago_text': '5 ชม.ที่แล้ว',
    'is_following_author': false,
    'is_liked': false,
    'is_saved': false,
    'is_own': false,
  },
  {
    'id': 'p4',
    'type': 'normal',
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
    'posted_ago_text': '1 ชม.ที่แล้ว',
    'is_following_author': false,
    'is_liked': false,
    'is_saved': true,
    'is_own': false,
  },
  {
    'id': 'p5',
    'type': 'normal',
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
    'posted_ago_text': '30 นาทีที่แล้ว',
    'is_following_author': true,
    'is_liked': false,
    'is_saved': false,
    'is_own': false,
  },
];

/// ทะเบียนบัญชีทั้งหมด + สถานะติดตามเริ่มต้น — ตรงกับ seed โพสต์ด้านบน
List<Map<String, dynamic>> _seedAccounts() => [
  {..._noon, 'is_following': true},
  {..._vet, 'is_following': true},
  {..._muk, 'is_following': false},
  {..._rescue, 'is_following': true},
  {..._somjeed, 'is_following': false},
  {..._guy, 'is_following': false},
];

/// ข้อมูล mock ในหน่วยความจำ — ใช้ช่วงยังไม่มี backend (ตามแนวทาง "ทำหน้าจอให้เห็นก่อน")
class MockFeedDataSource implements FeedRemoteDataSource {
  MockFeedDataSource({this.latency = const Duration(milliseconds: 400)})
    : _posts = _seedPosts(),
      _accounts = _seedAccounts();

  final Duration latency;
  List<Map<String, dynamic>> _posts;
  final List<Map<String, dynamic>> _accounts;
  final _hiddenIds = <String>{};

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
      _noon,
      _vet,
      _muk,
      _rescue,
      _somjeed,
      _guy,
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
  Future<void> reportPost(String postId, String reason) => _delay();

  @override
  Future<void> deletePost(String postId) async {
    await _delay();
    _posts = _posts.where((p) => p['id'] != postId).toList();
  }

  Map<String, dynamic> _find(String postId) => _posts.firstWhere(
    (p) => p['id'] == postId,
    orElse: () => throw StateError('ไม่พบโพสต์ $postId'),
  );
}

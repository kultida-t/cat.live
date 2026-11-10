const _avatarDir = 'asset:assets/images/avatars';

/// ทะเบียนบัญชีตัวอย่างเดียวกับเว็บ prototype (www.แมว.live) เรียงตามลำดับในเว็บ
/// — key ใช้เป็น `id` ของบัญชี ([mockMe] คือผู้ใช้ปัจจุบัน)
const mockMe = 'me';

const _accounts =
    <String, ({String handle, String name, String photo, int bg})>{
      'me': (
        handle: 'jutamas.lk',
        name: 'จุฑามาศ ลูกแก้ว',
        photo: '1494790108377-be9c29b29330',
        bg: 0xFFFFE89A,
      ),
      'noon': (
        handle: 'noon.mochi',
        name: 'นุ่น & โมจิ',
        photo: '1592194996308-7b43878e84a6',
        bg: 0xFFFCE7D6,
      ),
      'guy': (
        handle: 'guy.oldcat',
        name: 'กาย · แมวสูงวัย',
        photo: '1574158622682-e40e69881006',
        bg: 0xFFDCEBFF,
      ),
      'muk': (
        handle: 'muk.ari',
        name: 'มุก อารีย์',
        photo: '1787404200329-78b2aaee13c1',
        bg: 0xFFD5F0EB,
      ),
      'vet': (
        handle: 'maew.vetnote',
        name: 'หมอแมว Vet Note',
        photo: '1543852786-1cf6624b9987',
        bg: 0xFFEDE4FB,
      ),
      'rescue': (
        handle: 'rescue.bkk',
        name: 'ช่วยแมวกรุงเทพ',
        photo: '1503777119540-ce54b422baff',
        bg: 0xFFFDE2EC,
      ),
      'som': (
        handle: 'somjeed.daily',
        name: 'ส้มจี๊ดรายวัน',
        photo: '1596854407944-bf87f6fdd49e',
        bg: 0xFFFFF1C9,
      ),
      'pim': (
        handle: 'pim.kittenhouse',
        name: 'พิม บ้านลูกแมว',
        photo: '1574144611937-0df059b5ef3e',
        bg: 0xFFFFEEF3,
      ),
      'tonkla': (
        handle: 'tonkla_meow',
        name: 'ต้นกล้า',
        photo: '1533738363-b7f9aef128ce',
        bg: 0xFFEAF3FF,
      ),
      'bow': (
        handle: 'bow.persian',
        name: 'โบว์ เปอร์เซีย',
        photo: '1511044568932-338cba0ad803',
        bg: 0xFFFFF1E6,
      ),
      'nat': (
        handle: 'nat_catcafe',
        name: 'แนท แคทคาเฟ่',
        photo: '1765714714461-174be7eaad85',
        bg: 0xFFE6F7F3,
      ),
      'fluke': (
        handle: 'fluke.whiskers',
        name: 'ฟลุ๊ค',
        photo: '1514888286974-6c03e2ca1dba',
        bg: 0xFFF4EFFD,
      ),
      'mild': (
        handle: 'mild_snowball',
        name: 'มายด์ สโนว์บอล',
        photo: '1561948955-570b270e7c36',
        bg: 0xFFFFF8DD,
      ),
      'jay': (
        handle: 'jay.orangecat',
        name: 'เจ แมวส้ม',
        photo: '1571566882372-1598d88abd90',
        bg: 0xFFFFF1E6,
      ),
      'ploy': (
        handle: 'ploy.fluffy',
        name: 'พลอย',
        photo: '1764708844823-00d2188dafd8',
        bg: 0xFFFFEEF3,
      ),
    };

/// บัญชีที่ติดตามอยู่ตอนเริ่มต้น (ตรงกับเว็บ: เจ้าของโพสต์ที่ following = true)
const mockInitialFollowing = {'noon', 'vet', 'rescue'};

List<String> get mockAccountKeys => _accounts.keys.toList();

String mockHandleOf(String key) => _accounts[key]!.handle;

/// หา key ของบัญชีจาก handle (ใช้ตอนแปลงคอมเมนต์ตัวอย่างในโพสต์)
String mockKeyOfHandle(String handle) =>
    _accounts.entries.firstWhere((e) => e.value.handle == handle).key;

Map<String, dynamic> mockAccountJson(String key, {bool unseen = true}) {
  final a = _accounts[key]!;
  return {
    'id': key,
    'handle': a.handle,
    'name': a.name,
    'avatar_url': '$_avatarDir/${a.photo}.jpg',
    'avatar_bg': a.bg,
    'has_unseen_story': unseen,
  };
}

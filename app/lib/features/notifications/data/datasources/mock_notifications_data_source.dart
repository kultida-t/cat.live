import '../models/notification_models.dart';
import 'notifications_remote_data_source.dart';

const _avatarDir = 'asset:assets/images/avatars';

/// ข้อมูลตัวอย่างการแจ้งเตือน (7 รายการ: ยังไม่อ่าน 3, อ่านแล้ว 4)
class MockNotificationsDataSource implements NotificationsRemoteDataSource {
  const MockNotificationsDataSource();

  @override
  Future<List<AppNotificationModel>> fetchNotifications() async {
    return _seedItems.map(AppNotificationModel.fromJson).toList();
  }

  @override
  Future<void> markAsRead(String id) async {}

  @override
  Future<void> markAllAsRead() async {}

  static const List<Map<String, dynamic>> _seedItems = [
    {
      'id': 'n1',
      'category': 'community',
      'title_th': 'ส้มจี๊ดรายวัน (@somjeed.daily) คอมเมนต์โพสต์ของคุณ',
      'title_en': 'Somjeed Daily (@somjeed.daily) commented on your post',
      'body_th': '“น่ารักมากกก ขอกอดด้วย”',
      'body_en': '“So cuteee, can I have a hug too!”',
      'time_label_th': '5 นาทีที่แล้ว',
      'time_label_en': '5m ago',
      'is_read': false,
      'target_route': '/notifications/post/p1?comments=1',
      'actor_name': 'ส้มจี๊ดรายวัน',
      'actor_handle': '@somjeed.daily',
      'actor_avatar': '$_avatarDir/1596854407944-bf87f6fdd49e.jpg',
      'actor_bg': 0xFFFFF1C9,
    },
    {
      'id': 'n2',
      'category': 'treats',
      'title_th': 'กาย · แมวสูงวัย (@guy.oldcat) ส่งขนมแมวเลียให้ มะลิ',
      'title_en': 'Guy (@guy.oldcat) sent creamy treats to Mali',
      'body_th': 'ส่งขนมแมวเลีย 1 แพ็ก พร้อมโน้ต “ขอให้น้องมะลิแข็งแรงนะ”',
      'body_en': 'Sent 1 pack of creamy treats: “Stay healthy, Mali!”',
      'time_label_th': '22 นาทีที่แล้ว',
      'time_label_en': '22m ago',
      'is_read': false,
      'target_route': '/notifications/treats',
      'actor_name': 'กาย · แมวสูงวัย',
      'actor_handle': '@guy.oldcat',
      'actor_avatar': '$_avatarDir/1574158622682-e40e69881006.jpg',
      'actor_bg': 0xFFDCEBFF,
    },
    {
      'id': 'n3',
      'category': 'help',
      'title_th': 'ประกาศแมวหายใกล้คุณ (รัศมี 3 กม.)',
      'title_en': 'Lost cat alert near you (within 3 km)',
      'body_th': 'พบแมวส้มปลอกคอสีฟ้าแถวอารีย์ ซอย 4 — ช่วยตรวจดูเพิ่มเติม',
      'body_en': 'Orange cat with blue collar spotted near Ari Soi 4',
      'time_label_th': '1 ชม. ที่แล้ว',
      'time_label_en': '1h ago',
      'is_read': false,
      'target_route': '/notifications/help',
    },
    {
      'id': 'n4',
      'category': 'community',
      'title_th': 'มุก อารีย์ (@muk.ari) เริ่มติดตามคุณแล้ว',
      'title_en': 'Muk Ari (@muk.ari) started following you',
      'body_th': 'แตะเพื่อดูรายชื่อผู้ติดตามและส่งข้อความทักทาย',
      'body_en': 'Tap to view followers and say hello',
      'time_label_th': '3 ชม. ที่แล้ว',
      'time_label_en': '3h ago',
      'is_read': true,
      'target_route': '/notifications/connections',
      'actor_name': 'มุก อารีย์',
      'actor_handle': '@muk.ari',
      'actor_avatar': '$_avatarDir/1787404200329-78b2aaee13c1.jpg',
      'actor_bg': 0xFFD5F0EB,
    },
    {
      'id': 'n5',
      'category': 'care',
      'title_th': 'เตือนนัดสุขภาพ ส้มจี๊ด',
      'title_en': 'Health reminder for Somjeed',
      'body_th': 'นัดถัดไป: ถ่ายพยาธิ / หยดเห็บหมัด · 20 พ.ย. 2569',
      'body_en': 'Next: Deworming & flea spot-on · 20 Nov 2026',
      'time_label_th': 'เมื่อวาน',
      'time_label_en': 'Yesterday',
      'is_read': true,
      'target_route': '/notifications/health?cat=cat-somjeed',
    },
    {
      'id': 'n6',
      'category': 'community',
      'title_th': 'ต้นกล้า (@tonkla_meow) ถูกใจโพสต์ของคุณ',
      'title_en': 'Tonkla (@tonkla_meow) liked your post',
      'body_th':
          '“แมวควรกินน้ำวันละเท่าไหร่? ประมาณ 40–60 มล. ต่อน้ำหนักตัว 1 กก.”',
      'body_en': '“How much water should a cat drink daily? ~40–60 ml/kg”',
      'time_label_th': '2 วันที่แล้ว',
      'time_label_en': '2d ago',
      'is_read': true,
      'target_route': '/notifications/post/p2',
      'actor_name': 'ต้นกล้า',
      'actor_handle': '@tonkla_meow',
      'actor_avatar': '$_avatarDir/1533738363-b7f9aef128ce.jpg',
      'actor_bg': 0xFFEAF3FF,
    },
    {
      'id': 'n7',
      'category': 'system',
      'title_th': 'ยินดีต้อนรับสู่ แมว.live',
      'title_en': 'Welcome to maew.live',
      'body_th':
          'ตั้งค่า Cat ID เพื่อช่วยให้เพื่อนบ้านช่วยตามหาน้องแมวได้เร็วขึ้น',
      'body_en': 'Set up Cat ID so neighbors can help locate your cat faster',
      'time_label_th': '5 วันที่แล้ว',
      'time_label_en': '5d ago',
      'is_read': true,
      'target_route': '/cat-profile',
    },
  ];
}

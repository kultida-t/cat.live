/// ข้อความหน้าการแจ้งเตือน ไทย/อังกฤษ
class NotificationsL10n {
  const NotificationsL10n(this.isEn);

  final bool isEn;

  String get title => isEn ? 'Notifications' : 'การแจ้งเตือน';
  String get backLabel => isEn ? 'Back' : 'ย้อนกลับ';
  String get markAllRead => isEn ? 'Mark all read' : 'อ่านทั้งหมดแล้ว';
  String get markedAllReadToast =>
      isEn ? 'Marked all notifications as read' : 'อ่านการแจ้งเตือนทั้งหมดแล้ว';

  String get filterAll => isEn ? 'All' : 'ทั้งหมด';
  String filterUnread(int count) => isEn
      ? (count > 0 ? 'Unread ($count)' : 'Unread')
      : (count > 0 ? 'ยังไม่อ่าน ($count)' : 'ยังไม่อ่าน');

  String get emptyTitle =>
      isEn ? 'No notifications yet' : 'ยังไม่มีการแจ้งเตือน';
  String get emptySubtitle => isEn
      ? 'Updates about your cats, community, and alerts will show up here'
      : 'ความเคลื่อนไหวจากชุมชน ขนมแมว และประกาศใกล้คุณจะแสดงที่นี่';
  String get emptyUnreadTitle =>
      isEn ? 'All caught up!' : 'อ่านครบทุกรายการแล้ว';
  String get emptyUnreadSubtitle => isEn
      ? 'You have no unread notifications right now'
      : 'ไม่มีการแจ้งเตือนที่ยังไม่ได้อ่านในตอนนี้';
  String get showAllButton => isEn ? 'View all' : 'ดูทั้งหมด';

  String get loadErrorTitle =>
      isEn ? 'Could not load notifications' : 'โหลดการแจ้งเตือนไม่สำเร็จ';
  String get loadErrorMessage => isEn
      ? 'Check your internet connection and try again'
      : 'ตรวจสัญญาณอินเทอร์เน็ตแล้วลองใหม่อีกครั้ง';
  String get retry => isEn ? 'Try again' : 'ลองใหม่';

  String unreadBadgeLabel(int count) {
    if (isEn) {
      return count > 0 ? '$count unread' : 'All read';
    }
    return count > 0 ? 'ยังไม่อ่าน $count รายการ' : 'อ่านครบแล้ว';
  }
}

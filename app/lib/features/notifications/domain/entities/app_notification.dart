/// หมวดหมู่ของการแจ้งเตือนในแอป
enum NotificationCategory { community, help, treats, care, system }

/// ตัวกรองรายการบนหน้าการแจ้งเตือน
enum NotificationFilter { all, unread }

/// ข้อมูลการแจ้งเตือน 1 รายการ (ชั้น domain — ไม่พึ่ง Flutter/dio)
class AppNotification {
  const AppNotification({
    required this.id,
    required this.category,
    required this.titleTh,
    required this.titleEn,
    required this.bodyTh,
    required this.bodyEn,
    required this.timeLabelTh,
    required this.timeLabelEn,
    required this.isRead,
    required this.targetRoute,
    this.actorName,
    this.actorHandle,
    this.actorAvatar,
    this.actorBg = 0xFFFFF1E6,
  });

  final String id;
  final NotificationCategory category;
  final String titleTh;
  final String titleEn;
  final String bodyTh;
  final String bodyEn;
  final String timeLabelTh;
  final String timeLabelEn;
  final bool isRead;

  /// เส้นทางปลายทางเมื่อกดรายการ (เช่น /p/p1, /treats, /help, /connections, /my-cat/health)
  final String targetRoute;

  final String? actorName;
  final String? actorHandle;
  final String? actorAvatar;
  final int actorBg;

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      category: category,
      titleTh: titleTh,
      titleEn: titleEn,
      bodyTh: bodyTh,
      bodyEn: bodyEn,
      timeLabelTh: timeLabelTh,
      timeLabelEn: timeLabelEn,
      isRead: isRead ?? this.isRead,
      targetRoute: targetRoute,
      actorName: actorName,
      actorHandle: actorHandle,
      actorAvatar: actorAvatar,
      actorBg: actorBg,
    );
  }
}

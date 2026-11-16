import '../../domain/entities/app_notification.dart';

/// โมเดล JSON สำหรับการแจ้งเตือน 1 รายการ
class AppNotificationModel {
  const AppNotificationModel({
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
  final String targetRoute;
  final String? actorName;
  final String? actorHandle;
  final String? actorAvatar;
  final int actorBg;

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    return AppNotificationModel(
      id: (json['id'] ?? '').toString(),
      category: _parseCategory(json['category']?.toString()),
      titleTh: (json['title_th'] ?? json['title'] ?? '').toString(),
      titleEn: (json['title_en'] ?? json['title'] ?? '').toString(),
      bodyTh: (json['body_th'] ?? json['body'] ?? '').toString(),
      bodyEn: (json['body_en'] ?? json['body'] ?? '').toString(),
      timeLabelTh: (json['time_label_th'] ?? json['time_label'] ?? '')
          .toString(),
      timeLabelEn: (json['time_label_en'] ?? json['time_label'] ?? '')
          .toString(),
      isRead: json['is_read'] == true,
      targetRoute: (json['target_route'] ?? '/').toString(),
      actorName: json['actor_name']?.toString(),
      actorHandle: json['actor_handle']?.toString(),
      actorAvatar: json['actor_avatar']?.toString(),
      actorBg: (json['actor_bg'] as int?) ?? 0xFFFFF1E6,
    );
  }

  AppNotification toEntity() {
    return AppNotification(
      id: id,
      category: category,
      titleTh: titleTh,
      titleEn: titleEn,
      bodyTh: bodyTh,
      bodyEn: bodyEn,
      timeLabelTh: timeLabelTh,
      timeLabelEn: timeLabelEn,
      isRead: isRead,
      targetRoute: targetRoute,
      actorName: actorName,
      actorHandle: actorHandle,
      actorAvatar: actorAvatar,
      actorBg: actorBg,
    );
  }

  static NotificationCategory _parseCategory(String? raw) {
    return switch (raw) {
      'community' => NotificationCategory.community,
      'help' => NotificationCategory.help,
      'treats' => NotificationCategory.treats,
      'care' => NotificationCategory.care,
      _ => NotificationCategory.system,
    };
  }
}

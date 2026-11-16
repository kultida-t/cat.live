import '../entities/app_notification.dart';

/// สัญญาดึงและจัดการสถานะการแจ้งเตือน
abstract interface class NotificationsRepository {
  Future<List<AppNotification>> fetchNotifications();
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
}

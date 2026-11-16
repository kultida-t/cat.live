import '../models/notification_models.dart';

/// สัญญาแหล่งข้อมูลระยะไกลสำหรับหน้าการแจ้งเตือน
abstract interface class NotificationsRemoteDataSource {
  Future<List<AppNotificationModel>> fetchNotifications();
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
}

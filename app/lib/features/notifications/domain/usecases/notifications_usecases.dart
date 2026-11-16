import '../entities/app_notification.dart';
import '../repositories/notifications_repository.dart';

/// โหลดรายการแจ้งเตือนทั้งหมด
class LoadNotifications {
  const LoadNotifications(this._repository);

  final NotificationsRepository _repository;

  Future<List<AppNotification>> call() => _repository.fetchNotifications();
}

/// ทำเครื่องหมายว่าอ่านแล้ว 1 รายการ
class MarkNotificationRead {
  const MarkNotificationRead(this._repository);

  final NotificationsRepository _repository;

  Future<void> call(String id) => _repository.markAsRead(id);
}

/// ทำเครื่องหมายว่าอ่านแล้วทั้งหมด
class MarkAllNotificationsRead {
  const MarkAllNotificationsRead(this._repository);

  final NotificationsRepository _repository;

  Future<void> call() => _repository.markAllAsRead();
}

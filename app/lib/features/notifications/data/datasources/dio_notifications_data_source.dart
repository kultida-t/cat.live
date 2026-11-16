import 'package:dio/dio.dart';

import '../models/notification_models.dart';
import 'notifications_remote_data_source.dart';

/// เรียก API การแจ้งเตือนจริงผ่าน Dio (ใช้เมื่อ USE_MOCK_DATA=false)
class DioNotificationsDataSource implements NotificationsRemoteDataSource {
  const DioNotificationsDataSource(this._dio);

  final Dio _dio;

  @override
  Future<List<AppNotificationModel>> fetchNotifications() async {
    final res = await _dio.get<Map<String, dynamic>>('/v1/notifications');
    final items = (res.data?['items'] as List?) ?? const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(AppNotificationModel.fromJson)
        .toList();
  }

  @override
  Future<void> markAsRead(String id) async {
    await _dio.post<void>('/v1/notifications/$id/read');
  }

  @override
  Future<void> markAllAsRead() async {
    await _dio.post<void>('/v1/notifications/read-all');
  }
}

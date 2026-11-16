import 'package:dio/dio.dart';

import '../../../../core/network/dio_failure_mapper.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_remote_data_source.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  const NotificationsRepositoryImpl(this._remote);

  final NotificationsRemoteDataSource _remote;

  @override
  Future<List<AppNotification>> fetchNotifications() async {
    try {
      final models = await _remote.fetchNotifications();
      return models.map((m) => m.toEntity()).toList();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<void> markAsRead(String id) async {
    try {
      await _remote.markAsRead(id);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      await _remote.markAllAsRead();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}

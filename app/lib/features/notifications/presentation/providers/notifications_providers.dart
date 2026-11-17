import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/token_provider.dart';
import '../../data/datasources/dio_notifications_data_source.dart';
import '../../data/datasources/mock_notifications_data_source.dart';
import '../../data/datasources/notifications_remote_data_source.dart';
import '../../data/repositories/notifications_repository_impl.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../../domain/usecases/notifications_usecases.dart';

const _useMockData = bool.fromEnvironment('USE_MOCK_DATA', defaultValue: true);

final _notificationsDioProvider = Provider<Dio>(
  (ref) => createApiClient(tokens: ref.watch(appTokenProvider)),
);

final notificationsRemoteDataSourceProvider =
    Provider<NotificationsRemoteDataSource>((ref) {
      return _useMockData
          ? const MockNotificationsDataSource()
          : DioNotificationsDataSource(ref.watch(_notificationsDioProvider));
    });

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepositoryImpl(
    ref.watch(notificationsRemoteDataSourceProvider),
  ),
);

final loadNotificationsProvider = Provider<LoadNotifications>(
  (ref) => LoadNotifications(ref.watch(notificationsRepositoryProvider)),
);

final markNotificationReadProvider = Provider<MarkNotificationRead>(
  (ref) => MarkNotificationRead(ref.watch(notificationsRepositoryProvider)),
);

final markAllNotificationsReadProvider = Provider<MarkAllNotificationsRead>(
  (ref) => MarkAllNotificationsRead(ref.watch(notificationsRepositoryProvider)),
);

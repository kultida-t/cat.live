import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/datasources/dio_feed_data_source.dart';
import '../../data/datasources/feed_remote_data_source.dart';
import '../../data/datasources/mock_feed_data_source.dart';
import '../../data/repositories/feed_repository_impl.dart';
import '../../domain/entities/feed_user.dart';
import '../../domain/repositories/feed_repository.dart';
import '../../domain/usecases/feed_usecases.dart';

/// ช่วงยังไม่มี backend ใช้ข้อมูล mock — ต่อ API จริงด้วย `--dart-define=USE_MOCK_DATA=false`
const useMockData = bool.fromEnvironment('USE_MOCK_DATA', defaultValue: true);

final dioProvider = Provider<Dio>((ref) => createApiClient());

final feedDataSourceProvider = Provider<FeedRemoteDataSource>((ref) {
  return useMockData
      ? MockFeedDataSource()
      : DioFeedDataSource(ref.watch(dioProvider));
});

final feedRepositoryProvider = Provider<FeedRepository>(
  (ref) => FeedRepositoryImpl(ref.watch(feedDataSourceProvider)),
);

final getFeedPageProvider = Provider(
  (ref) => GetFeedPage(ref.watch(feedRepositoryProvider)),
);
final getStoryUsersProvider = Provider(
  (ref) => GetStoryUsers(ref.watch(feedRepositoryProvider)),
);
final getAccountsProvider = Provider(
  (ref) => GetAccounts(ref.watch(feedRepositoryProvider)),
);
final toggleLikeProvider = Provider(
  (ref) => ToggleLike(ref.watch(feedRepositoryProvider)),
);
final toggleSaveProvider = Provider(
  (ref) => ToggleSave(ref.watch(feedRepositoryProvider)),
);
final toggleFollowProvider = Provider(
  (ref) => ToggleFollow(ref.watch(feedRepositoryProvider)),
);
final hidePostProvider = Provider(
  (ref) => HidePost(ref.watch(feedRepositoryProvider)),
);
final reportPostProvider = Provider(
  (ref) => ReportPost(ref.watch(feedRepositoryProvider)),
);
final deletePostProvider = Provider(
  (ref) => DeletePost(ref.watch(feedRepositoryProvider)),
);

final storyUsersProvider = FutureProvider<List<FeedUser>>(
  (ref) => ref.watch(getStoryUsersProvider)(),
);

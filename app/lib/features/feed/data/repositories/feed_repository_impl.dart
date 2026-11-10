import 'package:dio/dio.dart';

import '../../../../core/network/dio_failure_mapper.dart';
import '../../domain/entities/feed_tab.dart';
import '../../domain/entities/feed_user.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/feed_repository.dart';
import '../datasources/feed_remote_data_source.dart';

class FeedRepositoryImpl implements FeedRepository {
  const FeedRepositoryImpl(this._remote);

  final FeedRemoteDataSource _remote;

  /// ครอบทุกการเรียก: DioException → Failure ภาษาไทย
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<FeedPage> getPosts({
    required FeedTab tab,
    int cursor = 0,
    int limit = 5,
  }) => _guard(
    () async => (await _remote.fetchPosts(
      tab: tab,
      cursor: cursor,
      limit: limit,
    )).toEntity(),
  );

  @override
  Future<List<FeedUser>> getStoryUsers() => _guard(
    () async =>
        (await _remote.fetchStoryUsers()).map((u) => u.toEntity()).toList(),
  );

  @override
  Future<List<FeedUser>> getAccounts() => _guard(
    () async =>
        (await _remote.fetchAccounts()).map((u) => u.toEntity()).toList(),
  );

  @override
  Future<Post> toggleLike(String postId) =>
      _guard(() async => (await _remote.toggleLike(postId)).toEntity());

  @override
  Future<Post> toggleSave(String postId) =>
      _guard(() async => (await _remote.toggleSave(postId)).toEntity());

  @override
  Future<void> toggleFollow(String userId) =>
      _guard(() => _remote.toggleFollow(userId));

  @override
  Future<void> hidePost(String postId) =>
      _guard(() => _remote.hidePost(postId));

  @override
  Future<void> hideAccountPosts(String userId) =>
      _guard(() => _remote.hideAccountPosts(userId));

  @override
  Future<void> reportPost(String postId, String reason) =>
      _guard(() => _remote.reportPost(postId, reason));

  @override
  Future<void> deletePost(String postId) =>
      _guard(() => _remote.deletePost(postId));
}

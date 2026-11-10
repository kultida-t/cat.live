import 'package:dio/dio.dart';

import '../../domain/entities/feed_tab.dart';
import '../models/feed_models.dart';
import 'feed_remote_data_source.dart';

/// เรียก API ฟีดจริงผ่าน Dio — เส้นทางด้านล่างเป็นสัญญาเบื้องต้น
/// ต้องปรับให้ตรง OpenAPI ของ NestJS เมื่อ backend พร้อม
class DioFeedDataSource implements FeedRemoteDataSource {
  const DioFeedDataSource(this._dio);

  final Dio _dio;

  @override
  Future<FeedPageModel> fetchPosts({
    required FeedTab tab,
    required int cursor,
    required int limit,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/v1/feed',
      queryParameters: {'tab': tab.name, 'cursor': cursor, 'limit': limit},
    );
    return FeedPageModel.fromJson(res.data!);
  }

  @override
  Future<List<FeedUserModel>> fetchStoryUsers() async {
    final res = await _dio.get<List<dynamic>>('/v1/stories');
    return res.data!
        .cast<Map<String, dynamic>>()
        .map(FeedUserModel.fromJson)
        .toList();
  }

  @override
  Future<List<FeedUserModel>> fetchAccounts() async {
    final res = await _dio.get<List<dynamic>>('/v1/feed/accounts');
    return res.data!
        .cast<Map<String, dynamic>>()
        .map(FeedUserModel.fromJson)
        .toList();
  }

  @override
  Future<PostModel> toggleLike(String postId) async {
    final res = await _dio.post<Map<String, dynamic>>('/v1/posts/$postId/like');
    return PostModel.fromJson(res.data!);
  }

  @override
  Future<PostModel> toggleSave(String postId) async {
    final res = await _dio.post<Map<String, dynamic>>('/v1/posts/$postId/save');
    return PostModel.fromJson(res.data!);
  }

  @override
  Future<void> toggleFollow(String userId) async {
    await _dio.post<void>('/v1/users/$userId/follow');
  }

  @override
  Future<void> hidePost(String postId) async {
    await _dio.post<void>('/v1/posts/$postId/hide');
  }

  @override
  Future<void> reportPost(String postId, String reason) async {
    await _dio.post<void>('/v1/posts/$postId/report', data: {'reason': reason});
  }

  @override
  Future<void> deletePost(String postId) async {
    await _dio.delete<void>('/v1/posts/$postId');
  }
}

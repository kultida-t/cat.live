import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../../../core/media/strip_image_metadata.dart';
import '../../domain/entities/feed_tab.dart';
import '../../domain/entities/new_post.dart';
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
  Future<void> hideAccountPosts(String userId) async {
    await _dio.post<void>('/v1/users/$userId/hide-posts');
  }

  @override
  Future<void> reportPost(String postId, String reason) async {
    await _dio.post<void>('/v1/posts/$postId/report', data: {'reason': reason});
  }

  @override
  Future<void> deletePost(String postId) async {
    await _dio.delete<void>('/v1/posts/$postId');
  }

  @override
  Future<PostModel> fetchPost(String postId) async {
    final res = await _dio.get<Map<String, dynamic>>('/v1/posts/$postId');
    return PostModel.fromJson(res.data!);
  }

  /// สร้างโพสต์แบบ multipart — รูปถูกลบข้อมูลแฝง (GPS) ก่อนส่งเสมอ
  /// ส่วนวิดีโอส่งไฟล์เดิม เซิร์ฟเวอร์ต้องลบข้อมูลแฝงเอง
  @override
  Future<PostModel> createPost(NewPost draft) async {
    final files = <MultipartFile>[];
    for (final m in draft.media) {
      final path = m.source.substring(m.source.indexOf(':') + 1);
      final bytes = m.source.startsWith('file:')
          ? await File(path).readAsBytes()
          : (await rootBundle.load(path)).buffer.asUint8List();
      files.add(
        m.isVideo
            ? MultipartFile.fromBytes(bytes, filename: m.name)
            : MultipartFile.fromBytes(
                await stripImageMetadata(bytes),
                filename: '${m.name.split('.').first}.png',
              ),
      );
    }
    final res = await _dio.post<Map<String, dynamic>>(
      '/v1/posts',
      data: FormData.fromMap({
        'caption': draft.caption,
        'category': 'daily',
        'media': files,
      }),
    );
    return PostModel.fromJson(res.data!);
  }

  @override
  Future<List<CommentModel>> fetchComments(String postId) async {
    final res = await _dio.get<List<dynamic>>('/v1/posts/$postId/comments');
    return res.data!
        .cast<Map<String, dynamic>>()
        .map(CommentModel.fromJson)
        .toList();
  }

  @override
  Future<CommentModel> addComment(
    String postId,
    String text, {
    String? replyToHandle,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/v1/posts/$postId/comments',
      data: {'text': text, 'reply_to_handle': ?replyToHandle},
    );
    return CommentModel.fromJson(res.data!);
  }

  @override
  Future<CommentModel> toggleCommentLike(
    String postId,
    String commentId,
  ) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/v1/posts/$postId/comments/$commentId/like',
    );
    return CommentModel.fromJson(res.data!);
  }
}

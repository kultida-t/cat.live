import '../../domain/entities/feed_tab.dart';
import '../../domain/entities/new_post.dart';
import '../models/feed_models.dart';

/// แหล่งข้อมูลฟีด — มี 2 ตัวสลับกันได้: mock (ตอนนี้) และ Dio (ต่อ API จริง)
abstract interface class FeedRemoteDataSource {
  Future<FeedPageModel> fetchPosts({
    required FeedTab tab,
    required int cursor,
    required int limit,
  });
  Future<List<FeedUserModel>> fetchStoryUsers();
  Future<List<FeedUserModel>> fetchAccounts();
  Future<PostModel> toggleLike(String postId);
  Future<PostModel> toggleSave(String postId);
  Future<void> toggleFollow(String userId);
  Future<void> hidePost(String postId);
  Future<void> hideAccountPosts(String userId);
  Future<void> reportPost(String postId, String reason);
  Future<void> deletePost(String postId);
  Future<PostModel> fetchPost(String postId);
  Future<PostModel> createPost(NewPost draft);
  Future<List<CommentModel>> fetchComments(String postId);
  Future<CommentModel> addComment(
    String postId,
    String text, {
    String? replyToHandle,
  });
  Future<CommentModel> toggleCommentLike(String postId, String commentId);
}

import '../entities/comment.dart';
import '../entities/feed_tab.dart';
import '../entities/feed_user.dart';
import '../entities/new_post.dart';
import '../entities/post.dart';

/// สัญญาของข้อมูลฟีด — ชั้น domain รู้จักแค่ interface นี้
/// ทุกเมธอดโยน `Failure` เมื่อผิดพลาด
abstract interface class FeedRepository {
  Future<FeedPage> getPosts({
    required FeedTab tab,
    int cursor = 0,
    int limit = 5,
  });
  Future<List<FeedUser>> getStoryUsers();
  Future<List<FeedUser>> getAccounts();
  Future<Post> toggleLike(String postId);
  Future<Post> toggleSave(String postId);
  Future<void> toggleFollow(String userId);
  Future<void> hidePost(String postId);
  Future<void> hideAccountPosts(String userId);
  Future<void> reportPost(String postId, String reason);
  Future<void> deletePost(String postId);
  Future<Post> getPost(String postId);
  Future<Post> createPost(NewPost draft);
  Future<List<Comment>> getComments(String postId);
  Future<Comment> addComment(
    String postId,
    String text, {
    String? replyToHandle,
  });
  Future<Comment> toggleCommentLike(String postId, String commentId);
}

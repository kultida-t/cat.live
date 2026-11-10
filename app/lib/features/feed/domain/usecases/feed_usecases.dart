import '../entities/comment.dart';
import '../entities/feed_tab.dart';
import '../entities/feed_user.dart';
import '../entities/new_post.dart';
import '../entities/post.dart';
import '../repositories/feed_repository.dart';

/// Use case แต่ละตัวทำงานเดียว — ชั้น presentation เรียกผ่านตัวเหล่านี้เท่านั้น

class GetFeedPage {
  const GetFeedPage(this._repo);
  final FeedRepository _repo;

  Future<FeedPage> call({required FeedTab tab, int cursor = 0}) =>
      _repo.getPosts(tab: tab, cursor: cursor);
}

class GetStoryUsers {
  const GetStoryUsers(this._repo);
  final FeedRepository _repo;

  Future<List<FeedUser>> call() => _repo.getStoryUsers();
}

class GetAccounts {
  const GetAccounts(this._repo);
  final FeedRepository _repo;

  Future<List<FeedUser>> call() => _repo.getAccounts();
}

class ToggleLike {
  const ToggleLike(this._repo);
  final FeedRepository _repo;

  Future<Post> call(String postId) => _repo.toggleLike(postId);
}

class ToggleSave {
  const ToggleSave(this._repo);
  final FeedRepository _repo;

  Future<Post> call(String postId) => _repo.toggleSave(postId);
}

class ToggleFollow {
  const ToggleFollow(this._repo);
  final FeedRepository _repo;

  Future<void> call(String userId) => _repo.toggleFollow(userId);
}

class HidePost {
  const HidePost(this._repo);
  final FeedRepository _repo;

  Future<void> call(String postId) => _repo.hidePost(postId);
}

class HideAccountPosts {
  const HideAccountPosts(this._repo);
  final FeedRepository _repo;

  Future<void> call(String userId) => _repo.hideAccountPosts(userId);
}

class ReportPost {
  const ReportPost(this._repo);
  final FeedRepository _repo;

  Future<void> call(String postId, String reason) =>
      _repo.reportPost(postId, reason);
}

class DeletePost {
  const DeletePost(this._repo);
  final FeedRepository _repo;

  Future<void> call(String postId) => _repo.deletePost(postId);
}

class GetPost {
  const GetPost(this._repo);
  final FeedRepository _repo;

  Future<Post> call(String postId) => _repo.getPost(postId);
}

class CreatePost {
  const CreatePost(this._repo);
  final FeedRepository _repo;

  Future<Post> call(NewPost draft) => _repo.createPost(draft);
}

class GetComments {
  const GetComments(this._repo);
  final FeedRepository _repo;

  Future<List<Comment>> call(String postId) => _repo.getComments(postId);
}

class AddComment {
  const AddComment(this._repo);
  final FeedRepository _repo;

  Future<Comment> call(String postId, String text, {String? replyToHandle}) =>
      _repo.addComment(postId, text, replyToHandle: replyToHandle);
}

class ToggleCommentLike {
  const ToggleCommentLike(this._repo);
  final FeedRepository _repo;

  Future<Comment> call(String postId, String commentId) =>
      _repo.toggleCommentLike(postId, commentId);
}

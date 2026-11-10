import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/comment.dart';
import 'feed_providers.dart';

enum CommentsStatus { loading, ready, error }

class CommentsState {
  const CommentsState({
    this.status = CommentsStatus.loading,
    this.comments = const [],
    this.replyTo,
    this.errorMessage,
  });

  final CommentsStatus status;
  final List<Comment> comments;

  /// คอมเมนต์ที่กำลังตอบกลับ (null = คอมเมนต์ใหม่ระดับบนสุด)
  final Comment? replyTo;
  final String? errorMessage;

  CommentsState copyWith({
    CommentsStatus? status,
    List<Comment>? comments,
    Object? replyTo = _keep,
    String? errorMessage,
  }) => CommentsState(
    status: status ?? this.status,
    comments: comments ?? this.comments,
    replyTo: identical(replyTo, _keep) ? this.replyTo : replyTo as Comment?,
    errorMessage: errorMessage ?? this.errorMessage,
  );
}

const _keep = Object();

final commentsControllerProvider = NotifierProvider.autoDispose
    .family<CommentsController, CommentsState, String>(CommentsController.new);

/// จัดการคอมเมนต์ของโพสต์หนึ่งใบ: โหลด/ส่ง/ถูกใจ/ตอบกลับ
/// ส่งและกดถูกใจแบบ optimistic — ล้มเหลวจะย้อนกลับและคืน [Failure]
class CommentsController extends Notifier<CommentsState> {
  CommentsController(this.postId);

  final String postId;
  var _tempSeq = 0;

  @override
  CommentsState build() {
    Future.microtask(load);
    return const CommentsState();
  }

  Future<void> load() async {
    state = const CommentsState();
    try {
      final comments = await ref.read(getCommentsProvider)(postId);
      if (!ref.mounted) return;
      state = state.copyWith(status: CommentsStatus.ready, comments: comments);
    } on Failure catch (f) {
      if (!ref.mounted) return;
      state = state.copyWith(
        status: CommentsStatus.error,
        errorMessage: f.message,
      );
    }
  }

  void startReply(Comment comment) => state = state.copyWith(replyTo: comment);

  void cancelReply() => state = state.copyWith(replyTo: null);

  Future<Failure?> add(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty) return null;
    final replyTo = state.replyTo;
    final tempId = 'tmp-${++_tempSeq}';
    final temp = Comment(
      id: tempId,
      author: ref.read(currentUserProvider),
      text: text,
      timeText: 'เมื่อสักครู่',
      likeCount: 0,
      isLiked: false,
      replyToHandle: replyTo?.author.handle,
    );
    state = state.copyWith(comments: [...state.comments, temp], replyTo: null);
    try {
      final saved = await ref.read(addCommentProvider)(
        postId,
        text,
        replyToHandle: replyTo?.author.handle,
      );
      if (ref.mounted) {
        state = state.copyWith(
          comments: [
            for (final c in state.comments) c.id == tempId ? saved : c,
          ],
        );
      }
      return null;
    } on Failure catch (f) {
      if (ref.mounted) {
        state = state.copyWith(
          comments: state.comments.where((c) => c.id != tempId).toList(),
        );
      }
      return f;
    }
  }

  Future<Failure?> toggleLike(Comment comment) async {
    if (comment.id.startsWith('tmp-')) return null;
    final liked = !comment.isLiked;
    final optimistic = comment.copyWith(
      isLiked: liked,
      likeCount: comment.likeCount + (liked ? 1 : -1),
    );
    _replace(optimistic);
    try {
      final server = await ref.read(toggleCommentLikeProvider)(
        postId,
        comment.id,
      );
      if (ref.mounted) _replace(server);
      return null;
    } on Failure catch (f) {
      if (ref.mounted) _replace(comment);
      return f;
    }
  }

  void _replace(Comment updated) {
    state = state.copyWith(
      comments: [
        for (final c in state.comments) c.id == updated.id ? updated : c,
      ],
    );
  }
}

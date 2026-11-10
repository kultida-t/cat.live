import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/fill_icon.dart';
import '../../../../core/widgets/toast_pill.dart';
import '../../domain/entities/comment.dart';
import '../../domain/entities/post.dart';
import '../providers/comments_controller.dart';
import '../providers/feed_controller.dart';
import '../providers/feed_providers.dart';

const _reactions = ['❤️', '🥹', '😹', '👏', '🙏'];

/// ชีตความคิดเห็นของโพสต์ — หน้าตาตามเว็บ (www.แมว.live)
Future<void> showCommentsSheet(BuildContext context, Post post) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x594A3428),
    builder: (context) => _CommentsSheet(post: post),
  );
}

class _CommentsSheet extends ConsumerStatefulWidget {
  const _CommentsSheet({required this.post});

  final Post post;

  @override
  ConsumerState<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<_CommentsSheet>
    with ToastMixin {
  final _input = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _input.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    disposeToast();
    _input.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  CommentsController get _controller =>
      ref.read(commentsControllerProvider(widget.post.id).notifier);

  Future<void> _send([String? text]) async {
    final value = text ?? _input.text;
    if (value.trim().isEmpty) return;
    if (text == null) _input.clear();
    final pending = _controller.add(value);
    ref.read(feedControllerProvider.notifier).bumpCommentCount(widget.post.id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
    final failure = await pending;
    if (failure != null && mounted) {
      ref
          .read(feedControllerProvider.notifier)
          .bumpCommentCount(widget.post.id, by: -1);
      showToast(failure.message);
    }
  }

  Future<void> _like(Comment comment) async {
    final failure = await _controller.toggleLike(comment);
    if (failure != null && mounted) showToast(failure.message);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(commentsControllerProvider(widget.post.id));
    final media = MediaQuery.of(context);
    final available = media.size.height - media.viewInsets.bottom;
    final me = ref.watch(currentUserProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: available * 0.55,
              maxHeight: available * 0.82,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  _Header(
                    count: state.comments.length,
                    onClose: () => Navigator.pop(context),
                  ),
                  Expanded(child: _body(state)),
                  _Footer(
                    me: me.avatar,
                    meBg: me.avatarBg,
                    hint: 'แสดงความคิดเห็นถึง ${widget.post.author.handle}…',
                    controller: _input,
                    focus: _focus,
                    replyTo: state.replyTo,
                    onCancelReply: _controller.cancelReply,
                    onSend: _send,
                    onReaction: _send,
                  ),
                ],
              ),
            ),
          ),
          if (toastMessage != null)
            Positioned(
              left: 0,
              right: 0,
              top: -56,
              child: IgnorePointer(
                child: Center(child: ToastPill(message: toastMessage!)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _body(CommentsState state) {
    if (state.status == CommentsStatus.loading) {
      return const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.muted,
          ),
        ),
      );
    }
    if (state.status == CommentsStatus.error) {
      return ErrorView(
        title: 'โหลดความคิดเห็นไม่สำเร็จ',
        message: state.errorMessage ?? 'ลองใหม่อีกครั้ง',
        onRetry: _controller.load,
      );
    }
    final post = widget.post;
    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.only(bottom: 16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.line)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppAvatar(
                source: post.author.avatar,
                bg: post.author.avatarBg,
                size: 34,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${post.author.handle} ',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: post.caption),
                    ],
                  ),
                  style: _text,
                ),
              ),
            ],
          ),
        ),
        for (final c in state.comments)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _CommentRow(
              key: ValueKey(c.id),
              comment: c,
              onReply: () {
                _controller.startReply(c);
                _focus.requestFocus();
              },
              onLike: () => _like(c),
            ),
          ),
      ],
    );
  }
}

const _text = TextStyle(fontSize: 14, height: 1.6, color: AppColors.text);

class _Header extends StatelessWidget {
  const _Header({required this.count, required this.onClose});

  final int count;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.line2,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 40, height: 40),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'ความคิดเห็น '),
                    TextSpan(
                      text: '$count',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              SizedBox(
                width: 40,
                height: 40,
                child: IconButton(
                  tooltip: 'ปิด',
                  onPressed: onClose,
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    LucideIcons.x,
                    size: 20,
                    color: AppColors.text2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommentRow extends StatelessWidget {
  const _CommentRow({
    super.key,
    required this.comment,
    required this.onReply,
    required this.onLike,
  });

  final Comment comment;
  final VoidCallback onReply;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    final isReply = comment.replyToHandle != null;
    return Padding(
      padding: EdgeInsets.only(left: isReply ? 40 : 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppAvatar(
            source: comment.author.avatar,
            bg: comment.author.avatarBg,
            size: isReply ? 28 : 34,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${comment.author.handle} ',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (isReply)
                        TextSpan(
                          text: '@${comment.replyToHandle} ',
                          style: const TextStyle(color: AppColors.ink),
                        ),
                      TextSpan(text: comment.text),
                    ],
                  ),
                  style: _text,
                ),
                const SizedBox(height: 4),
                DefaultTextStyle(
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.muted,
                    height: 1.5,
                  ),
                  child: Row(
                    children: [
                      Text(comment.timeText),
                      if (comment.likeCount > 0) ...[
                        const SizedBox(width: 12),
                        Text('ถูกใจ ${comment.likeCount}'),
                      ],
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: onReply,
                        behavior: HitTestBehavior.opaque,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 24),
                          child: const Center(
                            child: Text(
                              'ตอบกลับ',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.text2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Semantics(
            button: true,
            label: comment.isLiked
                ? 'เลิกถูกใจความคิดเห็น'
                : 'ถูกใจความคิดเห็น',
            child: InkResponse(
              onTap: onLike,
              radius: 20,
              child: SizedBox(
                width: 32,
                height: 32,
                child: Center(
                  child: FillIcon(
                    shape: FillIconShape.heart,
                    size: 15,
                    filled: comment.isLiked,
                    color: comment.isLiked ? AppColors.heart : AppColors.muted,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.me,
    required this.meBg,
    required this.hint,
    required this.controller,
    required this.focus,
    required this.replyTo,
    required this.onCancelReply,
    required this.onSend,
    required this.onReaction,
  });

  final String me;
  final int meBg;
  final String hint;
  final TextEditingController controller;
  final FocusNode focus;
  final Comment? replyTo;
  final VoidCallback onCancelReply;
  final VoidCallback onSend;
  final ValueChanged<String> onReaction;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final canSend = controller.text.trim().isNotEmpty;
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, 16 + bottomInset),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (final emoji in _reactions)
                  Semantics(
                    button: true,
                    label: 'ส่ง $emoji',
                    excludeSemantics: true,
                    child: InkResponse(
                      onTap: () => onReaction(emoji),
                      radius: 22,
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: Center(
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (replyTo != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
              decoration: BoxDecoration(
                color: AppColors.soft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(text: 'กำลังตอบกลับ '),
                          TextSpan(
                            text: replyTo!.author.handle,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.text2,
                      ),
                    ),
                  ),
                  InkResponse(
                    onTap: onCancelReply,
                    radius: 16,
                    child: const SizedBox(
                      width: 24,
                      height: 24,
                      child: Icon(
                        LucideIcons.x,
                        size: 14,
                        color: AppColors.text2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              AppAvatar(source: me, bg: meBg, size: 34),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(minHeight: 44),
                  padding: const EdgeInsets.only(left: 16, right: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.line2),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          focusNode: focus,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => onSend(),
                          style: const TextStyle(
                            fontSize: 14.5,
                            color: AppColors.text,
                          ),
                          decoration: InputDecoration(
                            isCollapsed: true,
                            border: InputBorder.none,
                            hintText: hint,
                            hintStyle: const TextStyle(
                              fontSize: 14.5,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                      ),
                      Opacity(
                        opacity: canSend ? 1 : 0.35,
                        child: IconButton(
                          tooltip: 'ส่งความคิดเห็น',
                          onPressed: canSend ? onSend : null,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          icon: const Icon(
                            LucideIcons.send,
                            size: 18,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

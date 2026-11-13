import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/config/app_locale.dart';
import '../../../../core/media/strip_image_metadata.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/toast_pill.dart';
import '../../domain/entities/messages_data.dart';
import '../providers/messages_controller.dart';
import '../widgets/messages_l10n.dart';

/// หน้าห้องแชท 1 ต่อ 1 (/messages/:id) — ตรงเว็บ prototype (www.แมว.live/messages/t-noon)
class ChatRoomPage extends ConsumerStatefulWidget {
  const ChatRoomPage({super.key, required this.threadId});

  final String threadId;

  @override
  ConsumerState<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends ConsumerState<ChatRoomPage> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _showEmojiBar = false;
  String? _toast;

  static const _quickEmojis = ['😂', '🤣', '😻', '🐾', '❤️', '🙏', '😴'];
  static const _samplePhotos = [
    'asset:assets/images/hero/mali.jpg',
    'asset:assets/images/hero/somjeed.jpg',
    'asset:assets/images/hero/thuadam.jpg',
    'asset:assets/images/hero/kitten.jpg',
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(messagesControllerProvider.notifier).markRead(widget.threadId);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _showToast(String msg) {
    setState(() => _toast = msg);
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted && _toast == msg) setState(() => _toast = null);
    });
  }

  Future<void> _sendText([String? override]) async {
    final text = (override ?? _ctrl.text).trim();
    if (text.isEmpty) return;
    if (override == null) _ctrl.clear();
    setState(() => _showEmojiBar = false);
    await ref
        .read(messagesControllerProvider.notifier)
        .sendMessage(threadId: widget.threadId, text: text);
    _scrollToBottom();
  }

  Future<void> _pickDevicePhoto(ImageSource source, MessagesL10n l10n) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;
      final clean = await stripImageMetadata(await picked.readAsBytes());
      final outFile = File(
        '${Directory.systemTemp.path}/msg_${DateTime.now().microsecondsSinceEpoch}.png',
      );
      await outFile.writeAsBytes(clean, flush: true);
      if (!mounted) return;
      await ref
          .read(messagesControllerProvider.notifier)
          .sendMessage(
            threadId: widget.threadId,
            text: '',
            imagePath: 'file:${outFile.path}',
          );
      _scrollToBottom();
    } on PlatformException {
      if (mounted) _showToast(l10n.photoPickFailed);
    } catch (_) {
      if (mounted) _showToast(l10n.photoPickFailed);
    }
  }

  Future<void> _pickSamplePhoto(MessagesL10n l10n) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.sheetBarrier,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          14,
          20,
          20 + MediaQuery.of(ctx).viewPadding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.sendPhoto,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () => Navigator.of(ctx).pop('gallery'),
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 48,
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.images,
                      size: 20,
                      color: AppColors.text,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l10n.pickFromGallery,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            InkWell(
              onTap: () => Navigator.of(ctx).pop('camera'),
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 48,
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.camera,
                      size: 20,
                      color: AppColors.text,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l10n.takePhoto,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1, color: AppColors.line),
            ),
            Text(
              l10n.samplePhotos,
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _samplePhotos.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final src = _samplePhotos[i];
                  return InkWell(
                    onTap: () => Navigator.of(ctx).pop(src),
                    borderRadius: BorderRadius.circular(14),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: AppImage(source: src),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    if (choice == 'gallery') {
      await _pickDevicePhoto(ImageSource.gallery, l10n);
      return;
    }
    if (choice == 'camera') {
      await _pickDevicePhoto(ImageSource.camera, l10n);
      return;
    }
    await ref
        .read(messagesControllerProvider.notifier)
        .sendMessage(threadId: widget.threadId, text: '', imagePath: choice);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(messagesControllerProvider);
    final l10n = MessagesL10n(ref.watch(appLocaleProvider) == 'en');
    final thread = state.threadById(widget.threadId);

    if (state.status == MessagesStatus.loading && thread == null) {
      return const Scaffold(
        backgroundColor: AppColors.page,
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

    if (thread == null) {
      return Scaffold(
        backgroundColor: AppColors.page,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.emptyTitle,
                  style: const TextStyle(fontSize: 15, color: AppColors.muted),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => context.pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.btn,
                    foregroundColor: AppColors.ink,
                  ),
                  child: Text(l10n.back),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.page,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _RoomHeader(
                  peer: thread.peer,
                  backLabel: l10n.back,
                  onBack: () => context.pop(),
                  onCall: () => _showToast(l10n.callSoon),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => FocusScope.of(context).unfocus(),
                    child: ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                      itemCount: thread.messages.length + 1,
                      itemBuilder: (_, i) {
                        if (i == 0) {
                          return _RoomPeerIntro(
                            peer: thread.peer,
                            emptyHint: thread.messages.isEmpty
                                ? l10n.emptyRoomHint
                                : null,
                          );
                        }
                        final idx = i - 1;
                        final msg = thread.messages[idx];
                        final isLastInGroup =
                            idx == thread.messages.length - 1 ||
                            thread.messages[idx + 1].isMine != msg.isMine;
                        return _MessageBubble(
                          message: msg,
                          peer: thread.peer,
                          showPeerAvatar: !msg.isMine && isLastInGroup,
                        );
                      },
                    ),
                  ),
                ),
                if (_showEmojiBar)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: AppColors.page,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        for (final emoji in _quickEmojis)
                          InkWell(
                            onTap: () => _ctrl.text = '${_ctrl.text}$emoji',
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 22),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                _ComposerBar(
                  controller: _ctrl,
                  l10n: l10n,
                  onPickPhoto: () => _pickSamplePhoto(l10n),
                  onToggleEmoji: () =>
                      setState(() => _showEmojiBar = !_showEmojiBar),
                  onSend: _sendText,
                ),
              ],
            ),
          ),
          if (_toast != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 84,
              child: IgnorePointer(
                child: Center(child: ToastPill(message: _toast!)),
              ),
            ),
        ],
      ),
    );
  }
}

class _RoomHeader extends StatelessWidget {
  const _RoomHeader({
    required this.peer,
    required this.backLabel,
    required this.onBack,
    required this.onCall,
  });

  final ChatUser peer;
  final String backLabel;
  final VoidCallback onBack;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 8, 8),
      decoration: const BoxDecoration(
        color: AppColors.page,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: backLabel,
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(14),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  LucideIcons.chevronLeft,
                  size: 24,
                  color: AppColors.text,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          AppAvatar(source: peer.avatarSource, bg: peer.avatarBg, size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  peer.handle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                Text(
                  peer.lastActiveText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          Semantics(
            button: true,
            label: 'โทร',
            child: InkWell(
              onTap: onCall,
              borderRadius: BorderRadius.circular(14),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(LucideIcons.phone, size: 21, color: AppColors.text),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomPeerIntro extends StatelessWidget {
  const _RoomPeerIntro({required this.peer, this.emptyHint});

  final ChatUser peer;
  final String? emptyHint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 26),
      child: Column(
        children: [
          AppAvatar(source: peer.avatarSource, bg: peer.avatarBg, size: 84),
          const SizedBox(height: 12),
          Text(
            peer.handle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            peer.relationText,
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          if (emptyHint != null) ...[
            const SizedBox(height: 18),
            Text(
              emptyHint!,
              style: const TextStyle(fontSize: 13.5, color: AppColors.muted),
            ),
          ],
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.peer,
    required this.showPeerAvatar,
  });

  final ChatMessage message;
  final ChatUser peer;
  final bool showPeerAvatar;

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.72;
    final bubble = Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: message.imagePath != null && message.text.isEmpty
          ? const EdgeInsets.all(4)
          : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: message.isMine ? AppColors.btn : AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: message.isMine ? AppColors.btnBorder : AppColors.line,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.imagePath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 190,
                height: 150,
                child: AppImage(source: message.imagePath!),
              ),
            ),
          if (message.text.isNotEmpty) ...[
            if (message.imagePath != null) const SizedBox(height: 6),
            Text(
              message.text,
              style: TextStyle(
                fontSize: 15,
                height: 1.35,
                color: message.isMine ? AppColors.ink : AppColors.text,
              ),
            ),
          ],
        ],
      ),
    );

    if (message.isMine) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [bubble],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: 30,
            child: showPeerAvatar
                ? AppAvatar(
                    source: peer.avatarSource,
                    bg: peer.avatarBg,
                    size: 28,
                  )
                : null,
          ),
          const SizedBox(width: 8),
          bubble,
        ],
      ),
    );
  }
}

class _ComposerBar extends StatelessWidget {
  const _ComposerBar({
    required this.controller,
    required this.l10n,
    required this.onPickPhoto,
    required this.onToggleEmoji,
    required this.onSend,
  });

  final TextEditingController controller;
  final MessagesL10n l10n;
  final VoidCallback onPickPhoto;
  final VoidCallback onToggleEmoji;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 10, 10),
      decoration: const BoxDecoration(
        color: AppColors.page,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: l10n.sendPhoto,
            child: InkWell(
              onTap: onPickPhoto,
              borderRadius: BorderRadius.circular(14),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  LucideIcons.imagePlus,
                  size: 22,
                  color: AppColors.text,
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.line2),
              ),
              padding: const EdgeInsets.only(left: 14, right: 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      onSubmitted: (_) => onSend(),
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.text,
                      ),
                      decoration: InputDecoration(
                        hintText: l10n.typeMessageHint,
                        hintStyle: const TextStyle(
                          fontSize: 15,
                          color: AppColors.muted,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: l10n.emoji,
                    child: InkWell(
                      onTap: onToggleEmoji,
                      borderRadius: BorderRadius.circular(999),
                      child: const SizedBox(
                        width: 36,
                        height: 36,
                        child: Icon(
                          LucideIcons.smile,
                          size: 20,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            button: true,
            label: l10n.send,
            child: InkWell(
              onTap: onSend,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.btn,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.btnBorder),
                ),
                child: const Icon(
                  LucideIcons.send,
                  size: 19,
                  color: AppColors.ink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

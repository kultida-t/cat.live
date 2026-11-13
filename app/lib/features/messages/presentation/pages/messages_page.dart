import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/config/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/toast_pill.dart';
import '../../domain/entities/messages_data.dart';
import '../providers/messages_controller.dart';
import '../widgets/messages_l10n.dart';
import '../widgets/messages_sheets.dart';
import '../widgets/messages_skeleton.dart';

/// หน้ารายการข้อความแชท (/messages) — ตรงเว็บ prototype (www.แมว.live/messages)
class MessagesPage extends ConsumerStatefulWidget {
  const MessagesPage({super.key});

  @override
  ConsumerState<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends ConsumerState<MessagesPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String? _toast;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _unfocusSearch() {
    _searchFocus.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _unfocusAfterSheet() {
    _unfocusSearch();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _unfocusSearch();
    });
  }

  void _showToast(String msg) {
    setState(() => _toast = msg);
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted && _toast == msg) setState(() => _toast = null);
    });
  }

  Future<void> _openThread(ChatThread thread) async {
    _unfocusSearch();
    await ref.read(messagesControllerProvider.notifier).markRead(thread.id);
    if (!mounted) return;
    context.push('/messages/${thread.id}');
  }

  Future<void> _openNewMessage(MessagesState state, MessagesL10n l10n) async {
    _unfocusSearch();
    final peer = await showNewMessageSheet(
      context,
      contacts: state.suggestedContacts,
      l10n: l10n,
    );
    _unfocusAfterSheet();
    if (peer == null || !mounted) return;
    final thread = await ref
        .read(messagesControllerProvider.notifier)
        .openOrCreateForPeer(peer);
    if (!mounted) return;
    context.push('/messages/${thread.id}');
  }

  Future<void> _openNote(MessageNote note, MessagesL10n l10n) async {
    _unfocusSearch();
    if (note.isMine) {
      final updated = await showEditNoteSheet(
        context,
        initialNote: note.noteText,
        l10n: l10n,
      );
      _unfocusAfterSheet();
      if (updated != null && mounted) {
        await ref
            .read(messagesControllerProvider.notifier)
            .updateMyNote(updated);
      }
      return;
    }
    final state = ref.read(messagesControllerProvider);
    final match = state.threads.where((t) => t.peer.id == note.userId);
    if (match.isNotEmpty) {
      await _openThread(match.first);
    }
  }

  Future<void> _openThreadOptions(ChatThread thread, MessagesL10n l10n) async {
    _unfocusSearch();
    final action = await showThreadOptionsSheet(
      context,
      thread: thread,
      l10n: l10n,
    );
    _unfocusAfterSheet();
    if (action == null || !mounted) return;
    final controller = ref.read(messagesControllerProvider.notifier);
    switch (action) {
      case ThreadSheetAction.pin:
        await controller.togglePin(thread.id);
      case ThreadSheetAction.toggleRead:
        await controller.toggleRead(thread.id);
      case ThreadSheetAction.mute:
        await controller.toggleMute(thread.id);
      case ThreadSheetAction.moveBox:
        final nextBox = thread.box == MessagesBoxTab.general
            ? MessagesBoxTab.primary
            : MessagesBoxTab.general;
        await controller.moveToBox(thread.id, nextBox);
      case ThreadSheetAction.block:
        final ok = await showDangerConfirmSheet(
          context,
          title: l10n.blockConfirmTitle(thread.peer.handle),
          description: l10n.blockConfirmDesc(thread.peer.handle),
          cancelLabel: l10n.cancel,
          confirmLabel: l10n.block,
        );
        _unfocusAfterSheet();
        if (!ok || !mounted) return;
        await controller.blockThread(thread.id);
        if (mounted) _showToast('บล็อก ${thread.peer.handle} แล้ว');
      case ThreadSheetAction.delete:
        final ok = await showDangerConfirmSheet(
          context,
          title: l10n.deleteConfirmTitle,
          description: l10n.deleteConfirmDesc,
          cancelLabel: l10n.cancel,
          confirmLabel: l10n.deleteAction,
        );
        _unfocusAfterSheet();
        if (!ok || !mounted) return;
        await controller.deleteThread(thread.id);
        if (mounted) _showToast('ลบแชทแล้ว');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(messagesControllerProvider);
    final controller = ref.read(messagesControllerProvider.notifier);
    final l10n = MessagesL10n(ref.watch(appLocaleProvider) == 'en');

    return Scaffold(
      backgroundColor: AppColors.page,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _MessagesHeader(
                  l10n: l10n,
                  onBack: () => context.pop(),
                  onManage: () async {
                    _unfocusSearch();
                    await showManageMessagesSheet(context, l10n: l10n);
                    _unfocusAfterSheet();
                  },
                  onNewMessage: () => _openNewMessage(state, l10n),
                ),
                _MessagesTabs(
                  l10n: l10n,
                  selected: state.tab,
                  requestCount: state.requestCount,
                  onSelect: controller.selectTab,
                ),
                Expanded(
                  child: switch (state.status) {
                    MessagesStatus.loading => const MessagesSkeleton(),
                    MessagesStatus.error => _MessagesError(
                      message: state.error?.message ?? 'โหลดข้อมูลไม่สำเร็จ',
                      retryLabel: l10n.retry,
                      onRetry: controller.load,
                    ),
                    MessagesStatus.ready => _MessagesContent(
                      state: state,
                      l10n: l10n,
                      searchCtrl: _searchCtrl,
                      searchFocus: _searchFocus,
                      onSearchChanged: controller.setQuery,
                      onClearFilter: () =>
                          controller.toggleFilter(state.filter),
                      onTapNote: (n) => _openNote(n, l10n),
                      onOpenThread: _openThread,
                      onOpenOptions: (t) => _openThreadOptions(t, l10n),
                    ),
                  },
                ),
              ],
            ),
          ),
          if (_toast != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 36,
              child: IgnorePointer(
                child: Center(child: ToastPill(message: _toast!)),
              ),
            ),
        ],
      ),
    );
  }
}

class _MessagesHeader extends StatelessWidget {
  const _MessagesHeader({
    required this.l10n,
    required this.onBack,
    required this.onManage,
    required this.onNewMessage,
  });

  final MessagesL10n l10n;
  final VoidCallback onBack;
  final VoidCallback onManage;
  final VoidCallback onNewMessage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 8, 8, 4),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: l10n.back,
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
          Expanded(
            child: Text(
              l10n.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
          ),
          Semantics(
            button: true,
            label: l10n.manage,
            child: InkWell(
              onTap: onManage,
              borderRadius: BorderRadius.circular(14),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  LucideIcons.slidersHorizontal,
                  size: 22,
                  color: AppColors.text,
                ),
              ),
            ),
          ),
          Semantics(
            button: true,
            label: l10n.newMessage,
            child: InkWell(
              onTap: onNewMessage,
              borderRadius: BorderRadius.circular(14),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  LucideIcons.squarePen,
                  size: 22,
                  color: AppColors.text,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessagesTabs extends StatelessWidget {
  const _MessagesTabs({
    required this.l10n,
    required this.selected,
    required this.requestCount,
    required this.onSelect,
  });

  final MessagesL10n l10n;
  final MessagesBoxTab selected;
  final int requestCount;
  final ValueChanged<MessagesBoxTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final items = [
      (MessagesBoxTab.primary, l10n.tabPrimary),
      (MessagesBoxTab.general, l10n.tabGeneral),
      (MessagesBoxTab.requests, l10n.tabRequests(requestCount)),
    ];
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          for (final item in items)
            Expanded(
              child: Semantics(
                button: true,
                selected: selected == item.$1,
                label: item.$2,
                child: InkWell(
                  onTap: () => onSelect(item.$1),
                  child: SizedBox(
                    height: 44,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          item.$2,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: selected == item.$1
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: selected == item.$1
                                ? AppColors.text
                                : AppColors.muted,
                          ),
                        ),
                        if (selected == item.$1)
                          Positioned(
                            left: 22,
                            right: 22,
                            bottom: 0,
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: AppColors.ink,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                      ],
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

class _MessagesContent extends StatelessWidget {
  const _MessagesContent({
    required this.state,
    required this.l10n,
    required this.searchCtrl,
    required this.searchFocus,
    required this.onSearchChanged,
    required this.onClearFilter,
    required this.onTapNote,
    required this.onOpenThread,
    required this.onOpenOptions,
  });

  final MessagesState state;
  final MessagesL10n l10n;
  final TextEditingController searchCtrl;
  final FocusNode searchFocus;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearFilter;
  final ValueChanged<MessageNote> onTapNote;
  final ValueChanged<ChatThread> onOpenThread;
  final ValueChanged<ChatThread> onOpenOptions;

  @override
  Widget build(BuildContext context) {
    final threads = state.visibleThreads;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.soft,
                  borderRadius: BorderRadius.circular(22),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.search,
                      size: 18,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: searchCtrl,
                        focusNode: searchFocus,
                        onChanged: onSearchChanged,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.text,
                        ),
                        decoration: InputDecoration(
                          hintText: l10n.searchHint,
                          hintStyle: const TextStyle(
                            fontSize: 15,
                            color: AppColors.muted,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    if (state.query.isNotEmpty)
                      InkWell(
                        onTap: () {
                          searchCtrl.clear();
                          onSearchChanged('');
                        },
                        child: const Icon(
                          LucideIcons.x,
                          size: 18,
                          color: AppColors.muted,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (state.filter != MessagesFilter.all)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Chip(
                      label: Text(_filterLabel(state.filter, l10n)),
                      onDeleted: onClearFilter,
                      backgroundColor: AppColors.btn,
                      side: const BorderSide(color: AppColors.btnBorder),
                      labelStyle: const TextStyle(
                        fontSize: 12,
                        color: AppColors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (state.notes.isNotEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 118,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                  itemCount: state.notes.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => _NoteCard(
                    note: state.notes[i],
                    l10n: l10n,
                    onTap: () => onTapNote(state.notes[i]),
                  ),
                ),
              ),
            ),
          if (threads.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    state.query.isNotEmpty ? l10n.emptySearch : l10n.emptyTitle,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.muted,
                    ),
                  ),
                ),
              ),
            )
          else
            SliverList.builder(
              itemCount: threads.length,
              itemBuilder: (_, i) {
                final t = threads[i];
                return _ThreadRow(
                  thread: t,
                  showPreview: state.settings.showMessagePreview,
                  l10n: l10n,
                  onTap: () => onOpenThread(t),
                  onOptions: () => onOpenOptions(t),
                );
              },
            ),
        ],
      ),
    );
  }

  String _filterLabel(MessagesFilter filter, MessagesL10n l10n) =>
      switch (filter) {
        MessagesFilter.unread => l10n.filterUnread,
        MessagesFilter.unanswered => l10n.filterUnanswered,
        MessagesFilter.pinned => l10n.filterPinned,
        MessagesFilter.muted => l10n.filterMuted,
        MessagesFilter.all => '',
      };
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.note,
    required this.l10n,
    required this.onTap,
  });

  final MessageNote note;
  final MessagesL10n l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = note.isMine ? l10n.yourNote : note.handle;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 82,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Positioned(
                top: 24,
                child: AppAvatar(
                  source: note.avatarSource,
                  bg: note.avatarBg,
                  size: 62,
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.line),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0D4A3428),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    note.noteText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.2,
                      color: AppColors.text,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThreadRow extends StatelessWidget {
  const _ThreadRow({
    required this.thread,
    required this.showPreview,
    required this.l10n,
    required this.onTap,
    required this.onOptions,
  });

  final ChatThread thread;
  final bool showPreview;
  final MessagesL10n l10n;
  final VoidCallback onTap;
  final VoidCallback onOptions;

  @override
  Widget build(BuildContext context) {
    final preview = showPreview
        ? (thread.lastSentByMe
              ? '${l10n.youPrefix}${thread.lastMessagePreview}'
              : thread.lastMessagePreview)
        : l10n.hiddenPreview;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
        child: Row(
          children: [
            AppAvatar(
              source: thread.peer.avatarSource,
              bg: thread.peer.avatarBg,
              size: 54,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          thread.peer.handle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: thread.isUnread
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                      if (thread.isPinned) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          LucideIcons.pin,
                          size: 13,
                          color: AppColors.muted,
                        ),
                      ],
                      if (thread.isMuted) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          LucideIcons.bellOff,
                          size: 13,
                          color: AppColors.muted,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    preview.isEmpty
                        ? thread.lastTimeText
                        : '$preview · ${thread.lastTimeText}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: thread.isUnread
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: thread.isUnread ? AppColors.text : AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (thread.isUnread)
              Container(
                width: 9,
                height: 9,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: const BoxDecoration(
                  color: AppColors.ink,
                  shape: BoxShape.circle,
                ),
              ),
            Semantics(
              button: true,
              label: 'ตัวเลือกแชทกับ ${thread.peer.handle}',
              child: InkWell(
                onTap: onOptions,
                borderRadius: BorderRadius.circular(999),
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(
                    LucideIcons.ellipsis,
                    size: 18,
                    color: AppColors.muted,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessagesError extends StatelessWidget {
  const _MessagesError({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: AppColors.muted),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.btn,
                foregroundColor: AppColors.ink,
              ),
              child: Text(retryLabel),
            ),
          ],
        ),
      ),
    );
  }
}

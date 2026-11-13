import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../data/datasources/mock_messages_data_source.dart';
import '../../data/repositories/messages_repository_impl.dart';
import '../../domain/entities/messages_data.dart';
import '../../domain/repositories/messages_repository.dart';
import '../../domain/usecases/messages_usecases.dart';

enum MessagesStatus { loading, ready, error }

class MessagesState {
  const MessagesState({
    this.status = MessagesStatus.loading,
    this.tab = MessagesBoxTab.primary,
    this.filter = MessagesFilter.all,
    this.query = '',
    this.notes = const [],
    this.threads = const [],
    this.suggestedContacts = const [],
    this.settings = const MessagesSettings(),
    this.error,
  });

  final MessagesStatus status;
  final MessagesBoxTab tab;
  final MessagesFilter filter;
  final String query;
  final List<MessageNote> notes;
  final List<ChatThread> threads;
  final List<ChatUser> suggestedContacts;
  final MessagesSettings settings;
  final Failure? error;

  int get requestCount =>
      threads.where((t) => t.box == MessagesBoxTab.requests).length;

  int get unreadTotalCount =>
      threads.where((t) => t.isUnread && !t.isMuted).length;

  List<ChatThread> get visibleThreads {
    final q = query.trim().toLowerCase();
    final filtered = threads.where((t) {
      if (t.box != tab) return false;
      if (q.isNotEmpty) {
        final matchHandle = t.peer.handle.toLowerCase().contains(q);
        final matchName = t.peer.name.toLowerCase().contains(q);
        final matchPreview = t.lastMessagePreview.toLowerCase().contains(q);
        if (!matchHandle && !matchName && !matchPreview) return false;
      }
      return switch (filter) {
        MessagesFilter.all => true,
        MessagesFilter.unread => t.isUnread,
        MessagesFilter.unanswered => t.isUnanswered,
        MessagesFilter.pinned => t.isPinned,
        MessagesFilter.muted => t.isMuted,
      };
    }).toList();

    filtered.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return 0;
    });
    return filtered;
  }

  ChatThread? threadById(String id) {
    for (final t in threads) {
      if (t.id == id) return t;
    }
    return null;
  }

  MessagesState copyWith({
    MessagesStatus? status,
    MessagesBoxTab? tab,
    MessagesFilter? filter,
    String? query,
    List<MessageNote>? notes,
    List<ChatThread>? threads,
    List<ChatUser>? suggestedContacts,
    MessagesSettings? settings,
    Failure? error,
    bool clearError = false,
  }) => MessagesState(
    status: status ?? this.status,
    tab: tab ?? this.tab,
    filter: filter ?? this.filter,
    query: query ?? this.query,
    notes: notes ?? this.notes,
    threads: threads ?? this.threads,
    suggestedContacts: suggestedContacts ?? this.suggestedContacts,
    settings: settings ?? this.settings,
    error: clearError ? null : (error ?? this.error),
  );
}

final messagesRepositoryProvider = Provider<MessagesRepository>((ref) {
  return MessagesRepositoryImpl(MockMessagesDataSource());
});

final messagesControllerProvider =
    NotifierProvider<MessagesController, MessagesState>(MessagesController.new);

class MessagesController extends Notifier<MessagesState> {
  late final GetMessagesInbox _getInbox;
  late final SendChatMessage _sendMessage;
  late final OpenOrCreateThread _openOrCreate;
  late final UpdateMyMessageNote _updateNote;
  late final UpdateMessagesSettings _updateSettings;
  late final ManageChatThread _manage;

  @override
  MessagesState build() {
    final repo = ref.read(messagesRepositoryProvider);
    _getInbox = GetMessagesInbox(repo);
    _sendMessage = SendChatMessage(repo);
    _openOrCreate = OpenOrCreateThread(repo);
    _updateNote = UpdateMyMessageNote(repo);
    _updateSettings = UpdateMessagesSettings(repo);
    _manage = ManageChatThread(repo);
    Future.microtask(load);
    return const MessagesState();
  }

  Future<void> load({bool showSkeleton = true}) async {
    if (showSkeleton) {
      state = state.copyWith(status: MessagesStatus.loading, clearError: true);
    }
    try {
      final data = await _getInbox();
      state = state.copyWith(
        status: MessagesStatus.ready,
        notes: data.notes,
        threads: data.threads,
        suggestedContacts: data.suggestedContacts,
        settings: data.settings,
        clearError: true,
      );
    } on Failure catch (f) {
      state = state.copyWith(status: MessagesStatus.error, error: f);
    } catch (_) {
      state = state.copyWith(
        status: MessagesStatus.error,
        error: const UnknownFailure('โหลดข้อความไม่สำเร็จ กรุณาลองใหม่'),
      );
    }
  }

  void selectTab(MessagesBoxTab tab) {
    state = state.copyWith(tab: tab);
  }

  void setQuery(String query) {
    state = state.copyWith(query: query);
  }

  void toggleFilter(MessagesFilter filter) {
    final next = state.filter == filter ? MessagesFilter.all : filter;
    state = state.copyWith(filter: next);
  }

  Future<void> updateSettings(MessagesSettings settings) async {
    state = state.copyWith(settings: settings);
    await _updateSettings(settings);
  }

  Future<void> updateMyNote(String noteText) async {
    await _updateNote(noteText);
    await load(showSkeleton: false);
  }

  Future<void> markRead(String threadId) async {
    await _manage.setUnread(threadId, unread: false);
    state = state.copyWith(
      threads: state.threads
          .map((t) => t.id == threadId ? t.copyWith(isUnread: false) : t)
          .toList(),
    );
  }

  Future<void> toggleRead(String threadId) async {
    final target = state.threadById(threadId);
    if (target == null) return;
    final nextUnread = !target.isUnread;
    await _manage.setUnread(threadId, unread: nextUnread);
    state = state.copyWith(
      threads: state.threads
          .map((t) => t.id == threadId ? t.copyWith(isUnread: nextUnread) : t)
          .toList(),
    );
  }

  Future<void> togglePin(String threadId) async {
    await _manage.togglePin(threadId);
    state = state.copyWith(
      threads: state.threads
          .map((t) => t.id == threadId ? t.copyWith(isPinned: !t.isPinned) : t)
          .toList(),
    );
  }

  Future<void> toggleMute(String threadId) async {
    await _manage.toggleMute(threadId);
    state = state.copyWith(
      threads: state.threads
          .map((t) => t.id == threadId ? t.copyWith(isMuted: !t.isMuted) : t)
          .toList(),
    );
  }

  Future<void> moveToBox(String threadId, MessagesBoxTab box) async {
    await _manage.moveToBox(threadId, box);
    state = state.copyWith(
      threads: state.threads
          .map((t) => t.id == threadId ? t.copyWith(box: box) : t)
          .toList(),
    );
  }

  Future<void> blockThread(String threadId) async {
    await _manage.block(threadId);
    state = state.copyWith(
      threads: state.threads.where((t) => t.id != threadId).toList(),
    );
  }

  Future<void> deleteThread(String threadId) async {
    await _manage.delete(threadId);
    state = state.copyWith(
      threads: state.threads.where((t) => t.id != threadId).toList(),
    );
  }

  Future<ChatThread> openOrCreateForPeer(ChatUser peer) async {
    if (state.status != MessagesStatus.ready) {
      await load(showSkeleton: false);
    }
    final thread = await _openOrCreate(peer);
    await load(showSkeleton: false);
    return thread;
  }

  Future<void> sendMessage({
    required String threadId,
    required String text,
    String? imagePath,
  }) async {
    await _sendMessage(threadId: threadId, text: text, imagePath: imagePath);
    await load(showSkeleton: false);
  }
}

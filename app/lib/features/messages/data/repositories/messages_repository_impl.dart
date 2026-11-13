import '../../domain/entities/messages_data.dart';
import '../../domain/repositories/messages_repository.dart';
import '../datasources/mock_messages_data_source.dart';

class MessagesRepositoryImpl implements MessagesRepository {
  MessagesRepositoryImpl(this._mock);
  final MockMessagesDataSource _mock;

  @override
  Future<MessagesInboxData> getInbox() => _mock.getInbox();

  @override
  Future<void> updateMyNote(String noteText) => _mock.updateMyNote(noteText);

  @override
  Future<void> updateSettings(MessagesSettings settings) =>
      _mock.updateSettings(settings);

  @override
  Future<ChatThread> sendMessage({
    required String threadId,
    required String text,
    String? imagePath,
  }) => _mock.sendMessage(threadId: threadId, text: text, imagePath: imagePath);

  @override
  Future<ChatThread> openOrCreateThread(ChatUser peer) =>
      _mock.openOrCreateThread(peer);

  @override
  Future<void> togglePin(String threadId) => _mock.togglePin(threadId);

  @override
  Future<void> setUnread(String threadId, {required bool unread}) =>
      _mock.setUnread(threadId, unread: unread);

  @override
  Future<void> toggleMute(String threadId) => _mock.toggleMute(threadId);

  @override
  Future<void> moveToBox(String threadId, MessagesBoxTab box) =>
      _mock.moveToBox(threadId, box);

  @override
  Future<void> blockThread(String threadId) => _mock.blockThread(threadId);

  @override
  Future<void> deleteThread(String threadId) => _mock.deleteThread(threadId);
}

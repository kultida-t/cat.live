import '../entities/messages_data.dart';
import '../repositories/messages_repository.dart';

class GetMessagesInbox {
  const GetMessagesInbox(this._repo);
  final MessagesRepository _repo;

  Future<MessagesInboxData> call() => _repo.getInbox();
}

class SendChatMessage {
  const SendChatMessage(this._repo);
  final MessagesRepository _repo;

  Future<ChatThread> call({
    required String threadId,
    required String text,
    String? imagePath,
  }) => _repo.sendMessage(threadId: threadId, text: text, imagePath: imagePath);
}

class OpenOrCreateThread {
  const OpenOrCreateThread(this._repo);
  final MessagesRepository _repo;

  Future<ChatThread> call(ChatUser peer) => _repo.openOrCreateThread(peer);
}

class UpdateMyMessageNote {
  const UpdateMyMessageNote(this._repo);
  final MessagesRepository _repo;

  Future<void> call(String noteText) => _repo.updateMyNote(noteText);
}

class UpdateMessagesSettings {
  const UpdateMessagesSettings(this._repo);
  final MessagesRepository _repo;

  Future<void> call(MessagesSettings settings) =>
      _repo.updateSettings(settings);
}

class ManageChatThread {
  const ManageChatThread(this._repo);
  final MessagesRepository _repo;

  Future<void> togglePin(String id) => _repo.togglePin(id);
  Future<void> setUnread(String id, {required bool unread}) =>
      _repo.setUnread(id, unread: unread);
  Future<void> toggleMute(String id) => _repo.toggleMute(id);
  Future<void> moveToBox(String id, MessagesBoxTab box) =>
      _repo.moveToBox(id, box);
  Future<void> block(String id) => _repo.blockThread(id);
  Future<void> delete(String id) => _repo.deleteThread(id);
}

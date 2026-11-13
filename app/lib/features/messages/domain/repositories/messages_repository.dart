import '../entities/messages_data.dart';

/// สัญญาดึงและจัดการข้อมูลกล่องข้อความแชท
abstract class MessagesRepository {
  Future<MessagesInboxData> getInbox();

  Future<void> updateMyNote(String noteText);

  Future<void> updateSettings(MessagesSettings settings);

  Future<ChatThread> sendMessage({
    required String threadId,
    required String text,
    String? imagePath,
  });

  Future<ChatThread> openOrCreateThread(ChatUser peer);

  Future<void> togglePin(String threadId);

  Future<void> setUnread(String threadId, {required bool unread});

  Future<void> toggleMute(String threadId);

  Future<void> moveToBox(String threadId, MessagesBoxTab box);

  Future<void> blockThread(String threadId);

  Future<void> deleteThread(String threadId);
}

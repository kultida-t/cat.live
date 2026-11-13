/// แท็บกล่องข้อความบนหน้า /messages
enum MessagesBoxTab { primary, general, requests }

/// ตัวกรองในแผ่น "จัดการข้อความ" -> "แสดงเฉพาะ"
enum MessagesFilter { all, unread, unanswered, pinned, muted }

/// ข้อมูลผู้ใช้คู่สนทนาในระบบข้อความ
class ChatUser {
  const ChatUser({
    required this.id,
    required this.handle,
    required this.name,
    required this.avatarSource,
    required this.avatarBg,
    this.lastActiveText = 'ใช้งานล่าสุดเมื่อสักครู่',
    this.relationText = 'แมว.live · ผู้ติดตามซึ่งกันและกัน',
  });

  final String id;
  final String handle;
  final String name;
  final String avatarSource;
  final int avatarBg;
  final String lastActiveText;
  final String relationText;
}

/// การ์ดโน้ตสั้น ๆ ด้านบนหน้ารายการข้อความ
class MessageNote {
  const MessageNote({
    required this.id,
    required this.userId,
    required this.handle,
    required this.avatarSource,
    required this.avatarBg,
    required this.noteText,
    this.isMine = false,
  });

  final String id;
  final String userId;
  final String handle;
  final String avatarSource;
  final int avatarBg;
  final String noteText;
  final bool isMine;

  MessageNote copyWith({String? noteText}) => MessageNote(
    id: id,
    userId: userId,
    handle: handle,
    avatarSource: avatarSource,
    avatarBg: avatarBg,
    noteText: noteText ?? this.noteText,
    isMine: isMine,
  );
}

/// ข้อความหนึ่งรายการภายในห้องแชท
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.isMine,
    required this.text,
    required this.timeText,
    this.imagePath,
  });

  final String id;
  final String senderId;
  final bool isMine;
  final String text;
  final String timeText;
  final String? imagePath;
}

/// ห้องแชทหนึ่งห้องในรายการข้อความ
class ChatThread {
  const ChatThread({
    required this.id,
    required this.box,
    required this.peer,
    required this.lastMessagePreview,
    required this.lastTimeText,
    required this.messages,
    this.isUnread = false,
    this.isUnanswered = false,
    this.isPinned = false,
    this.isMuted = false,
    this.isBlocked = false,
    this.lastSentByMe = false,
  });

  final String id;
  final MessagesBoxTab box;
  final ChatUser peer;
  final String lastMessagePreview;
  final String lastTimeText;
  final List<ChatMessage> messages;
  final bool isUnread;
  final bool isUnanswered;
  final bool isPinned;
  final bool isMuted;
  final bool isBlocked;
  final bool lastSentByMe;

  ChatThread copyWith({
    MessagesBoxTab? box,
    ChatUser? peer,
    String? lastMessagePreview,
    String? lastTimeText,
    List<ChatMessage>? messages,
    bool? isUnread,
    bool? isUnanswered,
    bool? isPinned,
    bool? isMuted,
    bool? isBlocked,
    bool? lastSentByMe,
  }) => ChatThread(
    id: id,
    box: box ?? this.box,
    peer: peer ?? this.peer,
    lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
    lastTimeText: lastTimeText ?? this.lastTimeText,
    messages: messages ?? this.messages,
    isUnread: isUnread ?? this.isUnread,
    isUnanswered: isUnanswered ?? this.isUnanswered,
    isPinned: isPinned ?? this.isPinned,
    isMuted: isMuted ?? this.isMuted,
    isBlocked: isBlocked ?? this.isBlocked,
    lastSentByMe: lastSentByMe ?? this.lastSentByMe,
  );
}

/// การตั้งค่า 3 สวิตช์ในแผ่น "จัดการข้อความ"
class MessagesSettings {
  const MessagesSettings({
    this.allowRequests = true,
    this.showReadReceipts = true,
    this.showMessagePreview = true,
  });

  final bool allowRequests;
  final bool showReadReceipts;
  final bool showMessagePreview;

  MessagesSettings copyWith({
    bool? allowRequests,
    bool? showReadReceipts,
    bool? showMessagePreview,
  }) => MessagesSettings(
    allowRequests: allowRequests ?? this.allowRequests,
    showReadReceipts: showReadReceipts ?? this.showReadReceipts,
    showMessagePreview: showMessagePreview ?? this.showMessagePreview,
  );
}

/// ข้อมูลทั้งหมดของกล่องข้อความ (/messages)
class MessagesInboxData {
  const MessagesInboxData({
    required this.notes,
    required this.threads,
    required this.settings,
    required this.suggestedContacts,
  });

  final List<MessageNote> notes;
  final List<ChatThread> threads;
  final MessagesSettings settings;
  final List<ChatUser> suggestedContacts;
}

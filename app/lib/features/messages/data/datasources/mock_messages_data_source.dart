import '../../../feed/data/datasources/mock_accounts.dart';
import '../../domain/entities/messages_data.dart';

/// แหล่งข้อมูลจำลองสำหรับกล่องข้อความ (/messages) — ตรงกับเว็บ prototype (www.แมว.live)
class MockMessagesDataSource {
  MockMessagesDataSource() {
    _resetSeed();
  }

  late List<MessageNote> _notes;
  late List<ChatThread> _threads;
  MessagesSettings _settings = const MessagesSettings();

  static ChatUser userFromMockKey(
    String key, {
    String lastActiveText = 'ใช้งานล่าสุดเมื่อสักครู่',
    String relationText = 'แมว.live · ผู้ติดตามซึ่งกันและกัน',
  }) {
    final json = mockAccountJson(key);
    return ChatUser(
      id: json['id'] as String,
      handle: json['handle'] as String,
      name: json['name'] as String,
      avatarSource: json['avatar_url'] as String,
      avatarBg: json['avatar_bg'] as int,
      lastActiveText: lastActiveText,
      relationText: relationText,
    );
  }

  void _resetSeed() {
    final me = userFromMockKey(mockMe);
    final noon = userFromMockKey(
      'noon',
      lastActiveText: 'ใช้งานล่าสุด 38 นาทีที่แล้ว',
    );
    final vet = userFromMockKey(
      'vet',
      lastActiveText: 'ใช้งานล่าสุด 2 ชม. ที่แล้ว',
      relationText: 'แมว.live · สัตวแพทย์และผู้ติดตาม',
    );
    final rescue = userFromMockKey(
      'rescue',
      lastActiveText: 'ใช้งานล่าสุด 12 ชม. ที่แล้ว',
    );
    final som = userFromMockKey(
      'som',
      lastActiveText: 'ใช้งานล่าสุด 14 ชม. ที่แล้ว',
    );
    final muk = userFromMockKey(
      'muk',
      lastActiveText: 'ใช้งานล่าสุด 1 วันที่แล้ว',
    );
    final guy = userFromMockKey(
      'guy',
      lastActiveText: 'ใช้งานล่าสุด 2 วันที่แล้ว',
      relationText: 'แมว.live · ยังไม่ได้ติดตามกัน',
    );

    _notes = [
      MessageNote(
        id: 'note-me',
        userId: me.id,
        handle: 'โน้ตของคุณ',
        avatarSource: me.avatarSource,
        avatarBg: me.avatarBg,
        noteText: 'มีแผนวันหยุดหรือยัง?',
        isMine: true,
      ),
      MessageNote(
        id: 'note-noon',
        userId: noon.id,
        handle: noon.handle,
        avatarSource: noon.avatarSource,
        avatarBg: noon.avatarBg,
        noteText: 'โมจิไม่ยอมตื่นเลย 😴',
      ),
      MessageNote(
        id: 'note-vet',
        userId: vet.id,
        handle: vet.handle,
        avatarSource: vet.avatarSource,
        avatarBg: vet.avatarBg,
        noteText: 'ถามเรื่องวัคซีนได้นะคะ',
      ),
      MessageNote(
        id: 'note-rescue',
        userId: rescue.id,
        handle: rescue.handle,
        avatarSource: rescue.avatarSource,
        avatarBg: rescue.avatarBg,
        noteText: 'ยังหาบ้านให้ลูกแมว 3 ตัว 🙏',
      ),
      MessageNote(
        id: 'note-som',
        userId: som.id,
        handle: som.handle,
        avatarSource: som.avatarSource,
        avatarBg: som.avatarBg,
        noteText: 'ส้มจี๊ดกินจุมาก',
      ),
    ];

    _threads = [
      ChatThread(
        id: 't-noon',
        box: MessagesBoxTab.primary,
        peer: noon,
        lastMessagePreview: '🤣🤣',
        lastTimeText: '38 นาที',
        isUnread: true,
        isUnanswered: true,
        messages: const [
          ChatMessage(
            id: 'm-noon-1',
            senderId: mockMe,
            isMine: true,
            text: 'รูปโมจิกอดตุ๊กตาน่ารักมาก',
            timeText: '10:12',
          ),
          ChatMessage(
            id: 'm-noon-2',
            senderId: 'noon',
            isMine: false,
            text: 'ขอบคุณค่า นอนแบบนี้ทั้งเช้าเลย',
            timeText: '10:15',
          ),
          ChatMessage(
            id: 'm-noon-3',
            senderId: 'noon',
            isMine: false,
            text: '🤣🤣',
            timeText: '10:15',
          ),
        ],
      ),
      ChatThread(
        id: 't-vet',
        box: MessagesBoxTab.primary,
        peer: vet,
        lastMessagePreview:
            'ไม่ต้องงดค่ะ แต่ถ้าน้องมีอาการป่วยอยู่ให้เลื่อนก่อนนะคะ',
        lastTimeText: '2 ชม.',
        isUnread: true,
        isUnanswered: true,
        messages: const [
          ChatMessage(
            id: 'm-vet-1',
            senderId: mockMe,
            isMine: true,
            text: 'คุณหมอคะ พามะลิไปฉีดวัคซีนต้องงดอาหารก่อนไหมคะ',
            timeText: '08:20',
          ),
          ChatMessage(
            id: 'm-vet-2',
            senderId: 'vet',
            isMine: false,
            text: 'ไม่ต้องงดค่ะ แต่ถ้าน้องมีอาการป่วยอยู่ให้เลื่อนก่อนนะคะ',
            timeText: '08:45',
          ),
        ],
      ),
      ChatThread(
        id: 't-rescue',
        box: MessagesBoxTab.primary,
        peer: rescue,
        lastMessagePreview: 'ได้เลยค่ะ เดี๋ยวส่งให้ตอนเย็น',
        lastTimeText: '12 ชม.',
        isUnread: true,
        isUnanswered: true,
        messages: const [
          ChatMessage(
            id: 'm-res-1',
            senderId: mockMe,
            isMine: true,
            text: 'ขอรายละเอียดพิกัดรับลูกแมวหน่อยค่ะ เดี๋ยวช่วยแชร์ให้',
            timeText: 'เมื่อวาน',
          ),
          ChatMessage(
            id: 'm-res-2',
            senderId: 'rescue',
            isMine: false,
            text: 'ได้เลยค่ะ เดี๋ยวส่งให้ตอนเย็น',
            timeText: 'เมื่อวาน',
          ),
        ],
      ),
      ChatThread(
        id: 't-som',
        box: MessagesBoxTab.primary,
        peer: som,
        lastMessagePreview: 'ถึงแล้ว',
        lastTimeText: '14 ชม.',
        lastSentByMe: true,
        messages: const [
          ChatMessage(
            id: 'm-som-1',
            senderId: 'som',
            isMine: false,
            text: 'ขนมแมวเลียที่ฝากสั่งมาส่งแล้วนะ',
            timeText: 'เมื่อวาน',
          ),
          ChatMessage(
            id: 'm-som-2',
            senderId: mockMe,
            isMine: true,
            text: 'ถึงแล้ว',
            timeText: 'เมื่อวาน',
          ),
        ],
      ),
      ChatThread(
        id: 't-muk',
        box: MessagesBoxTab.general,
        peer: muk,
        lastMessagePreview: 'คาเฟ่ที่อารีย์เปิดวันเสาร์ด้วยนะ 😂',
        lastTimeText: '1 วัน',
        isUnanswered: true,
        messages: const [
          ChatMessage(
            id: 'm-muk-1',
            senderId: 'muk',
            isMine: false,
            text: 'คาเฟ่ที่อารีย์เปิดวันเสาร์ด้วยนะ 😂',
            timeText: '1 วัน',
          ),
        ],
      ),
      ChatThread(
        id: 't-guy',
        box: MessagesBoxTab.requests,
        peer: guy,
        lastMessagePreview: 'สวัสดีครับ ขอถามเรื่องแมวสูงอายุหน่อยครับ',
        lastTimeText: '2 วัน',
        isUnanswered: true,
        messages: const [
          ChatMessage(
            id: 'm-guy-1',
            senderId: 'guy',
            isMine: false,
            text: 'สวัสดีครับ ขอถามเรื่องแมวสูงอายุหน่อยครับ',
            timeText: '2 วัน',
          ),
        ],
      ),
    ];
  }

  Future<MessagesInboxData> getInbox() async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    final contacts = mockAccountKeys
        .where((k) => k != mockMe)
        .map((k) => userFromMockKey(k))
        .toList();
    return MessagesInboxData(
      notes: List.unmodifiable(_notes),
      threads: List.unmodifiable(_threads.where((t) => !t.isBlocked)),
      settings: _settings,
      suggestedContacts: contacts,
    );
  }

  Future<void> updateMyNote(String noteText) async {
    final trimmed = noteText.trim();
    _notes = _notes
        .map((n) => n.isMine ? n.copyWith(noteText: trimmed) : n)
        .toList();
  }

  Future<void> updateSettings(MessagesSettings settings) async {
    _settings = settings;
  }

  Future<ChatThread> sendMessage({
    required String threadId,
    required String text,
    String? imagePath,
  }) async {
    final idx = _threads.indexWhere((t) => t.id == threadId);
    if (idx < 0) {
      throw StateError('ไม่พบห้องแชท');
    }
    final current = _threads[idx];
    final trimmed = text.trim();
    final msg = ChatMessage(
      id: 'm-${DateTime.now().microsecondsSinceEpoch}',
      senderId: mockMe,
      isMine: true,
      text: trimmed,
      imagePath: imagePath,
      timeText: 'เมื่อสักครู่',
    );
    final preview = trimmed.isNotEmpty
        ? trimmed
        : (imagePath != null ? 'ส่งรูปภาพ' : '');
    final updated = current.copyWith(
      box: current.box == MessagesBoxTab.requests
          ? MessagesBoxTab.primary
          : current.box,
      messages: [...current.messages, msg],
      lastMessagePreview: preview,
      lastTimeText: 'เมื่อสักครู่',
      isUnread: false,
      isUnanswered: false,
      lastSentByMe: true,
    );
    _threads = [
      updated,
      for (int i = 0; i < _threads.length; i++)
        if (i != idx) _threads[i],
    ];
    return updated;
  }

  Future<ChatThread> openOrCreateThread(ChatUser peer) async {
    final existing = _threads.where(
      (t) => t.peer.id == peer.id || t.peer.handle == peer.handle,
    );
    if (existing.isNotEmpty) {
      return existing.first;
    }
    final created = ChatThread(
      id: 't-${peer.id}',
      box: MessagesBoxTab.primary,
      peer: peer,
      lastMessagePreview: '',
      lastTimeText: 'ใหม่',
      messages: const [],
    );
    _threads = [created, ..._threads];
    return created;
  }

  Future<void> togglePin(String threadId) async {
    _threads = _threads
        .map((t) => t.id == threadId ? t.copyWith(isPinned: !t.isPinned) : t)
        .toList();
  }

  Future<void> setUnread(String threadId, {required bool unread}) async {
    _threads = _threads
        .map((t) => t.id == threadId ? t.copyWith(isUnread: unread) : t)
        .toList();
  }

  Future<void> toggleMute(String threadId) async {
    _threads = _threads
        .map((t) => t.id == threadId ? t.copyWith(isMuted: !t.isMuted) : t)
        .toList();
  }

  Future<void> moveToBox(String threadId, MessagesBoxTab box) async {
    _threads = _threads
        .map((t) => t.id == threadId ? t.copyWith(box: box) : t)
        .toList();
  }

  Future<void> blockThread(String threadId) async {
    _threads = _threads
        .map((t) => t.id == threadId ? t.copyWith(isBlocked: true) : t)
        .toList();
  }

  Future<void> deleteThread(String threadId) async {
    _threads = _threads.where((t) => t.id != threadId).toList();
  }
}

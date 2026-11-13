/// ข้อความ 2 ภาษา (ไทย/EN) สำหรับระบบข้อความแชท (/messages)
class MessagesL10n {
  const MessagesL10n(this.isEn);
  final bool isEn;

  String get title => isEn ? 'Messages' : 'ข้อความ';
  String get back => isEn ? 'Back' : 'ย้อนกลับ';
  String get manage => isEn ? 'Manage messages' : 'จัดการข้อความ';
  String get newMessage => isEn ? 'New message' : 'ข้อความใหม่';
  String get tabPrimary => isEn ? 'Primary' : 'หลัก';
  String get tabGeneral => isEn ? 'General' : 'ทั่วไป';
  String tabRequests(int count) => isEn
      ? (count > 0 ? 'Requests ($count)' : 'Requests')
      : (count > 0 ? 'คำขอ ($count)' : 'คำขอ');
  String get searchHint => isEn ? 'Search' : 'ค้นหา';
  String get yourNote => isEn ? 'Your note' : 'โน้ตของคุณ';
  String get youPrefix => isEn ? 'You: ' : 'คุณ: ';
  String get hiddenPreview => isEn ? 'New message' : 'มีข้อความใหม่';
  String get emptyTitle => isEn ? 'No messages yet' : 'ยังไม่มีข้อความ';
  String get emptySearch => isEn ? 'No matching chats' : 'ไม่พบแชทที่ค้นหา';
  String get retry => isEn ? 'Retry' : 'ลองใหม่';

  // Manage sheet
  String get showOnly => isEn ? 'Show only' : 'แสดงเฉพาะ';
  String get filterUnread => isEn ? 'Unread' : 'ยังไม่อ่าน';
  String get filterUnanswered => isEn ? 'Unanswered' : 'ยังไม่ตอบ';
  String get filterPinned => isEn ? 'Pinned' : 'ปักหมุด';
  String get filterMuted => isEn ? 'Muted' : 'ปิดเสียง';
  String get settingsTitle => isEn ? 'Settings' : 'ตั้งค่า';
  String get allowRequests => isEn ? 'Message requests' : 'รับคำขอข้อความ';
  String get allowRequestsDesc =>
      isEn ? 'From people you do not follow yet' : 'จากคนที่คุณยังไม่ได้ติดตาม';
  String get showReadReceipts => isEn ? 'Read receipts' : 'แสดงว่าอ่านแล้ว';
  String get showReadReceiptsDesc => isEn
      ? 'Let others see when you open a chat'
      : 'ให้อีกฝ่ายเห็นเมื่อคุณเปิดอ่าน';
  String get showPreview => isEn ? 'Message preview' : 'แสดงตัวอย่างข้อความ';
  String get showPreviewDesc =>
      isEn ? 'In chat list and notifications' : 'ในรายการแชทและการแจ้งเตือน';

  // Thread options sheet
  String get pinTop => isEn ? 'Pin to top' : 'ปักหมุดไว้บนสุด';
  String get unpinTop => isEn ? 'Unpin' : 'เลิกปักหมุด';
  String get markRead => isEn ? 'Mark as read' : 'ทำเครื่องหมายว่าอ่านแล้ว';
  String get markUnread =>
      isEn ? 'Mark as unread' : 'ทำเครื่องหมายว่ายังไม่อ่าน';
  String get muteChat => isEn ? 'Mute notifications' : 'ปิดการแจ้งเตือน';
  String get unmuteChat => isEn ? 'Unmute notifications' : 'เปิดการแจ้งเตือน';
  String get moveToGeneral => isEn ? 'Move to General' : 'ย้ายไปกล่องทั่วไป';
  String get moveToPrimary => isEn ? 'Move to Primary' : 'ย้ายไปกล่องหลัก';
  String get block => isEn ? 'Block' : 'บล็อก';
  String blockConfirmTitle(String handle) =>
      isEn ? 'Block $handle?' : 'บล็อก $handle?';
  String blockConfirmDesc(String handle) => isEn
      ? '$handle will not be able to message you and will not know you blocked them'
      : '$handle จะส่งข้อความหาคุณไม่ได้ และจะไม่เห็นว่าคุณบล็อก';
  String get deleteChat => isEn ? 'Delete chat' : 'ลบแชท';
  String get deleteConfirmTitle => isEn ? 'Delete this chat?' : 'ลบแชทนี้?';
  String get deleteConfirmDesc => isEn
      ? 'This chat will be removed from your inbox. The other person will still see the messages'
      : 'แชทจะหายจากกล่องข้อความของคุณ อีกฝ่ายยังเห็นข้อความเดิม';
  String get cancel => isEn ? 'Cancel' : 'ยกเลิก';
  String get deleteAction => isEn ? 'Delete' : 'ลบ';

  // New message & Note sheets
  String get chooseRecipient =>
      isEn ? 'Start a conversation' : 'เลือกผู้รับข้อความ';
  String get editNoteTitle => isEn ? 'Update your note' : 'แก้ไขโน้ตของคุณ';
  String get noteHint =>
      isEn ? 'Share a short thought...' : 'พิมพ์โน้ตสั้น ๆ...';
  String get save => isEn ? 'Save' : 'บันทึก';

  // Chat room
  String get typeMessageHint => isEn ? 'Message...' : 'ส่งข้อความ...';
  String get callSoon =>
      isEn ? 'Voice call — coming soon' : 'โทรคุย — กำลังพัฒนา จะมาในเฟสถัดไป';
  String get sendPhoto => isEn ? 'Send photo' : 'ส่งรูป';
  String get pickFromGallery =>
      isEn ? 'Choose from library' : 'เลือกจากคลังรูป';
  String get takePhoto => isEn ? 'Take photo' : 'ถ่ายรูป';
  String get samplePhotos => isEn ? 'Sample photos' : 'รูปตัวอย่าง';
  String get photoPickFailed =>
      isEn ? 'Could not open photos' : 'ไม่สามารถเปิดคลังรูป/กล้องได้';
  String get emoji => isEn ? 'Emoji' : 'อีโมจิ';
  String get send => isEn ? 'Send' : 'ส่ง';
  String get emptyRoomHint =>
      isEn ? 'Say hello to start chatting' : 'ทักทายเพื่อเริ่มบทสนทนาเลย';
}

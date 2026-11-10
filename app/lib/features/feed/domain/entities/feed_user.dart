import 'package:equatable/equatable.dart';

/// บัญชีในฟีด/สตอรี่ — [avatar] เป็น URL หรือ `asset:<path>` สำหรับข้อมูล mock
class FeedUser extends Equatable {
  const FeedUser({
    required this.id,
    required this.handle,
    required this.avatar,
    required this.avatarBg,
    required this.hasUnseenStory,
  });

  final String id;
  final String handle;
  final String avatar;

  /// สีพื้นหลังวงกลมอวตาร (ARGB) โชว์ระหว่างรอรูปโหลด
  final int avatarBg;
  final bool hasUnseenStory;

  @override
  List<Object?> get props => [id, handle, avatar, avatarBg, hasUnseenStory];
}

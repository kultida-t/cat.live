import 'package:equatable/equatable.dart';

/// บัญชีในฟีด/สตอรี่ — [avatar] เป็น URL หรือ `asset:<path>` สำหรับข้อมูล mock
class FeedUser extends Equatable {
  const FeedUser({
    required this.id,
    required this.handle,
    required this.avatar,
    required this.avatarBg,
    required this.hasUnseenStory,
    this.name,
    this.isFollowing = false,
  });

  final String id;
  final String handle;
  final String avatar;

  /// สีพื้นหลังวงกลมอวตาร (ARGB) โชว์ระหว่างรอรูปโหลด
  final int avatarBg;
  final bool hasUnseenStory;
  final bool isFollowing;

  /// ชื่อที่แสดงเต็ม (เช่น "นุ่น & โมจิ") — ไม่มีให้ใช้ [handle]
  final String? name;

  String get displayName => name ?? handle;

  FeedUser copyWith({bool? isFollowing}) => FeedUser(
    id: id,
    handle: handle,
    avatar: avatar,
    avatarBg: avatarBg,
    hasUnseenStory: hasUnseenStory,
    name: name,
    isFollowing: isFollowing ?? this.isFollowing,
  );

  @override
  List<Object?> get props => [
    id,
    handle,
    avatar,
    avatarBg,
    hasUnseenStory,
    name,
    isFollowing,
  ];
}

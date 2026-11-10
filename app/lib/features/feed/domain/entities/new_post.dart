import 'package:equatable/equatable.dart';

/// สื่อที่ผู้ใช้เลือกในหน้าสร้างโพสต์ — [source] เป็น `file:<path>` หรือ `asset:<path>`
class DraftMedia extends Equatable {
  const DraftMedia({
    required this.id,
    required this.source,
    required this.name,
    this.isVideo = false,
    this.seconds,
  });

  final String id;
  final String source;
  final String name;
  final bool isVideo;
  final double? seconds;

  @override
  List<Object?> get props => [id, source, name, isVideo, seconds];
}

class NewPost extends Equatable {
  const NewPost({
    required this.caption,
    required this.media,
    this.shareTo = const [],
  });

  final String caption;
  final List<DraftMedia> media;

  /// ชื่อแอปโซเชียลที่เลือกแชร์เพิ่ม (เช่น Facebook) — ใช้แสดง toast หลังโพสต์
  final List<String> shareTo;

  @override
  List<Object?> get props => [caption, media, shareTo];
}

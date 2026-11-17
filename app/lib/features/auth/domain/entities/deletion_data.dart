import 'package:equatable/equatable.dart';

/// ผู้ดูแลร่วมที่รับโอนสิทธิ์เจ้าของแมวได้ก่อนลบบัญชี (AUTH-05)
class DeletionCaretakerOption extends Equatable {
  const DeletionCaretakerOption({
    required this.id,
    required this.name,
    this.avatarSource,
  });

  final String id;
  final String name;
  final String? avatarSource;

  @override
  List<Object?> get props => [id, name, avatarSource];
}

/// แมวที่ผู้ใช้เป็นเจ้าของ พร้อมเงื่อนไขที่ต้องจัดการก่อนลบบัญชี
/// - มีผู้ดูแลร่วม → ต้องเลือกโอนสิทธิ์ให้ใครสักคน หรือยืนยันลบโปรไฟล์แมวไปด้วย
/// - ไม่มีผู้ดูแลร่วม → ลบไปพร้อมบัญชีอัตโนมัติ (ไม่ต้องเลือกอะไร)
class CatDeletionRequirement extends Equatable {
  const CatDeletionRequirement({
    required this.catId,
    required this.catName,
    this.imageSource,
    this.coCaretakers = const [],
  });

  final String catId;
  final String catName;
  final String? imageSource;
  final List<DeletionCaretakerOption> coCaretakers;

  bool get mustResolve => coCaretakers.isNotEmpty;

  @override
  List<Object?> get props => [catId, catName, imageSource, coCaretakers];
}

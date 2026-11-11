import 'package:equatable/equatable.dart';

enum HeroPhotoGroup { myCat, preset, customUpload }

/// ตัวเลือกรูปแบนเนอร์หน้าแรก (น้องแมวของฉัน, รูปจากแมว.live หรือรูปที่อัปโหลดเอง)
class HeroPhotoOption extends Equatable {
  const HeroPhotoOption({
    required this.id,
    required this.imageSource,
    required this.semanticLabel,
    required this.group,
    this.label,
  });

  final String id;
  final String imageSource;
  final String semanticLabel;
  final HeroPhotoGroup group;

  /// ชื่อน้องแมวที่ซ้อนด้านล่างรูป (เฉพาะกลุ่ม myCat)
  final String? label;

  @override
  List<Object?> get props => [id, imageSource, semanticLabel, group, label];
}

class HomeHeroGallery extends Equatable {
  const HomeHeroGallery({required this.myCats, required this.presets});

  final List<HeroPhotoOption> myCats;
  final List<HeroPhotoOption> presets;

  @override
  List<Object?> get props => [myCats, presets];
}

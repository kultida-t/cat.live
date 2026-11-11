import '../../domain/entities/hero_photo.dart';

/// ชุดรูปตัวอย่างสำหรับแบนเนอร์หน้าแรก — ตรงกับหน้าเว็บจริง www.แมว.live
class MockHomeHeroDataSource {
  const MockHomeHeroDataSource();

  static const _myCats = [
    HeroPhotoOption(
      id: 'cat-mali',
      imageSource: 'asset:assets/images/hero/mali.jpg',
      semanticLabel: 'มะลิ',
      group: HeroPhotoGroup.myCat,
      label: 'มะลิ',
    ),
    HeroPhotoOption(
      id: 'cat-somjeed',
      imageSource: 'asset:assets/images/hero/somjeed.jpg',
      semanticLabel: 'ส้มจี๊ด',
      group: HeroPhotoGroup.myCat,
      label: 'ส้มจี๊ด',
    ),
    HeroPhotoOption(
      id: 'cat-thuadam',
      imageSource: 'asset:assets/images/hero/thuadam.jpg',
      semanticLabel: 'ถั่วดำ',
      group: HeroPhotoGroup.myCat,
      label: 'ถั่วดำ',
    ),
  ];

  static const _presets = [
    HeroPhotoOption(
      id: 'preset-group',
      imageSource: 'asset:assets/images/hero/hero-group.webp',
      semanticLabel: 'แมวหลายตัวนั่งรวมกัน',
      group: HeroPhotoGroup.preset,
    ),
    HeroPhotoOption(
      id: 'preset-kitten',
      imageSource: 'asset:assets/images/hero/kitten.jpg',
      semanticLabel: 'ลูกแมวยกขาหน้า',
      group: HeroPhotoGroup.preset,
    ),
    HeroPhotoOption(
      id: 'preset-orange',
      imageSource: 'asset:assets/images/hero/somjeed.jpg',
      semanticLabel: 'แมวส้ม',
      group: HeroPhotoGroup.preset,
    ),
    HeroPhotoOption(
      id: 'preset-tabby',
      imageSource: 'asset:assets/images/hero/tabby.jpg',
      semanticLabel: 'แมวลายสลิด',
      group: HeroPhotoGroup.preset,
    ),
  ];

  HomeHeroGallery getGallery() =>
      const HomeHeroGallery(myCats: _myCats, presets: _presets);
}

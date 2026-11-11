import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_image.dart';

/// อวตารวงกลม — สีพื้นโชว์ระหว่างรอรูปโหลด
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.source,
    required this.bg,
    required this.size,
  });

  final String source;
  final int bg;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: Color(bg)),
      clipBehavior: Clip.antiAlias,
      child: AppImage(source: source),
    );
  }
}

/// อวตารพร้อมวงแหวนสตอรี่ — วงแหวนฟ้าไล่สีเมื่อมีสตอรี่ยังไม่ได้ดู
/// ถ้า [showSeenRing] เป็น false และไม่มีสตอรี่จะเว้นระยะขอบให้ขนาดรวมเท่ากัน
class StoryAvatar extends StatelessWidget {
  const StoryAvatar({
    super.key,
    required this.source,
    required this.bg,
    required this.size,
    required this.hasUnseenStory,
    this.showSeenRing = false,
  });

  final String source;
  final int bg;
  final double size;
  final bool hasUnseenStory;
  final bool showSeenRing;

  @override
  Widget build(BuildContext context) {
    final avatar = AppAvatar(source: source, bg: bg, size: size);
    if (!hasUnseenStory && !showSeenRing) {
      return Padding(padding: const EdgeInsets.all(4.5), child: avatar);
    }
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: hasUnseenStory
              ? const [AppColors.ringUnseenFrom, AppColors.ringUnseenTo]
              : const [AppColors.unchecked, AppColors.unchecked],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: avatar,
      ),
    );
  }
}

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
      child: ClipOval(
        child: SizedBox.expand(child: AppImage(source: source)),
      ),
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
    this.ringWidth = 2.5,
    this.gapWidth = 2.0,
  });

  final String source;
  final int bg;
  final double size;
  final bool hasUnseenStory;
  final bool showSeenRing;
  final double ringWidth;
  final double gapWidth;

  @override
  Widget build(BuildContext context) {
    final avatar = AppAvatar(source: source, bg: bg, size: size);
    if (!hasUnseenStory && !showSeenRing) {
      return Padding(
        padding: EdgeInsets.all(ringWidth + gapWidth),
        child: avatar,
      );
    }
    return Container(
      padding: EdgeInsets.all(ringWidth),
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
        padding: EdgeInsets.all(gapWidth),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: avatar,
      ),
    );
  }
}

/// อวตารพร้อมวงแหวนไล่สี — ใช้กับโปรไฟล์แมว (ส้มพาสเทล) และโปรไฟล์ตัวฉัน (เขียวมินต์)
class GradientAvatar extends StatelessWidget {
  const GradientAvatar({
    super.key,
    required this.source,
    required this.bg,
    required this.size,
    required this.gradientColors,
  });

  final String source;
  final int bg;
  final double size;
  final List<Color> gradientColors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
          stops: gradientColors.length == 3 ? const [0.0, 0.55, 1.0] : null,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.card,
        ),
        child: AppAvatar(source: source, bg: bg, size: size),
      ),
    );
  }
}

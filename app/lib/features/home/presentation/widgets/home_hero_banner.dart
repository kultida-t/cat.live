import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/fill_icon.dart';
import '../../domain/entities/hero_photo.dart';

/// แบนเนอร์ต้อนรับหน้าแรก — สูง 232px ไล่สีครีม + รูปแมวฝั่งขวาเบลนด์ขอบซ้าย
class HomeHeroBanner extends StatelessWidget {
  const HomeHeroBanner({
    super.key,
    required this.photo,
    required this.isCustomSelected,
    required this.onPhotoTap,
    required this.onOpenPicker,
  });

  final HeroPhotoOption photo;
  final bool isCustomSelected;
  final VoidCallback onPhotoTap;
  final VoidCallback onOpenPicker;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 232,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.heroStart, AppColors.heroEnd],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // รูปแมวฝั่งขวา 64% พร้อมเฟดขอบซ้ายให้กลืนกับพื้นหลัง
            Align(
              alignment: Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: 0.64,
                heightFactor: 1,
                child: Semantics(
                  button: true,
                  label: isCustomSelected
                      ? 'เปลี่ยนรูปหน้าแรก'
                      : 'ดูรูปแมวถัดไป',
                  excludeSemantics: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onPhotoTap,
                    child: ShaderMask(
                      blendMode: BlendMode.dstIn,
                      shaderCallback: (bounds) => const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        stops: [0.0, 0.18, 1.0],
                        colors: [
                          Colors.transparent,
                          Colors.black,
                          Colors.black,
                        ],
                      ).createShader(bounds),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 700),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeOut,
                        transitionBuilder: (child, animation) {
                          final scale = Tween<double>(
                            begin: 1.04,
                            end: 1.0,
                          ).animate(animation);
                          return FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(scale: scale, child: child),
                          );
                        },
                        child: SizedBox.expand(
                          key: ValueKey(photo.imageSource),
                          child: AppImage(
                            source: photo.imageSource,
                            semanticLabel: photo.semanticLabel,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ข้อความต้อนรับฝั่งซ้าย (ไม่ขวางการแตะรูปฝั่งขวา)
            IgnorePointer(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 28, 16, 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          text: 'สวัสดี\nคนรักแมว ',
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                            color: AppColors.text,
                          ),
                          children: const [
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: FillIcon(
                                shape: FillIconShape.heart,
                                color: AppColors.heroHeart,
                                filled: true,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'เพราะทุกแมว\nมีเรื่องราวที่สำคัญ',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          height: 1.35,
                          color: AppColors.text2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ปุ่มลอยมุมขวาบนสำหรับเปิดชีตเลือกรูปหน้าแรก
            Positioned(
              top: 8,
              right: 8,
              child: Semantics(
                button: true,
                label: 'เปลี่ยนรูปหน้าแรก',
                excludeSemantics: true,
                child: InkWell(
                  onTap: onOpenPicker,
                  borderRadius: BorderRadius.circular(999),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: ClipOval(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Color(0x40FFFFFF),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.imagePlus,
                              size: 18,
                              color: Color(0xE6FFFFFF),
                              shadows: [
                                Shadow(color: Color(0x44000000), blurRadius: 4),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

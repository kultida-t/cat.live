import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/tag_product_data.dart';
import '../l10n/tag_l10n.dart';

/// ส่วนฟีเจอร์กลาง-ล่างของหน้า /tag — ตรงตาม DOM/CSS เว็บจริง www.แมว.live/tag
class TagSectionsFeatures extends StatelessWidget {
  const TagSectionsFeatures({
    super.key,
    required this.data,
    required this.isEn,
    required this.soundTrigger,
    required this.isFlashlightOn,
    required this.onPlaySound,
    required this.onToggleFlashlight,
  });

  final TagProductData data;
  final bool isEn;
  final int soundTrigger;
  final bool isFlashlightOn;
  final VoidCallback onPlaySound;
  final VoidCallback onToggleFlashlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SoundSection(
          isEn: isEn,
          soundTrigger: soundTrigger,
          onPlaySound: onPlaySound,
        ),
        const SizedBox(height: 68),
        _PrecisionFindingSection(
          isEn: isEn,
          isFlashlightOn: isFlashlightOn,
          onPlaySound: onPlaySound,
          onToggleFlashlight: onToggleFlashlight,
        ),
        const SizedBox(height: 68),
        _HowItWorksSection(isEn: isEn),
        const SizedBox(height: 72),
        _PrivacySection(isEn: isEn),
        const SizedBox(height: 72),
        _CustomEngraveSection(isEn: isEn),
        const SizedBox(height: 68),
        _HighlightsSection(isEn: isEn),
        const SizedBox(height: 68),
        _SpecsCard(data: data, isEn: isEn),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            TagL10n.disclaimer(isEn),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              height: 1.55,
              color: AppColors.tagTextMuted,
            ),
          ),
        ),
      ],
    );
  }
}

class _SoundSection extends StatefulWidget {
  const _SoundSection({
    required this.isEn,
    required this.soundTrigger,
    required this.onPlaySound,
  });

  final bool isEn;
  final int soundTrigger;
  final VoidCallback onPlaySound;

  @override
  State<_SoundSection> createState() => _SoundSectionState();
}

class _SoundSectionState extends State<_SoundSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant _SoundSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.soundTrigger != widget.soundTrigger) {
      _pulseController.forward(from: 0);
      _pulseController.repeat();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          TagL10n.soundTitle(widget.isEn),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.tagTextDark,
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            TagL10n.soundDesc(widget.isEn),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.55,
              color: AppColors.tagTextMuted,
            ),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 240,
          child: Stack(
            alignment: Alignment.center,
            children: [
                // วงคลื่นเสียง .tag-ping 3 ชั้น (2.8s ease-out infinite) มีศูนย์กลางตรงแท็ก
                Positioned(
                  top: 18,
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, _) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          for (final delay in [0.0, 0.28, 0.57])
                            Builder(
                              builder: (context) {
                                final t = (_pulseController.value + delay) % 1.0;
                                final eased = Curves.easeOut.transform(t);
                                final size = 96.0 + eased * 128.0;
                                return Container(
                                  width: size,
                                  height: size,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.tagTealRing.withValues(
                                        alpha: (1.0 - eased) * 0.45,
                                      ),
                                      width: 1.8,
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      );
                    },
                  ),
                ),
                // ภาพปลอกคอสีกรมท่า + ซองแท็กสีกรมท่ามีรอยเย็บประขาวสลักชื่อ "ส้มจี๊ด" ตรงเว็บจริง
                Padding(
                  padding: const EdgeInsets.only(top: 36),
                  child: _CollarTagSvgIllustration(
                    collarColor: AppColors.tagCollarNavy,
                    tagColor: AppColors.tagCollarNavy,
                    stitchColor: Colors.white.withValues(alpha: 0.65),
                    centerText: TagL10n.sampleCatName(widget.isEn),
                    drawTagStitch: true,
                    size: 176,
                  ),
                ),
                // ป้ายสถานะอยู่ตรงกลางด้านบนเหนือปลอกคอ (นิ่งไม่ขยับ)
                Positioned(
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.tagTextDark.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.volume2,
                          size: 14,
                          color: AppColors.tagTeal,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          TagL10n.soundPlayingBadge(widget.isEn),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.tagTeal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PrecisionFindingSection extends StatelessWidget {
  const _PrecisionFindingSection({
    required this.isEn,
    required this.isFlashlightOn,
    required this.onPlaySound,
    required this.onToggleFlashlight,
  });

  final bool isEn;
  final bool isFlashlightOn;
  final VoidCallback onPlaySound;
  final VoidCallback onToggleFlashlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          TagL10n.closeTitle(isEn),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.tagTextDark,
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            TagL10n.closeDesc(isEn),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.55,
              color: AppColors.tagTextMuted,
            ),
          ),
        ),
        const SizedBox(height: 22),
        // เฟรมมือถือขนาด 150x300 ขอบ #2B2320 ตรงเว็บจริง
        Container(
          width: 158,
          height: 304,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: AppColors.tagPhoneFrame,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.tagPhoneFrame.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.tagTeal, AppColors.tagTealDeep],
              ),
              borderRadius: BorderRadius.circular(23),
            ),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.tagPhoneFrame,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  TagL10n.searchingBadge(isEn),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  TagL10n.sampleCatName(isEn),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                CustomPaint(
                  size: const Size(82, 82),
                  painter: _PrecisionArrowPainter(),
                ),
                const Spacer(),
                Text(
                  TagL10n.distanceSample(isEn),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  TagL10n.directionHint(isEn),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _RoundOverlayIcon(
                      icon: LucideIcons.compass,
                      label: TagL10n.closeLabel(isEn),
                      active: false,
                      onTap: () {},
                    ),
                    _RoundOverlayIcon(
                      icon: LucideIcons.flashlight,
                      label: TagL10n.flashlightLabel(isEn),
                      active: isFlashlightOn,
                      onTap: onToggleFlashlight,
                    ),
                    _RoundOverlayIcon(
                      icon: LucideIcons.volume2,
                      label: TagL10n.soundShortLabel(isEn),
                      active: false,
                      onTap: onPlaySound,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PrecisionArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final trailPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromLTWH(w * 0.08, h * 0.16, w * 0.72, h * 0.76),
      3.3,
      1.3,
      false,
      trailPaint,
    );

    canvas.drawCircle(
      Offset(w * 0.74, h * 0.14),
      4.5,
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );

    final arrowPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final start = Offset(w * 0.24, h * 0.78);
    final tip = Offset(w * 0.66, h * 0.28);
    canvas.drawLine(start, tip, arrowPaint);

    final head = Path()
      ..moveTo(tip.dx - 17, tip.dy + 2)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(tip.dx + 1, tip.dy + 17);
    canvas.drawPath(head, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RoundOverlayIcon extends StatelessWidget {
  const _RoundOverlayIcon({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: active
                ? Colors.white
                : Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 15,
            color: active ? AppColors.tagTeal : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection({required this.isEn});

  final bool isEn;

  @override
  Widget build(BuildContext context) {
    final nodes = TagL10n.howNodes(isEn);

    return Column(
      children: [
        Text(
          TagL10n.howTitle(isEn),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.tagTextDark,
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            TagL10n.howDesc(isEn),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.55,
              color: AppColors.tagTextMuted,
            ),
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            for (var i = 0; i < nodes.length; i++) ...[
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.tagTealDeep.withValues(alpha: 0.18),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: switch (i) {
                          0 => CustomPaint(
                            size: const Size(34, 34),
                            painter: _MiniCatTagIconPainter(
                              color: AppColors.tagColorTeal,
                            ),
                          ),
                          1 => const Icon(
                            LucideIcons.smartphone,
                            size: 24,
                            color: AppColors.tagTeal,
                          ),
                          _ => const Icon(
                            LucideIcons.mapPin,
                            size: 24,
                            color: AppColors.tagTeal,
                          ),
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      nodes[i],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.tagTextDark,
                      ),
                    ),
                  ],
                ),
              ),
              if (i < nodes.length - 1)
                const Padding(
                  padding: EdgeInsets.only(bottom: 22),
                  child: SizedBox(
                    width: 24,
                    child: CustomPaint(
                      size: Size(24, 2),
                      painter: _DashedConnectorPainter(),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ],
    );
  }
}

class _MiniCatTagIconPainter extends CustomPainter {
  const _MiniCatTagIconPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.28, h * 0.24)
      ..quadraticBezierTo(w * 0.16, h * 0.05, w * 0.10, h * 0.22)
      ..quadraticBezierTo(w * 0.04, h * 0.45, w * 0.06, h * 0.60)
      ..cubicTo(w * 0.08, h * 0.98, w * 0.92, h * 0.98, w * 0.94, h * 0.60)
      ..quadraticBezierTo(w * 0.96, h * 0.45, w * 0.90, h * 0.22)
      ..quadraticBezierTo(w * 0.84, h * 0.05, w * 0.72, h * 0.24)
      ..quadraticBezierTo(w * 0.50, h * 0.30, w * 0.28, h * 0.24)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawCircle(
      Offset(w * 0.50, h * 0.60),
      w * 0.22,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniCatTagIconPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _DashedConnectorPainter extends CustomPainter {
  const _DashedConnectorPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.tagTealRing
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (double x = 0; x < size.width; x += 6) {
      canvas.drawLine(Offset(x, 0), Offset(x + 3, 0), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PrivacySection extends StatelessWidget {
  const _PrivacySection({required this.isEn});

  final bool isEn;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          TagL10n.privacyTitle(isEn),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.tagTextDark,
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            TagL10n.privacyDesc(isEn),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.55,
              color: AppColors.tagTextMuted,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.tagCardMintSoft,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            LucideIcons.lock,
            size: 30,
            color: AppColors.tagTeal,
          ),
        ),
      ],
    );
  }
}

class _CustomEngraveSection extends StatelessWidget {
  const _CustomEngraveSection({required this.isEn});

  final bool isEn;

  @override
  Widget build(BuildContext context) {
    final items = isEn
        ? const [
            (AppColors.tagCollarBlack, 'Black', 'Somjeed', false, false),
            (AppColors.tagEngraveWhite, 'White', null, false, true),
            (AppColors.tagEngraveOrange, 'Orange', 'Khaopun', false, false),
            (AppColors.tagCollarNavy, 'Navy', null, true, false),
            (AppColors.tagEngraveOlive, 'Olive', 'Mochi', false, false),
            (AppColors.tagCollarMint, 'Mint', null, true, false),
          ]
        : const [
            (AppColors.tagCollarBlack, 'ดำ', 'ส้มจี๊ด', false, false),
            (AppColors.tagEngraveWhite, 'ขาว', null, false, true),
            (AppColors.tagEngraveOrange, 'ส้ม', 'ข้าวปั้น', false, false),
            (AppColors.tagCollarNavy, 'กรมท่า', null, true, false),
            (AppColors.tagEngraveOlive, 'เขียวมะกอก', 'โมจิ', false, false),
            (AppColors.tagCollarMint, 'มิ้นต์', null, true, false),
          ];

    return Column(
      children: [
        Text(
          TagL10n.customTitle(isEn),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.tagTextDark,
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            TagL10n.customDesc(isEn),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.55,
              color: AppColors.tagTextMuted,
            ),
          ),
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 8,
            childAspectRatio: 0.85,
          ),
          itemBuilder: (context, i) {
            final (color, label, text, hasFace, hasGreenDot) = items[i];
            final stitch = color == AppColors.tagEngraveWhite
                ? const Color(0xFFB9AE9C)
                : Colors.white.withValues(alpha: 0.45);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CollarTagSvgIllustration(
                  collarColor: color,
                  tagColor: color,
                  stitchColor: stitch,
                  centerText: text,
                  drawCatFace: hasFace,
                  drawGreenDot: hasGreenDot,
                  size: 88,
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.tagTextMuted,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// วาดภาพเวกเตอร์ปลอกคอพร้อมแท็ก (ใช้ร่วมกันใน Section 5 และ Section 9)
class _CollarTagSvgIllustration extends StatelessWidget {
  const _CollarTagSvgIllustration({
    required this.collarColor,
    required this.tagColor,
    required this.stitchColor,
    required this.size,
    this.centerText,
    this.drawCatFace = false,
    this.drawGreenDot = false,
    this.drawTagStitch = false,
  });

  final Color collarColor;
  final Color tagColor;
  final Color stitchColor;
  final double size;
  final String? centerText;
  final bool drawCatFace;
  final bool drawGreenDot;
  final bool drawTagStitch;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CollarTagIllustrationPainter(
          collarColor: collarColor,
          tagColor: tagColor,
          stitchColor: stitchColor,
          centerText: centerText,
          drawCatFace: drawCatFace,
          drawGreenDot: drawGreenDot,
          drawTagStitch: drawTagStitch,
        ),
      ),
    );
  }
}

class _CollarTagIllustrationPainter extends CustomPainter {
  const _CollarTagIllustrationPainter({
    required this.collarColor,
    required this.tagColor,
    required this.stitchColor,
    this.centerText,
    this.drawCatFace = false,
    this.drawGreenDot = false,
    this.drawTagStitch = false,
  });

  final Color collarColor;
  final Color tagColor;
  final Color stitchColor;
  final String? centerText;
  final bool drawCatFace;
  final bool drawGreenDot;
  final bool drawTagStitch;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final scale = w / 176.0;

    final cx = w * 0.50;
    final R = 46.0 * scale; // รัศมีความโค้งกลมของตัวแท็กหัวแมว (กว้าง 92 สมดุลกลมสวย)
    final bandW = 156.0 * scale; // สายปลอกคอกว้าง 1.7 เท่าของตัวแท็กตรงตามเว็บจริง
    final bandX = (w - bandW) / 2;
    final bandY = 22.0 * scale;
    final bandH = 22.0 * scale;

    final cy = bandY + bandH + R * 0.98; // จุดศูนย์กลางแท็กกลม
    final dipY = bandY + bandH + 2.0 * scale; // รอยเว้าตรงกลางอยู่ระดับขอบล่างของสายพอดี
    final earTopY = bandY + 4.0 * scale; // ปลายหูยื่นขึ้นไปบนสายปลอกคอเกือบถึงขอบบน
    final lx = cx - 26.0 * scale;
    final rx = cx + 26.0 * scale;

    // สายปลอกคอแนวนอน
    final bandRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(bandX, bandY, bandW, bandH),
      Radius.circular(4.0 * scale),
    );
    canvas.drawRRect(bandRect, Paint()..color = collarColor);

    // รอยเย็บประสีขาวบนสายปลอกคอ
    final stitchPaint = Paint()
      ..color = stitchColor
      ..strokeWidth = 1.1;
    final stitchTopY = bandY + bandH * 0.22;
    final stitchBottomY = bandY + bandH * 0.78;
    for (double x = bandX + 6.0 * scale; x < bandX + bandW - 6.0 * scale; x += 6.5 * scale) {
      canvas.drawLine(
        Offset(x, stitchTopY),
        Offset(x + 3.2 * scale, stitchTopY),
        stitchPaint,
      );
      canvas.drawLine(
        Offset(x, stitchBottomY),
        Offset(x + 3.2 * scale, stitchBottomY),
        stitchPaint,
      );
    }

    // ซองแท็กรูปหัวแมว (ทรงกลมป้อมสมดุลตรงตามเว็บจริง ไม่รี ไม่ยาว)
    final catPath = Path()
      ..moveTo(lx, earTopY)
      // เว้าลงมาระหว่างหูสองข้าง
      ..quadraticBezierTo(cx - 13.0 * scale, dipY - 4.0 * scale, cx, dipY)
      // โค้งขึ้นไปที่ปลายหูขวา
      ..quadraticBezierTo(cx + 13.0 * scale, dipY - 4.0 * scale, rx, earTopY)
      // โค้งขอบหูขวาลงมาที่แก้มขวา
      ..quadraticBezierTo(rx + 14.0 * scale, cy - R * 0.82, cx + R, cy)
      // โค้งกลมมนด้านล่างของตัวแท็ก (ครึ่งวงกลมล่างสมบูรณ์แบบ)
      ..arcToPoint(
        Offset(cx - R, cy),
        radius: Radius.circular(R),
        clockwise: true,
      )
      // โค้งจากแก้มซ้ายขึ้นไปที่ปลายหูซ้าย
      ..quadraticBezierTo(lx - 14.0 * scale, cy - R * 0.82, lx, earTopY)
      ..close();

    // เงาและตัวแท็กรูปหัวแมว
    canvas.drawShadow(catPath, AppColors.tagPhoneFrame.withValues(alpha: 0.20), 4, false);
    canvas.drawPath(catPath, Paint()..color = tagColor);

    // รอยเย็บประสีขาวรอบขอบซองแท็ก (ร่นเข้าด้านใน 3.5px สวยงามสมจริง)
    if (drawTagStitch) {
      final metrics = catPath.computeMetrics();
      final dashPaint = Paint()
        ..color = stitchColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1;
      canvas.save();
      canvas.translate(cx, cy);
      canvas.scale(0.91);
      canvas.translate(-cx, -cy);
      for (final metric in metrics) {
        for (double d = 3.5 * scale; d < metric.length - 3.5 * scale; d += 6.5 * scale) {
          canvas.drawPath(metric.extractPath(d, d + 3.2 * scale), dashPaint);
        }
      }
      canvas.restore();
    }

    // วงกลมสีขาวตรงกลางแท็ก (สีขาวบริสุทธิ์ ขอบชัด สะอาดตาตรงตามเว็บจริง)
    final circleCenter = Offset(cx, cy);
    final circleRadius = R * 0.62;
    canvas.drawCircle(
      circleCenter,
      circleRadius,
      Paint()..color = Colors.white,
    );

    if (centerText != null && centerText!.isNotEmpty) {
      // ข้อความ "ส้มจี๊ด" ขนาดกะทัดรัด มีพื้นที่ว่างรอบข้างโปร่งสบายตาตรงตามเว็บจริง
      final tp = TextPainter(
        text: TextSpan(
          text: centerText,
          style: TextStyle(
            fontSize: 12.0 * scale,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF4A6B68),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(circleCenter.dx - tp.width / 2, circleCenter.dy - tp.height / 2),
      );
    } else if (drawGreenDot) {
      canvas.drawCircle(
        circleCenter,
        circleRadius * 0.28,
        Paint()..color = AppColors.tagColorTeal,
      );
    } else if (drawCatFace) {
      final ink = Paint()
        ..color = AppColors.tagTextDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round;
      for (final dir in [-1.0, 1.0]) {
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(circleCenter.dx + dir * circleRadius * 0.35, circleCenter.dy - circleRadius * 0.14),
            width: circleRadius * 0.34,
            height: circleRadius * 0.24,
          ),
          3.4,
          2.6,
          false,
          ink,
        );
      }
      canvas.drawCircle(
        Offset(circleCenter.dx, circleCenter.dy + circleRadius * 0.14),
        circleRadius * 0.09,
        Paint()..color = AppColors.tagTextDark,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CollarTagIllustrationPainter oldDelegate) =>
      oldDelegate.collarColor != collarColor ||
      oldDelegate.tagColor != tagColor ||
      oldDelegate.centerText != centerText;
}

class _HighlightsSection extends StatelessWidget {
  const _HighlightsSection({required this.isEn});

  final bool isEn;

  @override
  Widget build(BuildContext context) {
    final items = TagL10n.highlights(isEn);
    const icons = [
      LucideIcons.batteryFull,
      LucideIcons.droplets,
      LucideIcons.cat,
    ];
    const bgs = [
      AppColors.tagCardGreenSoft,
      AppColors.tagCardMintSoft,
      AppColors.tagCardPurpleSoft,
    ];
    const inks = [
      AppColors.tagCardGreenInk,
      AppColors.tagTeal,
      AppColors.tagCardPurpleInk,
    ];

    return Column(
      children: [
        Text(
          TagL10n.highlightsTitle(isEn),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.tagTextDark,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(items.length, (i) {
            final (title, desc) = items[i];
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: bgs[i],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icons[i], size: 22, color: inks[i]),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.tagTextDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      desc,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11.5,
                        height: 1.35,
                        color: AppColors.tagTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _SpecsCard extends StatelessWidget {
  const _SpecsCard({required this.data, required this.isEn});

  final TagProductData data;
  final bool isEn;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          TagL10n.specsTitle(isEn),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.tagTextDark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          TagL10n.specsSubtitle(isEn, data.priceThb),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.tagTextMuted,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.tagBorder),
          ),
          child: Column(
            children: [
              for (var i = 0; i < data.specs.length; i++) ...[
                if (i > 0)
                  const Divider(
                    height: 18,
                    thickness: 1,
                    color: AppColors.tagBorder,
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 92,
                      child: Text(
                        isEn ? data.specs[i].labelEn : data.specs[i].labelTh,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.tagTextDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isEn ? data.specs[i].valueEn : data.specs[i].valueTh,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: AppColors.tagTextMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// หน้าแอนิเมชันเปิดแอปครั้งแรก — แมวส้มวิ่งกระโดดเข้าอ้อมกอดเจ้าของตรงตามเว็บ www.แมว.live
class SplashOverlay extends StatefulWidget {
  const SplashOverlay({super.key, required this.onFinished, this.isEn = false});

  final VoidCallback onFinished;
  final bool isEn;

  @override
  State<SplashOverlay> createState() => _SplashOverlayState();
}

class _SplashOverlayState extends State<SplashOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _mainCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  );
  late final AnimationController _fadeOutCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
    value: 1,
  );
  bool _dismissing = false;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final reduceMotion = MediaQuery.disableAnimationsOf(context);
      if (reduceMotion) {
        _mainCtrl.value = 0.78;
      } else {
        _mainCtrl.forward();
      }
      _autoDismissTimer = Timer(const Duration(milliseconds: 3600), _dismiss);
    });
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _mainCtrl.dispose();
    _fadeOutCtrl.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    if (_dismissing || !mounted) return;
    _dismissing = true;
    _autoDismissTimer?.cancel();
    await _fadeOutCtrl.reverse();
    if (mounted) widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final screenW = MediaQuery.sizeOf(context).width;
    final artWidth = math.min(screenW * 0.86, 360.0);
    final artHeight = artWidth * (220.0 / 320.0);

    return FadeTransition(
      opacity: CurvedAnimation(parent: _fadeOutCtrl, curve: Curves.easeOut),
      child: Semantics(
        container: true,
        label: widget.isEn
            ? 'แมว.live is opening · Tap anywhere to skip'
            : 'แมว.live กำลังเปิด · แตะเพื่อข้าม',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _dismiss,
          child: Material(
            color: Colors.transparent,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.2),
                  radius: 0.95,
                  colors: [
                    AppColors.splashBgStart,
                    AppColors.splashBgMid,
                    AppColors.splashBgEnd,
                  ],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: _mainCtrl,
                          builder: (_, _) => SizedBox(
                            width: artWidth,
                            height: artHeight,
                            child: CustomPaint(
                              painter: _SplashScenePainter(t: _mainCtrl.value),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        AnimatedBuilder(
                          animation: _mainCtrl,
                          builder: (_, child) {
                            final progress = ((_mainCtrl.value - 0.60) / 0.15)
                                .clamp(0.0, 1.0);
                            final eased = Curves.easeOut.transform(progress);
                            return Opacity(
                              opacity: eased,
                              child: Transform.translate(
                                offset: Offset(0, 10 * (1 - eased)),
                                child: child,
                              ),
                            );
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/brand/maew-logo.png',
                                width: 178,
                                height: 52,
                                semanticLabel: 'แมว.live',
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.isEn
                                    ? 'Because every cat has a story that matters'
                                    : 'เพราะทุกแมวมีเรื่องราวที่สำคัญ',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.muted,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 28 + bottomInset,
                    child: Text(
                      widget.isEn ? 'Tap to enter' : 'แตะเพื่อเข้าแอป',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.splashHint,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashScenePainter extends CustomPainter {
  const _SplashScenePainter({required this.t});

  final double t;

  static double _segment(double value, double start, double end) {
    if (end <= start) return value >= end ? 1.0 : 0.0;
    return ((value - start) / (end - start)).clamp(0.0, 1.0);
  }

  static double _lerp(double a, double b, double p) => a + (b - a) * p;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 320.0, size.height / 220.0);
    // เลื่อนแกน X เข้าซ้าย 40 หน่วย เพื่อให้ตัวเจ้าของ เงา แมวที่กอด และหัวใจอยู่กึ่งกลาง (x=160) ตรงแนวเดียวกับโลโก้
    canvas.translate(-40, 0);

    // 1) เงาบนพื้น
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(200, 198), width: 140, height: 16),
      Paint()..color = AppColors.splashShadow.withValues(alpha: 0.7),
    );

    // คำนวณการยืดหยุ่นของเจ้าของ (sp-squish: 54% -> 59% -> 66%)
    double squishX = 1.0;
    double squishY = 1.0;
    if (t >= 0.54 && t < 0.59) {
      final p = Curves.easeOut.transform(_segment(t, 0.54, 0.59));
      squishX = _lerp(1.0, 1.05, p);
      squishY = _lerp(1.0, 0.95, p);
    } else if (t >= 0.59 && t < 0.66) {
      final p = Curves.easeOut.transform(_segment(t, 0.59, 0.66));
      squishX = _lerp(1.05, 1.0, p);
      squishY = _lerp(0.95, 1.0, p);
    }

    void withOwnerSquish(VoidCallback draw) {
      canvas.save();
      canvas.translate(200, 196);
      canvas.scale(squishX, squishY);
      canvas.translate(-200, -196);
      draw();
      canvas.restore();
    }

    // 2) ตัวเจ้าของด้านหลังแมว
    withOwnerSquish(() => _paintOwnerBodyAndHead(canvas));

    // 3) แมวส้มวิ่งเข้ามากระโดดเข้ากอด
    _paintRunningCat(canvas);

    // 4) แขนเจ้าของอยู่หน้าแมวเพื่อกอดรับ
    withOwnerSquish(() => _paintOwnerArms(canvas));

    // 5) หัวใจ 3 ดวงลอยขึ้น
    _paintHeart(
      canvas,
      startT: 0.56,
      tip: const Offset(200, 88),
      large: true,
      color: AppColors.heart,
    );
    _paintHeart(
      canvas,
      startT: 0.593,
      tip: const Offset(246, 97),
      large: false,
      color: AppColors.splashShirt,
    );
    _paintHeart(
      canvas,
      startT: 0.627,
      tip: const Offset(158, 101),
      large: false,
      color: AppColors.splashHeartGold,
    );

    canvas.restore();
  }

  void _paintOwnerBodyAndHead(Canvas canvas) {
    // เสื้อ
    final shirt = Path()
      ..moveTo(168, 196)
      ..cubicTo(168, 162, 182, 138, 200, 138)
      ..cubicTo(218, 138, 232, 162, 232, 196)
      ..close();
    canvas.drawPath(shirt, Paint()..color = AppColors.splashShirt);

    // หัว
    canvas.drawCircle(
      const Offset(200, 112),
      24,
      Paint()..color = AppColors.splashSkin,
    );

    // ผม
    final hair = Path()
      ..moveTo(176, 108)
      ..cubicTo(178, 90, 189, 80, 202, 80)
      ..cubicTo(216, 80, 226, 90, 226, 106)
      ..cubicTo(220, 98, 210, 94, 200, 94)
      ..cubicTo(191, 94, 183, 99, 176, 108)
      ..close();
    canvas.drawPath(hair, Paint()..color = AppColors.ink);

    // ตา
    final eyePaint = Paint()..color = AppColors.text;
    canvas.drawCircle(const Offset(192, 115), 2.6, eyePaint);
    canvas.drawCircle(const Offset(210, 115), 2.6, eyePaint);

    // ยิ้ม
    final smile = Path()
      ..moveTo(195, 124)
      ..quadraticBezierTo(201, 129, 207, 124);
    canvas.drawPath(
      smile,
      Paint()
        ..color = AppColors.text
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );

    // แก้มแดง
    final cheekPaint = Paint()
      ..color = AppColors.splashShirt.withValues(alpha: 0.7);
    canvas.drawCircle(const Offset(186, 122), 3.6, cheekPaint);
    canvas.drawCircle(const Offset(216, 122), 3.6, cheekPaint);
  }

  void _paintOwnerArms(Canvas canvas) {
    final hugProgress = Curves.easeOut.transform(_segment(t, 0.50, 0.60));
    final leftAngle = _lerp(0, 78, hugProgress) * math.pi / 180;
    final rightAngle = _lerp(0, -78, hugProgress) * math.pi / 180;

    final armPaint = Paint()
      ..color = AppColors.splashSkin
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round;

    // แขนซ้าย (หมุนรอบหัวไหล่ 176, 152)
    canvas.save();
    canvas.translate(176, 152);
    canvas.rotate(leftAngle);
    canvas.translate(-176, -152);
    final leftArm = Path()
      ..moveTo(176, 152)
      ..quadraticBezierTo(154, 146, 146, 126);
    canvas.drawPath(leftArm, armPaint);
    canvas.restore();

    // แขนขวา (หมุนรอบหัวไหล่ 224, 152)
    canvas.save();
    canvas.translate(224, 152);
    canvas.rotate(rightAngle);
    canvas.translate(-224, -152);
    final rightArm = Path()
      ..moveTo(224, 152)
      ..quadraticBezierTo(246, 146, 254, 126);
    canvas.drawPath(rightArm, armPaint);
    canvas.restore();
  }

  void _paintRunningCat(Canvas canvas) {
    // sp-run keyframes
    double dx;
    double dy;
    double rotDeg;
    const runCurve = Cubic(0.3, 0.0, 0.3, 1.0);
    if (t < 0.40) {
      final p = runCurve.transform(_segment(t, 0.0, 0.40));
      dx = _lerp(-170, 58, p);
      dy = 0;
      rotDeg = 0;
    } else if (t < 0.50) {
      final p = runCurve.transform(_segment(t, 0.40, 0.50));
      dx = _lerp(58, 104, p);
      dy = _lerp(0, -40, p);
      rotDeg = _lerp(0, -8, p);
    } else if (t < 0.57) {
      final p = runCurve.transform(_segment(t, 0.50, 0.57));
      dx = _lerp(104, 116, p);
      dy = _lerp(-40, -16, p);
      rotDeg = _lerp(-8, 0, p);
    } else {
      dx = 116;
      dy = -16;
      rotDeg = 0;
    }

    // sp-bob (6 รอบในช่วง 0.00..0.40)
    double bobY = 0;
    if (t < 0.40) {
      final cycle = (t / 0.40) * 6.0;
      final frac = cycle - cycle.floorToDouble();
      bobY = -4.0 * math.sin(frac * math.pi);
    }

    // สลับขาหน้า/หลัง
    bool showLegsA = true;
    bool showLegsB = false;
    if (t < 0.40) {
      final cycle = (t / 0.40) * 6.0;
      final frac = cycle - cycle.floorToDouble();
      showLegsA = frac < 0.5;
      showLegsB = !showLegsA;
    } else {
      showLegsA = true;
      showLegsB = true;
    }

    // หางแกว่งตลอดเวลา
    final wagPhase = (t * 3.6) / 0.5;
    final wagFactor = 0.5 - 0.5 * math.cos(wagPhase * math.pi);
    final tailAngle = _lerp(-10, 14, wagFactor) * math.pi / 180;

    canvas.save();
    canvas.translate(dx, dy + bobY);
    if (rotDeg != 0) {
      canvas.translate(65, 140);
      canvas.rotate(rotDeg * math.pi / 180);
      canvas.translate(-65, -140);
    }

    // หาง
    canvas.save();
    canvas.translate(38, 150);
    canvas.rotate(tailAngle);
    canvas.translate(-38, -150);
    final tail = Path()
      ..moveTo(38, 150)
      ..quadraticBezierTo(16, 144, 20, 120);
    canvas.drawPath(
      tail,
      Paint()
        ..color = AppColors.splashCatDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();

    // ขาชุดหลัง (วาดใต้ตัว)
    if (showLegsB) {
      final legBPaint = Paint()..color = AppColors.splashCatDark;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(54, 160, 8, 18),
          const Radius.circular(4),
        ),
        legBPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(82, 160, 8, 18),
          const Radius.circular(4),
        ),
        legBPaint,
      );
    }

    // ลำตัว + ลายหลัง
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(62, 152), width: 56, height: 36),
      Paint()..color = AppColors.splashCatBody,
    );
    final stripe = Path()
      ..moveTo(48, 140)
      ..quadraticBezierTo(62, 134, 76, 140);
    canvas.drawPath(
      stripe,
      Paint()
        ..color = AppColors.splashCatStripe
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );

    // ขาชุดหน้า
    if (showLegsA) {
      final legAPaint = Paint()..color = AppColors.splashCatBody;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(44, 160, 8, 18),
          const Radius.circular(4),
        ),
        legAPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(72, 160, 8, 18),
          const Radius.circular(4),
        ),
        legAPaint,
      );
    }

    // หัว + หูนอก/ใน + หน้าแมว
    canvas.drawCircle(
      const Offset(94, 134),
      20,
      Paint()..color = AppColors.splashCatBody,
    );
    final earLeftOut = Path()
      ..moveTo(78, 122)
      ..lineTo(80, 100)
      ..lineTo(94, 116)
      ..close();
    final earRightOut = Path()
      ..moveTo(110, 122)
      ..lineTo(108, 100)
      ..lineTo(94, 116)
      ..close();
    final catPaint = Paint()..color = AppColors.splashCatBody;
    canvas.drawPath(earLeftOut, catPaint);
    canvas.drawPath(earRightOut, catPaint);

    final earLeftIn = Path()
      ..moveTo(82, 117)
      ..lineTo(83, 106)
      ..lineTo(90, 114)
      ..close();
    final earRightIn = Path()
      ..moveTo(106, 117)
      ..lineTo(105, 106)
      ..lineTo(98, 114)
      ..close();
    final earInPaint = Paint()..color = AppColors.splashShirt;
    canvas.drawPath(earLeftIn, earInPaint);
    canvas.drawPath(earRightIn, earInPaint);

    // ตายิ้มโค้ง
    final catEyePaint = Paint()
      ..color = AppColors.text
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(86, 134)
        ..quadraticBezierTo(89, 131, 92, 134),
      catEyePaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(98, 134)
        ..quadraticBezierTo(101, 131, 104, 134),
      catEyePaint,
    );

    // จมูก + แก้ม
    canvas.drawPath(
      Path()
        ..moveTo(93, 140)
        ..lineTo(97, 140)
        ..lineTo(95, 142.4)
        ..close(),
      Paint()..color = AppColors.heart,
    );
    final catCheek = Paint()
      ..color = AppColors.splashShirt.withValues(alpha: 0.6);
    canvas.drawCircle(const Offset(84, 142), 3, catCheek);
    canvas.drawCircle(const Offset(106, 142), 3, catCheek);

    canvas.restore();
  }

  void _paintHeart(
    Canvas canvas, {
    required double startT,
    required Offset tip,
    required bool large,
    required Color color,
  }) {
    if (t < startT) return;
    final elapsed = t - startT;
    final totalWindow = 1.0 - startT;
    final local = (elapsed / totalWindow).clamp(0.0, 1.0);

    double opacity;
    double dy;
    double scale;
    if (local < 0.18) {
      final p = Curves.easeOut.transform(local / 0.18);
      opacity = _lerp(0.0, 1.0, p);
      dy = _lerp(10, 0, p);
      scale = _lerp(0.3, 1.15, p);
    } else if (local < 0.32) {
      final p = (local - 0.18) / 0.14;
      opacity = 1.0;
      dy = _lerp(0, -4, p);
      scale = _lerp(1.15, 1.0, p);
    } else if (local < 0.82) {
      final p = (local - 0.32) / 0.50;
      opacity = 1.0;
      dy = _lerp(-4, -22, p);
      scale = 1.0;
    } else {
      final p = (local - 0.82) / 0.18;
      opacity = _lerp(1.0, 0.0, p);
      dy = _lerp(-22, -30, p);
      scale = _lerp(1.0, 0.9, p);
    }

    if (opacity <= 0.01) return;

    canvas.save();
    canvas.translate(tip.dx, tip.dy + dy);
    canvas.scale(scale);
    canvas.translate(-tip.dx, -tip.dy);

    final path = large
        ? (Path()
            ..moveTo(tip.dx, tip.dy - 26)
            ..cubicTo(
              tip.dx - 6,
              tip.dy - 36,
              tip.dx - 22,
              tip.dy - 32,
              tip.dx - 20,
              tip.dy - 20,
            )
            ..cubicTo(tip.dx - 18, tip.dy - 10, tip.dx, tip.dy, tip.dx, tip.dy)
            ..cubicTo(
              tip.dx,
              tip.dy,
              tip.dx + 18,
              tip.dy - 10,
              tip.dx + 20,
              tip.dy - 20,
            )
            ..cubicTo(
              tip.dx + 22,
              tip.dy - 32,
              tip.dx + 6,
              tip.dy - 36,
              tip.dx,
              tip.dy - 26,
            )
            ..close())
        : (Path()
            ..moveTo(tip.dx, tip.dy - 13)
            ..cubicTo(
              tip.dx - 3,
              tip.dy - 18,
              tip.dx - 11,
              tip.dy - 16,
              tip.dx - 10,
              tip.dy - 10,
            )
            ..cubicTo(tip.dx - 9, tip.dy - 5, tip.dx, tip.dy, tip.dx, tip.dy)
            ..cubicTo(
              tip.dx,
              tip.dy,
              tip.dx + 9,
              tip.dy - 5,
              tip.dx + 10,
              tip.dy - 10,
            )
            ..cubicTo(
              tip.dx + 11,
              tip.dy - 16,
              tip.dx + 3,
              tip.dy - 18,
              tip.dx,
              tip.dy - 13,
            )
            ..close());

    canvas.drawPath(path, Paint()..color = color.withValues(alpha: opacity));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SplashScenePainter oldDelegate) =>
      oldDelegate.t != t;
}

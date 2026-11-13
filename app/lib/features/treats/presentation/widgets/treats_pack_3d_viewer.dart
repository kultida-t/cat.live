import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/treat_item.dart';
import '../l10n/treats_l10n.dart';

/// เวทีแสดงแพ็กเกจขนมแบบลากหมุนดูได้ 360° พร้อมแอนิเมชันเด้งเข้าตะกร้า
class TreatsPack3dViewer extends StatefulWidget {
  const TreatsPack3dViewer({
    super.key,
    required this.treat,
    required this.cartCount,
    required this.hopTrigger,
    required this.isEn,
  });

  final TreatItem treat;
  final int cartCount;
  final int hopTrigger;
  final bool isEn;

  @override
  State<TreatsPack3dViewer> createState() => _TreatsPack3dViewerState();
}

class _TreatsPack3dViewerState extends State<TreatsPack3dViewer>
    with TickerProviderStateMixin {
  double _yaw = -0.3;
  double _pitch = -0.06;
  bool _dragging = false;
  Duration _lastInteract = Duration.zero;
  Duration _elapsed = Duration.zero;

  late final Ticker _ticker;
  late final AnimationController _hopController;

  @override
  void initState() {
    super.initState();
    _hopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _ticker = createTicker((elapsed) {
      _elapsed = elapsed;
      if (!_dragging &&
          !_hopController.isAnimating &&
          (elapsed - _lastInteract).inMilliseconds > 2500) {
        if (mounted) {
          setState(() {
            _yaw = (_yaw + 0.008) % (2 * math.pi);
          });
        }
      }
    })..start();
  }

  @override
  void didUpdateWidget(covariant TreatsPack3dViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hopTrigger != oldWidget.hopTrigger && widget.hopTrigger > 0) {
      _hopController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _hopController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 270,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.16),
          radius: 0.95,
          colors: [AppColors.treatsStageStart, AppColors.treatsStageEnd],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (_) {
                setState(() => _dragging = true);
                _lastInteract = _elapsed;
              },
              onPanUpdate: (details) {
                setState(() {
                  _yaw = (_yaw + details.delta.dx * 0.015) % (2 * math.pi);
                  _pitch = (_pitch - details.delta.dy * 0.008).clamp(
                    -0.55,
                    0.55,
                  );
                  _lastInteract = _elapsed;
                });
              },
              onPanEnd: (_) {
                setState(() => _dragging = false);
                _lastInteract = _elapsed;
              },
              onPanCancel: () => setState(() => _dragging = false),
              child: AnimatedBuilder(
                animation: _hopController,
                builder: (context, child) {
                  final t = _hopController.value;
                  var scale = 1.0;
                  var dx = 0.0;
                  var dy = 0.0;
                  var extraYaw = 0.0;

                  if (_hopController.isAnimating) {
                    if (t < 0.2) {
                      scale = 1.0 + 0.1 * math.sin((t / 0.2) * math.pi);
                    } else if (t < 0.7) {
                      final p = (t - 0.2) / 0.5;
                      dx = 110 * p;
                      dy = -110 * p - 24 * math.sin(p * math.pi);
                      scale = 1.0 - 0.85 * p;
                      extraYaw = 2.0 * p;
                    } else {
                      final p = (t - 0.7) / 0.3;
                      scale = p;
                    }
                  }

                  final totalYaw = _yaw + extraYaw;
                  final cosY = math.cos(totalYaw);
                  final isBack = cosY < 0;
                  final displayYaw = isBack ? totalYaw + math.pi : totalYaw;

                  final matrix = Matrix4.identity()
                    ..setEntry(3, 2, 0.0016)
                    ..rotateX(_pitch)
                    ..rotateY(displayYaw);

                  return Center(
                    child: Transform.translate(
                      offset: Offset(dx, dy),
                      child: Transform.scale(
                        scale: scale.clamp(0.05, 1.2),
                        child: Transform(
                          alignment: Alignment.center,
                          transform: matrix,
                          child: _PackArtwork(
                            treat: widget.treat,
                            isBack: isBack,
                            yaw: totalYaw,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (widget.cartCount > 0)
            Positioned(
              top: 12,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.sheetBarrier,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  TreatsL10n.inCartBadge(widget.isEn, widget.cartCount),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.treatsInk,
                  ),
                ),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 12,
            child: IgnorePointer(
              child: Text(
                TreatsL10n.drag360Hint(widget.isEn),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.text2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PackArtwork extends StatelessWidget {
  const _PackArtwork({
    required this.treat,
    required this.isBack,
    required this.yaw,
  });

  final TreatItem treat;
  final bool isBack;
  final double yaw;

  @override
  Widget build(BuildContext context) {
    final size = switch (treat.packShape) {
      TreatPackShape.pouch => const Size(146, 186),
      TreatPackShape.jar => const Size(134, 178),
      TreatPackShape.box => const Size(164, 172),
    };

    return SizedBox(
      width: size.width,
      height: size.height,
      child: CustomPaint(
        painter: _PackPainter(
          treat: treat,
          isBack: isBack,
          sideDepth: math.sin(yaw) * 14,
        ),
      ),
    );
  }
}

class _PackPainter extends CustomPainter {
  const _PackPainter({
    required this.treat,
    required this.isBack,
    required this.sideDepth,
  });

  final TreatItem treat;
  final bool isBack;
  final double sideDepth;

  @override
  void paint(Canvas canvas, Size size) {
    final baseColor = Color(treat.packColorHex);
    final darkerColor = Color.lerp(baseColor, AppColors.ink, 0.22)!;

    // เงาใต้แพ็กเกจ
    final shadowPaint = Paint()
      ..color = AppColors.treatsInk.withValues(alpha: 0.14)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height - 4),
        width: size.width * 0.78,
        height: 16,
      ),
      shadowPaint,
    );

    // ขอบข้าง 3 มิติเล็กน้อยตามมุมหมุน
    final bodyRect = Rect.fromLTWH(8, 12, size.width - 16, size.height - 20);
    final sideOffset = sideDepth.clamp(-12.0, 12.0);
    if (sideOffset.abs() > 1.5) {
      final sideRect = bodyRect.shift(Offset(sideOffset, 0));
      final sideRRect = RRect.fromRectAndRadius(
        sideRect,
        Radius.circular(treat.packShape == TreatPackShape.jar ? 24 : 16),
      );
      canvas.drawRRect(sideRRect, Paint()..color = darkerColor);
    }

    // ตัวแพ็กหลัก
    final radius = switch (treat.packShape) {
      TreatPackShape.pouch => const Radius.circular(18),
      TreatPackShape.jar => const Radius.circular(26),
      TreatPackShape.box => const Radius.circular(12),
    };
    final bodyRRect = RRect.fromRectAndRadius(bodyRect, radius);
    canvas.drawRRect(bodyRRect, Paint()..color = baseColor);

    // ฝาหรือแถบซีลด้านบน
    final lidRect = switch (treat.packShape) {
      TreatPackShape.pouch => Rect.fromLTWH(
        bodyRect.left + 4,
        bodyRect.top + 8,
        bodyRect.width - 8,
        8,
      ),
      TreatPackShape.jar => Rect.fromLTWH(
        bodyRect.left - 3,
        bodyRect.top - 4,
        bodyRect.width + 6,
        22,
      ),
      TreatPackShape.box => Rect.fromLTWH(
        bodyRect.left - 3,
        bodyRect.top - 2,
        bodyRect.width + 6,
        20,
      ),
    };
    canvas.drawRRect(
      RRect.fromRectAndRadius(lidRect, const Radius.circular(8)),
      Paint()..color = AppColors.treatsPackCream,
    );

    // ฉลากครีมตรงกลาง
    final labelRect = Rect.fromCenter(
      center: Offset(
        size.width / 2,
        size.height / 2 + (treat.packShape == TreatPackShape.pouch ? 6 : 8),
      ),
      width: bodyRect.width * 0.78,
      height: bodyRect.height * (isBack ? 0.62 : 0.74),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(labelRect, const Radius.circular(12)),
      Paint()..color = AppColors.treatsPackCream,
    );

    if (isBack) {
      _paintBackLabel(canvas, labelRect);
    } else {
      _paintFrontLabel(canvas, labelRect, baseColor);
    }
  }

  void _paintFrontLabel(Canvas canvas, Rect label, Color accent) {
    final cx = label.center.dx;

    // โลโก้ maew.live
    _drawCenteredText(
      canvas,
      'maew.live',
      Offset(cx, label.top + 16),
      const TextStyle(
        color: AppColors.ink,
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
    );
    _drawCenteredText(
      canvas,
      'LITTLE BITES, BIG LOVE',
      Offset(cx, label.top + 29),
      const TextStyle(
        color: AppColors.muted,
        fontSize: 6.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
    );

    // วงกลมสี + หน้าแมวน้อยตรงกลาง
    final badgeCenter = Offset(cx, label.center.dy - 2);
    canvas.drawCircle(badgeCenter, 26, Paint()..color = accent);

    final catPath = Path()
      ..moveTo(badgeCenter.dx - 16, badgeCenter.dy - 3)
      ..lineTo(badgeCenter.dx - 17, badgeCenter.dy - 17)
      ..lineTo(badgeCenter.dx - 7, badgeCenter.dy - 10)
      ..quadraticBezierTo(
        badgeCenter.dx,
        badgeCenter.dy - 13,
        badgeCenter.dx + 7,
        badgeCenter.dy - 10,
      )
      ..lineTo(badgeCenter.dx + 17, badgeCenter.dy - 17)
      ..lineTo(badgeCenter.dx + 16, badgeCenter.dy - 3)
      ..cubicTo(
        badgeCenter.dx + 20,
        badgeCenter.dy + 17,
        badgeCenter.dx - 20,
        badgeCenter.dy + 19,
        badgeCenter.dx - 16,
        badgeCenter.dy - 3,
      )
      ..close();
    canvas.drawPath(catPath, Paint()..color = AppColors.treatsPackFace);

    final eyePaint = Paint()
      ..color = AppColors.treatsPackStroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(badgeCenter.dx - 7, badgeCenter.dy + 1),
        width: 6,
        height: 5,
      ),
      math.pi,
      math.pi,
      false,
      eyePaint,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(badgeCenter.dx + 7, badgeCenter.dy + 1),
        width: 6,
        height: 5,
      ),
      math.pi,
      math.pi,
      false,
      eyePaint,
    );
    canvas.drawCircle(
      Offset(badgeCenter.dx, badgeCenter.dy + 5),
      2.2,
      Paint()..color = AppColors.treatsPackNose,
    );

    // ชื่อรสชาติ + ปริมาณ
    _drawCenteredText(
      canvas,
      treat.packLabel,
      Offset(cx, label.bottom - 26),
      const TextStyle(
        color: AppColors.ink,
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
      ),
    );
    _drawCenteredText(
      canvas,
      treat.packSize,
      Offset(cx, label.bottom - 13),
      const TextStyle(
        color: AppColors.text2,
        fontSize: 8.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  void _paintBackLabel(Canvas canvas, Rect label) {
    final cx = label.center.dx;
    _drawCenteredText(
      canvas,
      '100% CAT SAFE',
      Offset(cx, label.top + 20),
      const TextStyle(
        color: AppColors.ink,
        fontSize: 9,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.4,
      ),
    );
    final linePaint = Paint()
      ..color = AppColors.line2
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final y = label.top + 38 + i * 11.0;
      canvas.drawLine(
        Offset(label.left + 16, y),
        Offset(label.right - 16, y),
        linePaint,
      );
    }
    _drawCenteredText(
      canvas,
      'maew.live',
      Offset(cx, label.bottom - 16),
      const TextStyle(
        color: AppColors.muted,
        fontSize: 9,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  void _drawCenteredText(
    Canvas canvas,
    String text,
    Offset center,
    TextStyle style,
  ) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _PackPainter oldDelegate) =>
      oldDelegate.treat.id != treat.id ||
      oldDelegate.isBack != isBack ||
      (oldDelegate.sideDepth - sideDepth).abs() > 0.3;
}

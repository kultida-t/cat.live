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
  double _yaw = 0.34;
  double _pitch = 0.08;
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
                  final packWidget = _PackArtwork(
                    treat: widget.treat,
                    isBack: math.cos(totalYaw) < 0,
                    yaw: totalYaw,
                    pitch: _pitch,
                  );

                  return Center(
                    child: Transform.translate(
                      offset: Offset(dx, dy),
                      child: Transform.scale(
                        scale: scale.clamp(0.05, 1.2),
                        child: packWidget,
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
    required this.pitch,
  });

  final TreatItem treat;
  final bool isBack;
  final double yaw;
  final double pitch;

  @override
  Widget build(BuildContext context) {
    final size = switch (treat.packShape) {
      TreatPackShape.pouch => const Size(180, 210),
      TreatPackShape.jar => const Size(180, 210),
      TreatPackShape.box => const Size(186, 210),
    };

    return SizedBox(
      width: size.width,
      height: size.height,
      child: CustomPaint(
        painter: _PackPainter(
          treat: treat,
          isBack: isBack,
          yaw: yaw,
          pitch: pitch,
        ),
      ),
    );
  }
}

class _PackPainter extends CustomPainter {
  const _PackPainter({
    required this.treat,
    required this.isBack,
    required this.yaw,
    required this.pitch,
  });

  final TreatItem treat;
  final bool isBack;
  final double yaw;
  final double pitch;

  @override
  void paint(Canvas canvas, Size size) {
    final baseColor = Color(treat.packColorHex);

    // เงาใต้แพ็กเกจ
    final shadowPaint = Paint()
      ..color = AppColors.treatsInk.withValues(alpha: 0.14)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height - 4),
        width: size.width * 0.72,
        height: 16,
      ),
      shadowPaint,
    );

    switch (treat.packShape) {
      case TreatPackShape.pouch:
        _paintPouch(canvas, size, baseColor);
      case TreatPackShape.jar:
        _paintJar(canvas, size, baseColor);
      case TreatPackShape.box:
        _paintBox(canvas, size, baseColor);
    }
  }

  /// วาดถุงขนม 3 มิติแบบ Stand-up Pouch (ปากถุงแคบมีแถบซีล, ตัวถุงป่อง, ก้นกว้างโค้ง)
  void _paintPouch(Canvas canvas, Size size, Color baseColor) {
    final cx = size.width / 2;
    final cy = size.height / 2 - 4;
    const halfW = 42.0;
    const halfH = 62.0;
    const cameraDist = 420.0;
    const slices = 24;

    final cosY = math.cos(yaw);
    final sinY = math.sin(yaw);
    final cosX = math.cos(pitch);
    final sinX = math.sin(pitch);

    ({double x, double y, double z}) rotatePoint(double x, double y, double z) {
      final x1 = x * cosY + z * sinY;
      final z1 = -x * sinY + z * cosY;
      final y2 = y * cosX - z1 * sinX;
      final z2 = y * sinX + z1 * cosX;
      return (x: x1, y: y2, z: z2);
    }

    Offset projectPoint(({double x, double y, double z}) p) {
      final persp = cameraDist / (cameraDist - p.z);
      return Offset(cx + p.x * persp, cy + p.y * persp);
    }

    double widthAt(double t) {
      // ปากถุงแคบ (0.83) -> ป่องตรงกลาง (1.03) -> ก้นถุงกว้างกว่าปาก (0.90) + โค้งมนที่มุมบน/ล่าง
      double base;
      if (t < 0.55) {
        final u = t / 0.55;
        final ease = math.sin(u * math.pi / 2);
        base = halfW * (0.83 + 0.20 * ease);
      } else {
        final u = (t - 0.55) / 0.45;
        final ease = 1 - math.cos(u * math.pi / 2);
        base = halfW * (1.03 - 0.13 * ease);
      }
      if (t < 0.04) {
        final c = 1 - (t / 0.04);
        base -= 3.2 * (1 - math.sqrt(1 - c * c));
      } else if (t > 0.92) {
        final c = (t - 0.92) / 0.08;
        base -= 7.5 * (1 - math.sqrt(1 - c * c));
      }
      return base;
    }

    double depthAt(double t) {
      // ปากถุงบางเรียว (2.0) -> ก้นถุงหนาแบบ stand-up gusset (14.5)
      return 2.0 + 12.5 * math.pow(t, 0.72);
    }

    final frontLeft = <({double x, double y, double z})>[];
    final frontRight = <({double x, double y, double z})>[];
    final backLeft = <({double x, double y, double z})>[];
    final backRight = <({double x, double y, double z})>[];

    for (var i = 0; i <= slices; i++) {
      final t = i / slices;
      final y = -halfH + t * (halfH * 2);
      final w = widthAt(t);
      final d = depthAt(t);
      frontLeft.add(rotatePoint(-w, y, d));
      frontRight.add(rotatePoint(w, y, d));
      backLeft.add(rotatePoint(-w, y, -d));
      backRight.add(rotatePoint(w, y, -d));
    }

    final frontBottomMid = rotatePoint(0, halfH + 5, depthAt(1.0));
    final backBottomMid = rotatePoint(0, halfH + 5, -depthAt(1.0));

    // ค่าแสงสะท้อนพาสเทลสว่างตรงกับ Three.js บนเว็บจริง
    final litFront = Color.lerp(baseColor, Colors.white, 0.28)!;
    final shadedFront = Color.lerp(baseColor, Colors.white, 0.12)!;
    final litSide = Color.lerp(baseColor, Colors.white, 0.38)!;
    final shadedSide = Color.lerp(baseColor, AppColors.ink, 0.06)!;
    final sealTopColor = Color.lerp(baseColor, Colors.white, 0.42)!;
    final bottomColor = Color.lerp(baseColor, AppColors.ink, 0.14)!;

    // เช็กทิศการหันของแต่ละด้าน (Normal Z > 0 = หันเข้ากล้อง)
    final frontNormalZ = cosY * cosX;
    final leftNormalZ = sinY * cosX;
    final rightNormalZ = -sinY * cosX;
    final topNormalZ = -sinX;
    final bottomNormalZ = sinX;

    // วาดด้านที่อยู่ด้านหลังก่อน (เรียงลำดับความลึก)
    void drawFrontFace() {
      final path = Path()..moveTo(projectPoint(frontLeft[0]).dx, projectPoint(frontLeft[0]).dy);
      for (var i = 1; i <= slices; i++) {
        final p = projectPoint(frontRight[i - 1]);
        if (i == 1) path.lineTo(p.dx, p.dy);
      }
      for (var i = 1; i <= slices; i++) {
        final p = projectPoint(frontRight[i]);
        path.lineTo(p.dx, p.dy);
      }
      final botMid = projectPoint(frontBottomMid);
      final botLeft = projectPoint(frontLeft[slices]);
      path.quadraticBezierTo(botMid.dx, botMid.dy, botLeft.dx, botLeft.dy);
      for (var i = slices - 1; i >= 0; i--) {
        final p = projectPoint(frontLeft[i]);
        path.lineTo(p.dx, p.dy);
      }
      path.close();

      final bounds = path.getBounds();
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [litFront, shadedFront],
          ).createShader(bounds),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = Colors.white.withValues(alpha: 0.22),
      );
      _paintPouchLabel(
        canvas,
        rotatePoint: rotatePoint,
        projectPoint: projectPoint,
        isFront: true,
        accent: baseColor,
        zOffset: depthAt(0.5) + 0.6,
        labelW: 50,
        labelH: 82,
      );
    }

    void drawBackFace() {
      final path = Path()..moveTo(projectPoint(backRight[0]).dx, projectPoint(backRight[0]).dy);
      for (var i = 1; i <= slices; i++) {
        final p = projectPoint(backRight[i]);
        path.lineTo(p.dx, p.dy);
      }
      final botMid = projectPoint(backBottomMid);
      final botLeft = projectPoint(backLeft[slices]);
      path.quadraticBezierTo(botMid.dx, botMid.dy, botLeft.dx, botLeft.dy);
      for (var i = slices - 1; i >= 0; i--) {
        final p = projectPoint(backLeft[i]);
        path.lineTo(p.dx, p.dy);
      }
      path.close();

      final bounds = path.getBounds();
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [litFront, shadedFront],
          ).createShader(bounds),
      );
      _paintPouchLabel(
        canvas,
        rotatePoint: rotatePoint,
        projectPoint: projectPoint,
        isFront: false,
        accent: baseColor,
        zOffset: -(depthAt(0.5) + 0.6),
        labelW: 50,
        labelH: 82,
      );
    }

    void drawSideWall(
      List<({double x, double y, double z})> edgeA,
      List<({double x, double y, double z})> edgeB,
      Color color,
    ) {
      final path = Path()..moveTo(projectPoint(edgeA[0]).dx, projectPoint(edgeA[0]).dy);
      for (var i = 1; i <= slices; i++) {
        final p = projectPoint(edgeA[i]);
        path.lineTo(p.dx, p.dy);
      }
      for (var i = slices; i >= 0; i--) {
        final p = projectPoint(edgeB[i]);
        path.lineTo(p.dx, p.dy);
      }
      path.close();
      canvas.drawPath(path, Paint()..color = color);
    }

    void drawTopSeal() {
      final p0 = projectPoint(frontLeft[0]);
      final p1 = projectPoint(frontRight[0]);
      final p2 = projectPoint(backRight[0]);
      final p3 = projectPoint(backLeft[0]);
      final path = Path()
        ..moveTo(p0.dx, p0.dy)
        ..lineTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..lineTo(p3.dx, p3.dy)
        ..close();
      canvas.drawPath(path, Paint()..color = sealTopColor);
    }

    void drawBottomGusset() {
      final fl = projectPoint(frontLeft[slices]);
      final fm = projectPoint(frontBottomMid);
      final fr = projectPoint(frontRight[slices]);
      final br = projectPoint(backRight[slices]);
      final bm = projectPoint(backBottomMid);
      final bl = projectPoint(backLeft[slices]);
      final path = Path()
        ..moveTo(fl.dx, fl.dy)
        ..quadraticBezierTo(fm.dx, fm.dy, fr.dx, fr.dy)
        ..lineTo(br.dx, br.dy)
        ..quadraticBezierTo(bm.dx, bm.dy, bl.dx, bl.dy)
        ..close();
      canvas.drawPath(path, Paint()..color = bottomColor);
    }

    if (bottomNormalZ > -0.05) drawBottomGusset();
    if (topNormalZ > -0.05) drawTopSeal();

    if (frontNormalZ >= 0) {
      if (leftNormalZ > 0) drawSideWall(frontLeft, backLeft, litSide);
      if (rightNormalZ > 0) drawSideWall(frontRight, backRight, shadedSide);
      drawFrontFace();
    } else {
      if (leftNormalZ > 0) drawSideWall(frontLeft, backLeft, litSide);
      if (rightNormalZ > 0) drawSideWall(frontRight, backRight, shadedSide);
      drawBackFace();
    }
  }

  /// วาดกล่องขนมรวม 3 มิติ (ทรงสี่เหลี่ยม + ฝาสีครีมด้านบน + ฉลากหน้า/หลัง)
  void _paintBox(Canvas canvas, Size size, Color baseColor) {
    final cx = size.width / 2;
    final cy = size.height / 2 + 2;
    const halfW = 44.0;
    const halfD = 32.0;
    const bodyTop = -40.0;
    const bodyBot = 52.0;
    const lidTop = -51.0;
    const lidBot = -40.0;
    const lidHalfW = 46.0;
    const lidHalfD = 34.0;
    const cameraDist = 420.0;

    final cosY = math.cos(yaw);
    final sinY = math.sin(yaw);
    final cosX = math.cos(pitch);
    final sinX = math.sin(pitch);

    ({double x, double y, double z}) rotatePoint(double x, double y, double z) {
      final x1 = x * cosY + z * sinY;
      final z1 = -x * sinY + z * cosY;
      final y2 = y * cosX - z1 * sinX;
      final z2 = y * sinX + z1 * cosX;
      return (x: x1, y: y2, z: z2);
    }

    Offset projectPoint(({double x, double y, double z}) p) {
      final persp = cameraDist / (cameraDist - p.z);
      return Offset(cx + p.x * persp, cy + p.y * persp);
    }

    void drawQuad(
      ({double x, double y, double z}) a,
      ({double x, double y, double z}) b,
      ({double x, double y, double z}) c,
      ({double x, double y, double z}) d,
      Color color,
    ) {
      final pa = projectPoint(a);
      final pb = projectPoint(b);
      final pc = projectPoint(c);
      final pd = projectPoint(d);
      final path = Path()
        ..moveTo(pa.dx, pa.dy)
        ..lineTo(pb.dx, pb.dy)
        ..lineTo(pc.dx, pc.dy)
        ..lineTo(pd.dx, pd.dy)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
    }

    void drawPrism({
      required double w,
      required double d,
      required double top,
      required double bot,
      required Color frontColor,
      required Color leftColor,
      required Color rightColor,
      required Color topColor,
      required Color bottomColor,
      void Function()? onFrontDrawn,
      void Function()? onBackDrawn,
    }) {
      final flt = rotatePoint(-w, top, d);
      final frt = rotatePoint(w, top, d);
      final frb = rotatePoint(w, bot, d);
      final flb = rotatePoint(-w, bot, d);
      final blt = rotatePoint(-w, top, -d);
      final brt = rotatePoint(w, top, -d);
      final brb = rotatePoint(w, bot, -d);
      final blb = rotatePoint(-w, bot, -d);

      if (sinX > 0) drawQuad(flb, frb, brb, blb, bottomColor);
      if (sinX < 0) drawQuad(blt, brt, frt, flt, topColor);

      if (sinY > 0) drawQuad(blt, flt, flb, blb, leftColor);
      if (sinY < 0) drawQuad(frt, brt, brb, frb, rightColor);

      if (cosY >= 0) {
        drawQuad(flt, frt, frb, flb, frontColor);
        onFrontDrawn?.call();
      } else {
        drawQuad(brt, blt, blb, brb, frontColor);
        onBackDrawn?.call();
      }
    }

    final frontColor = Color.lerp(baseColor, Colors.white, 0.24)!;
    final leftColor = Color.lerp(baseColor, Colors.white, 0.30)!;
    final rightColor = Color.lerp(baseColor, AppColors.ink, 0.08)!;
    final bottomColor = Color.lerp(baseColor, AppColors.ink, 0.22)!;

    void drawBody() => drawPrism(
      w: halfW,
      d: halfD,
      top: bodyTop,
      bot: bodyBot,
      frontColor: frontColor,
      leftColor: leftColor,
      rightColor: rightColor,
      topColor: frontColor,
      bottomColor: bottomColor,
      onFrontDrawn: () => _paintPouchLabel(
        canvas,
        rotatePoint: (x, y, z) => rotatePoint(x, y + 6, z),
        projectPoint: projectPoint,
        isFront: true,
        accent: baseColor,
        zOffset: halfD + 0.6,
        labelW: 54,
        labelH: 70,
      ),
      onBackDrawn: () => _paintPouchLabel(
        canvas,
        rotatePoint: (x, y, z) => rotatePoint(x, y + 6, z),
        projectPoint: projectPoint,
        isFront: false,
        accent: baseColor,
        zOffset: -(halfD + 0.6),
        labelW: 54,
        labelH: 70,
      ),
    );

    final lidFront = const Color(0xFFFFFDF8);
    final lidLeft = Colors.white;
    final lidSide = Color.lerp(AppColors.treatsPackCream, AppColors.ink, 0.10)!;
    final lidTopCol = Colors.white;
    final lidBotCol = Color.lerp(AppColors.treatsPackCream, AppColors.ink, 0.16)!;

    void drawLid() => drawPrism(
      w: lidHalfW,
      d: lidHalfD,
      top: lidTop,
      bot: lidBot,
      frontColor: lidFront,
      leftColor: lidLeft,
      rightColor: lidSide,
      topColor: lidTopCol,
      bottomColor: lidBotCol,
    );

    // เรียงลำดับความลึก: ถ้ามองจากด้านล่าง (sinX > 0) ให้วาดฝาก่อนตัวกล่อง จะได้ไม่ทะลุ
    if (sinX > 0) {
      drawLid();
      drawBody();
    } else {
      drawBody();
      drawLid();
    }
  }

  /// วาดกระปุกขนม 3 มิติ (ทรงกระบอกสีพาสเทล + ฝาสีครีม + ฉลากหมุนตามทรงกระบอก)
  void _paintJar(Canvas canvas, Size size, Color baseColor) {
    final cx = size.width / 2;
    final cy = size.height / 2 + 4;
    const radius = 40.0;
    const lidRadius = 42.5;
    const bodyTop = -38.0;
    const bodyBot = 50.0;
    const lidTop = -50.0;
    const lidBot = -38.0;
    const cameraDist = 420.0;

    final cosY = math.cos(yaw);
    final sinY = math.sin(yaw);
    final cosX = math.cos(pitch);
    final sinX = math.sin(pitch);

    ({double x, double y, double z}) rotatePoint(double x, double y, double z) {
      final x1 = x * cosY + z * sinY;
      final z1 = -x * sinY + z * cosY;
      final y2 = y * cosX - z1 * sinX;
      final z2 = y * sinX + z1 * cosX;
      return (x: x1, y: y2, z: z2);
    }

    Offset projectPoint(({double x, double y, double z}) p) {
      final persp = cameraDist / (cameraDist - p.z);
      return Offset(cx + p.x * persp, cy + p.y * persp);
    }

    Path drawCylinder({
      required double r,
      required double top,
      required double bot,
      required Color leftCol,
      required Color midCol,
      required Color rightCol,
      required Color capCol,
    }) {
      const steps = 28;
      final topPts = <Offset>[];
      final botPts = <Offset>[];
      for (var i = 0; i <= steps; i++) {
        final a = -math.pi / 2 + (i / steps) * math.pi;
        final x = r * math.sin(a);
        final z = r * math.cos(a);
        // หมุนเฉพาะ pitch รอบแกน X สำหรับทรงกระบอกสมมาตรแกน Y
        final yt = top * cosX - z * sinX;
        final zt = top * sinX + z * cosX;
        final yb = bot * cosX - z * sinX;
        final zb = bot * sinX + z * cosX;
        topPts.add(projectPoint((x: x, y: yt, z: zt)));
        botPts.add(projectPoint((x: x, y: yb, z: zb)));
      }

      final bodyPath = Path()..moveTo(topPts.first.dx, topPts.first.dy);
      for (final p in topPts.skip(1)) {
        bodyPath.lineTo(p.dx, p.dy);
      }
      for (final p in botPts.reversed) {
        bodyPath.lineTo(p.dx, p.dy);
      }
      bodyPath.close();

      canvas.drawPath(
        bodyPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [leftCol, midCol, rightCol],
            stops: const [0.0, 0.42, 1.0],
          ).createShader(bodyPath.getBounds()),
      );

      // ฝาบนหรือก้นวงรีเมื่อก้ม/เงย
      if (sinX.abs() > 0.03) {
        final ringY = sinX < 0 ? top : bot;
        final ringPts = <Offset>[];
        for (var i = 0; i < steps; i++) {
          final a = (i / steps) * 2 * math.pi;
          final x = r * math.sin(a);
          final z = r * math.cos(a);
          final yr = ringY * cosX - z * sinX;
          final zr = ringY * sinX + z * cosX;
          ringPts.add(projectPoint((x: x, y: yr, z: zr)));
        }
        final capPath = Path()..moveTo(ringPts.first.dx, ringPts.first.dy);
        for (final p in ringPts.skip(1)) {
          capPath.lineTo(p.dx, p.dy);
        }
        capPath.close();
        canvas.drawPath(
          capPath,
          Paint()
            ..color = sinX < 0
                ? capCol
                : Color.lerp(rightCol, AppColors.ink, 0.12)!,
        );
      }
      return bodyPath;
    }

    final jarLit = Color.lerp(baseColor, Colors.white, 0.38)!;
    final jarMid = Color.lerp(baseColor, Colors.white, 0.22)!;
    final jarShade = Color.lerp(baseColor, AppColors.ink, 0.04)!;

    void drawJarBody() {
      final jarBodyPath = drawCylinder(
        r: radius,
        top: bodyTop,
        bot: bodyBot,
        leftCol: jarLit,
        midCol: jarMid,
        rightCol: jarShade,
        capCol: jarMid,
      );

      // ฉลากหน้า/หลังหมุนตามผิวกระปุก (คลิปให้อยู่ในขอบกระปุก)
      canvas.save();
      canvas.clipPath(jarBodyPath);
      if (cosY >= -0.15) {
        _paintPouchLabel(
          canvas,
          rotatePoint: (x, y, z) => rotatePoint(x, y + 6, z),
          projectPoint: projectPoint,
          isFront: true,
          accent: baseColor,
          zOffset: radius + 0.8,
          labelW: 46,
          labelH: 66,
        );
      } else {
        _paintPouchLabel(
          canvas,
          rotatePoint: (x, y, z) => rotatePoint(x, y + 6, z),
          projectPoint: projectPoint,
          isFront: false,
          accent: baseColor,
          zOffset: -(radius + 0.8),
          labelW: 46,
          labelH: 66,
        );
      }
      canvas.restore();
    }

    // ฝากระปุกสีครีมด้านบน (ไล่เงาชัดขึ้นไม่ให้กลืนกับพื้นหลัง)
    void drawJarLid() => drawCylinder(
      r: lidRadius,
      top: lidTop,
      bot: lidBot,
      leftCol: Colors.white,
      midCol: const Color(0xFFFFFCF3),
      rightCol: Color.lerp(AppColors.treatsPackCream, AppColors.ink, 0.11)!,
      capCol: Colors.white,
    );

    if (sinX > 0) {
      drawJarLid();
      drawJarBody();
    } else {
      drawJarBody();
      drawJarLid();
    }
  }

  void _paintPouchLabel(
    Canvas canvas, {
    required ({double x, double y, double z}) Function(double, double, double)
    rotatePoint,
    required Offset Function(({double x, double y, double z})) projectPoint,
    required bool isFront,
    required Color accent,
    required double zOffset,
    double labelW = 64.0,
    double labelH = 112.0,
  }) {
    final hw = labelW / 2;
    final hh = labelH / 2;

    final pTL = projectPoint(rotatePoint(isFront ? -hw : hw, -hh, zOffset));
    final pTR = projectPoint(rotatePoint(isFront ? hw : -hw, -hh, zOffset));
    final pBR = projectPoint(rotatePoint(isFront ? hw : -hw, hh, zOffset));
    final pBL = projectPoint(rotatePoint(isFront ? -hw : hw, hh, zOffset));

    final labelPath = Path()
      ..moveTo(pTL.dx, pTL.dy)
      ..lineTo(pTR.dx, pTR.dy)
      ..lineTo(pBR.dx, pBR.dy)
      ..lineTo(pBL.dx, pBL.dy)
      ..close();
    canvas.drawPath(labelPath, Paint()..color = AppColors.treatsPackCream);

    if (!isFront) return;

    final ux = (pTR.dx - pTL.dx) / labelW;
    final uy = (pTR.dy - pTL.dy) / labelW;
    final vx = (pBL.dx - pTL.dx) / labelH;
    final vy = (pBL.dy - pTL.dy) / labelH;

    final affine = Matrix4(
      ux,
      uy,
      0,
      0,
      vx,
      vy,
      0,
      0,
      0,
      0,
      1,
      0,
      pTL.dx,
      pTL.dy,
      0,
      1,
    );
    canvas.save();
    canvas.transform(affine.storage);
    _paintFrontLabel(
      canvas,
      Rect.fromLTWH(0, 0, labelW, labelH),
      accent,
      compact: true,
    );
    canvas.restore();
  }

  void _paintFrontLabel(
    Canvas canvas,
    Rect label,
    Color accent, {
    bool compact = false,
  }) {
    final cx = label.center.dx;
    final s = compact ? (label.width / 64.0).clamp(0.65, 1.0) : 1.0;
    final badgeRadius = compact ? 16.0 * s : 26.0;
    final faceScale = compact ? 0.62 * s : 1.0;

    // โลโก้ maew.live
    _drawCenteredText(
      canvas,
      'maew.live',
      Offset(cx, label.top + (compact ? 11 * s : 16)),
      TextStyle(
        color: AppColors.ink,
        fontSize: compact ? 8.5 * s : 13,
        fontWeight: FontWeight.w800,
      ),
    );
    _drawCenteredText(
      canvas,
      'LITTLE BITES, BIG LOVE',
      Offset(cx, label.top + (compact ? 18 * s : 29)),
      TextStyle(
        color: AppColors.muted,
        fontSize: compact ? 3.8 * s : 6.5,
        fontWeight: FontWeight.w600,
        letterSpacing: compact ? 0.15 : 0.4,
      ),
    );

    // วงกลมสี + หน้าแมวน้อยตรงกลาง
    final badgeCenter = Offset(cx, label.center.dy - (compact ? 1.5 * s : 2));
    canvas.drawCircle(badgeCenter, badgeRadius, Paint()..color = accent);

    final catPath = Path()
      ..moveTo(badgeCenter.dx - 16 * faceScale, badgeCenter.dy - 3 * faceScale)
      ..lineTo(badgeCenter.dx - 17 * faceScale, badgeCenter.dy - 17 * faceScale)
      ..lineTo(badgeCenter.dx - 7 * faceScale, badgeCenter.dy - 10 * faceScale)
      ..quadraticBezierTo(
        badgeCenter.dx,
        badgeCenter.dy - 13 * faceScale,
        badgeCenter.dx + 7 * faceScale,
        badgeCenter.dy - 10 * faceScale,
      )
      ..lineTo(badgeCenter.dx + 17 * faceScale, badgeCenter.dy - 17 * faceScale)
      ..lineTo(badgeCenter.dx + 16 * faceScale, badgeCenter.dy - 3 * faceScale)
      ..cubicTo(
        badgeCenter.dx + 20 * faceScale,
        badgeCenter.dy + 17 * faceScale,
        badgeCenter.dx - 20 * faceScale,
        badgeCenter.dy + 19 * faceScale,
        badgeCenter.dx - 16 * faceScale,
        badgeCenter.dy - 3 * faceScale,
      )
      ..close();
    canvas.drawPath(catPath, Paint()..color = AppColors.treatsPackFace);

    final eyePaint = Paint()
      ..color = AppColors.treatsPackStroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * faceScale
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(
          badgeCenter.dx - 7 * faceScale,
          badgeCenter.dy + 1 * faceScale,
        ),
        width: 6 * faceScale,
        height: 5 * faceScale,
      ),
      math.pi,
      math.pi,
      false,
      eyePaint,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(
          badgeCenter.dx + 7 * faceScale,
          badgeCenter.dy + 1 * faceScale,
        ),
        width: 6 * faceScale,
        height: 5 * faceScale,
      ),
      math.pi,
      math.pi,
      false,
      eyePaint,
    );
    canvas.drawCircle(
      Offset(badgeCenter.dx, badgeCenter.dy + 5 * faceScale),
      2.2 * faceScale,
      Paint()..color = AppColors.treatsPackNose,
    );

    // ชื่อรสชาติ + ปริมาณ
    _drawCenteredText(
      canvas,
      treat.packLabel,
      Offset(cx, label.bottom - (compact ? 17 * s : 26)),
      TextStyle(
        color: AppColors.ink,
        fontSize: compact ? 7.2 * s : 10.5,
        fontWeight: FontWeight.w800,
      ),
    );
    _drawCenteredText(
      canvas,
      treat.packSize,
      Offset(cx, label.bottom - (compact ? 8.5 * s : 13)),
      TextStyle(
        color: AppColors.text2,
        fontSize: compact ? 5.8 * s : 8.5,
        fontWeight: FontWeight.w600,
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
      (oldDelegate.yaw - yaw).abs() > 0.005 ||
      (oldDelegate.pitch - pitch).abs() > 0.005;
}

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../core/theme/app_colors.dart';

enum Tag3dMode { tagOnly, collarWithTag }

/// พรีวิว 3 มิติของแท็กและปลอกคอ แสดงเป็นวัตถุทึบ (เห็นเฉพาะผิวด้านนอก) หมุนและลากหมุนได้
/// ตามโมเดล Three.js บนเว็บ www.แมว.live/tag
class Tag3dViewer extends StatefulWidget {
  const Tag3dViewer({
    super.key,
    required this.mode,
    required this.tagColor,
    this.collarColor = AppColors.tagCollarNavy,
    this.height = 240,
  });

  final Tag3dMode mode;
  final Color tagColor;
  final Color collarColor;
  final double height;

  @override
  State<Tag3dViewer> createState() => _Tag3dViewerState();
}

class _Tag3dViewerState extends State<Tag3dViewer>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;
  double _time = 0;
  double _yawBase = 0;
  late double _pitch;
  bool _autoRotate = true;

  bool get _isHero => widget.mode == Tag3dMode.tagOnly;

  @override
  void initState() {
    super.initState();
    _yawBase = _isHero ? -0.35 : -0.50;
    _pitch = _isHero ? -0.12 : 0.24;
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final dt = (_lastTick == Duration.zero)
        ? 0.016
        : (elapsed - _lastTick).inMicroseconds / 1000000.0;
    _lastTick = elapsed;
    if (!_autoRotate) return;
    setState(() {
      _time += dt;
    });
  }

  /// มุมหมุนปัจจุบันรอบแกนตั้ง (ถ้าลากแล้ว หยุดหมุนอัตโนมัติและคงมุมเดิม)
  double get _yaw => _yawBase + _autoOffset;

  double get _autoOffset {
    if (!_autoRotate) return 0;
    return _isHero ? _heroMotion(_time) : _time * 0.50;
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (_) {
        setState(() {
          _yawBase = _yaw;
          _autoRotate = false;
        });
      },
      onPanUpdate: (details) {
        setState(() {
          _yawBase += details.delta.dx * 0.012;
          if (_isHero) {
            _pitch = (_pitch + details.delta.dy * 0.009).clamp(-1.2, 1.2);
          }
        });
      },
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: CustomPaint(
          painter: _Tag3dPainter(
            mode: widget.mode,
            tagColor: widget.tagColor,
            collarColor: widget.collarColor,
            yaw: _yaw,
            pitch: _pitch,
          ),
        ),
      ),
    );
  }
}

/// การเคลื่อนไหวของแท็กตัวบนสุด (ฟังก์ชันของเวลาเป็นวินาที)
double _heroMotion(double t) => t * 0.55;

class _V3 {
  const _V3(this.x, this.y, this.z);
  final double x;
  final double y;
  final double z;
}

/// กล้องแบบเปอร์สเปกทีฟ: หมุนวัตถุรอบแกน Y แล้วรอบแกน X จากนั้นฉายลงจอ
class _Cam {
  _Cam({
    required this.cx,
    required this.cy,
    required double yaw,
    required double pitch,
  }) : _cosY = math.cos(yaw),
       _sinY = math.sin(yaw),
       _cosP = math.cos(pitch),
       _sinP = math.sin(pitch);

  final double cx;
  final double cy;
  final double focal = 600;
  final double _cosY;
  final double _sinY;
  final double _cosP;
  final double _sinP;

  double get cosYaw => _cosY;

  _V3 rotate(_V3 v) {
    final x1 = v.x * _cosY + v.z * _sinY;
    final z1 = -v.x * _sinY + v.z * _cosY;
    final y2 = v.y * _cosP - z1 * _sinP;
    final z2 = v.y * _sinP + z1 * _cosP;
    return _V3(x1, y2, z2);
  }

  Offset project(_V3 v) {
    final r = rotate(v);
    final s = focal / (focal - r.z);
    return Offset(cx + r.x * s, cy + r.y * s);
  }
}

class _Face {
  _Face(this.points, this.depth, this.color, {this.isStroke = false, this.strokeWidth = 0.8});
  final List<Offset> points;
  final double depth;
  final Color color;
  final bool isStroke;
  final double strokeWidth;
}

class _Tag3dPainter extends CustomPainter {
  const _Tag3dPainter({
    required this.mode,
    required this.tagColor,
    required this.collarColor,
    required this.yaw,
    required this.pitch,
  });

  final Tag3dMode mode;
  final Color tagColor;
  final Color collarColor;
  final double yaw;
  final double pitch;

  // ขนาดตัวเรือนแท็กหน่วยพิกเซลก่อนขยาย
  static const double _bodyW = 86;
  static const double _bodyH = 104;
  static const int _segments = 120;

  static List<Offset>? _outlineCache;

  /// เส้นขอบรูปหัวแมว สุ่มจุดจากเส้นโค้งเบซิเยร์ (ทิศตามเข็มนาฬิกาบนจอ)
  static List<Offset> get _outline {
    final cached = _outlineCache;
    if (cached != null) return cached;
    final path = _buildCatPath(_bodyW, _bodyH);
    final metric = path.computeMetrics().first;
    final points = <Offset>[];
    for (var i = 0; i < _segments; i++) {
      final tangent = metric.getTangentForOffset(
        metric.length * i / _segments,
      );
      points.add(tangent!.position);
    }
    return _outlineCache = points;
  }

  static Path _buildCatPath(double w, double h) {
    final halfW = w / 2;
    final topY = -h * 0.42;
    final earTipY = -h * 0.54;
    final cheekY = -h * 0.12;
    final bottomY = h * 0.48;
    return Path()
      ..moveTo(-halfW * 0.30, topY + h * 0.08)
      ..quadraticBezierTo(
        -halfW * 0.56,
        earTipY - h * 0.04,
        -halfW * 0.86,
        earTipY + h * 0.08,
      )
      ..quadraticBezierTo(-halfW * 1.04, cheekY, -halfW, h * 0.12)
      ..cubicTo(-halfW, bottomY, halfW, bottomY, halfW, h * 0.12)
      ..quadraticBezierTo(
        halfW * 1.04,
        cheekY,
        halfW * 0.86,
        earTipY + h * 0.08,
      )
      ..quadraticBezierTo(
        halfW * 0.56,
        earTipY - h * 0.04,
        halfW * 0.30,
        topY + h * 0.08,
      )
      ..quadraticBezierTo(0, topY + h * 0.12, -halfW * 0.30, topY + h * 0.08)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    if (mode == Tag3dMode.tagOnly) {
      final haloPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white,
            AppColors.tagHeroGlowMid,
            AppColors.tagBgMid.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.55, 0.72],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 130));
      canvas.drawCircle(Offset(cx, cy), 130, haloPaint);

      _drawTag(
        canvas,
        _Cam(cx: cx, cy: cy, yaw: yaw, pitch: pitch),
        scale: 1.9,
      );
    } else {
      _paintCollarWithTag(canvas, cx, cy);
    }
  }

  void _paintCollarWithTag(Canvas canvas, double cx, double cy) {
    final cam = _Cam(cx: cx, cy: cy - 10, yaw: yaw, pitch: -0.22);

    final shadowPaint = Paint()
      ..color = AppColors.tagTextDark.withValues(alpha: 0.09)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 70), width: 170, height: 18),
      shadowPaint,
    );

    final faces = <_Face>[];
    const rOut = 104.0;
    const rIn = 99.0;
    const yTop = -23.0;
    const yBot = -1.0;
    const segs = 72;

    final innerBase = Color.lerp(collarColor, Colors.black, 0.18)!;
    final rimBase = Color.lerp(collarColor, Colors.white, 0.10)!;
    final isLightCollar = collarColor.computeLuminance() > 0.72;
    final stitchColor = isLightCollar
        ? AppColors.tagTextMuted.withValues(alpha: 0.35)
        : Colors.white.withValues(alpha: 0.55);

    void addQuad(_V3 a, _V3 b, _V3 c, _V3 d, _V3 normal, Color base) {
      final rn = cam.rotate(normal);
      if (rn.z <= 0.02) return;
      final ra = cam.rotate(a);
      final rb = cam.rotate(b);
      final rc = cam.rotate(c);
      final rd = cam.rotate(d);
      faces.add(
        _Face(
          [cam.project(a), cam.project(b), cam.project(c), cam.project(d)],
          (ra.z + rb.z + rc.z + rd.z) / 4,
          _shade(base, _intensity(rn)),
        ),
      );
    }

    // สร้างสายปลอกคอ 3 มิติโค้งเนียนทึบจริง (ผนังนอก + ผนังใน + ขอบบน)
    for (var i = 0; i < segs; i++) {
      final a0 = i / segs * math.pi * 2;
      final a1 = (i + 1) / segs * math.pi * 2;
      final am = (a0 + a1) / 2;
      final sx0 = math.sin(a0);
      final cz0 = math.cos(a0);
      final sx1 = math.sin(a1);
      final cz1 = math.cos(a1);
      final nx = math.sin(am);
      final nz = math.cos(am);

      // ผนังด้านนอก
      addQuad(
        _V3(rOut * sx0, yTop, rOut * cz0),
        _V3(rOut * sx1, yTop, rOut * cz1),
        _V3(rOut * sx1, yBot, rOut * cz1),
        _V3(rOut * sx0, yBot, rOut * cz0),
        _V3(nx, 0, nz),
        collarColor,
      );

      // ผนังด้านใน
      addQuad(
        _V3(rIn * sx1, yTop, rIn * cz1),
        _V3(rIn * sx0, yTop, rIn * cz0),
        _V3(rIn * sx0, yBot, rIn * cz0),
        _V3(rIn * sx1, yBot, rIn * cz1),
        _V3(-nx, 0, -nz),
        innerBase,
      );

      // ขอบบนของสายปลอกคอ
      addQuad(
        _V3(rIn * sx0, yTop, rIn * cz0),
        _V3(rIn * sx1, yTop, rIn * cz1),
        _V3(rOut * sx1, yTop, rOut * cz1),
        _V3(rOut * sx0, yTop, rOut * cz0),
        const _V3(0, -1, 0),
        rimBase,
      );

      // แถบสะท้อนแสงตรงกลาง + รอยเย็บขอบบน-ล่าง (เฉพาะส่วนที่ไม่ถูกตัวล็อกด้านหลังบัง)
      final inBuckleZone = (am - math.pi).abs() < 0.14;
      final rn = cam.rotate(_V3(nx, 0, nz));
      if (!inBuckleZone && rn.z > 0.05) {
        final yMidTop = (yTop + yBot) / 2 - 1.6;
        final yMidBot = (yTop + yBot) / 2 + 1.6;
        addQuad(
          _V3((rOut + 0.4) * sx0, yMidTop, (rOut + 0.4) * cz0),
          _V3((rOut + 0.4) * sx1, yMidTop, (rOut + 0.4) * cz1),
          _V3((rOut + 0.4) * sx1, yMidBot, (rOut + 0.4) * cz1),
          _V3((rOut + 0.4) * sx0, yMidBot, (rOut + 0.4) * cz0),
          _V3(nx, 0, nz),
          const Color(0xFFDCE4E2),
        );

        for (final ySt in [yTop + 3.2, yBot - 3.2]) {
          final p0 = _V3((rOut + 0.5) * sx0, ySt, (rOut + 0.5) * cz0);
          final p1 = _V3((rOut + 0.5) * sx1, ySt, (rOut + 0.5) * cz1);
          faces.add(
            _Face(
              [cam.project(p0), cam.project(p1)],
              (cam.rotate(p0).z + cam.rotate(p1).z) / 2 + 0.2,
              stitchColor,
              isStroke: true,
              strokeWidth: 0.9,
            ),
          );
        }
      }
    }

    // ตัวล็อกบัคเคิล 3 มิติครบ 6 ด้าน ครอบติดแนบสนิทกับสายปลอกคอที่ด้านหลัง
    const bColor = Color(0xFFF4F4F2);
    const bx0 = -12.0;
    const bx1 = 12.0;
    const by0 = yTop - 1.5;
    const by1 = yBot + 1.5;
    const bz0 = -rOut - 3.0; // ด้านนอกสุด
    const bz1 = -rIn + 3.0; // ด้านในสุด
    // หน้าหลัง (นอก)
    addQuad(
      const _V3(bx0, by0, bz0),
      const _V3(bx1, by0, bz0),
      const _V3(bx1, by1, bz0),
      const _V3(bx0, by1, bz0),
      const _V3(0, 0, -1),
      bColor,
    );
    // หน้าใน
    addQuad(
      const _V3(bx1, by0, bz1),
      const _V3(bx0, by0, bz1),
      const _V3(bx0, by1, bz1),
      const _V3(bx1, by1, bz1),
      const _V3(0, 0, 1),
      bColor,
    );
    // ข้างซ้าย
    addQuad(
      const _V3(bx0, by0, bz1),
      const _V3(bx0, by0, bz0),
      const _V3(bx0, by1, bz0),
      const _V3(bx0, by1, bz1),
      const _V3(-1, 0, 0),
      bColor,
    );
    // ข้างขวา
    addQuad(
      const _V3(bx1, by0, bz0),
      const _V3(bx1, by0, bz1),
      const _V3(bx1, by1, bz1),
      const _V3(bx1, by1, bz0),
      const _V3(1, 0, 0),
      bColor,
    );
    // ฝาบน
    addQuad(
      const _V3(bx0, by0, bz1),
      const _V3(bx1, by0, bz1),
      const _V3(bx1, by0, bz0),
      const _V3(bx0, by0, bz0),
      const _V3(0, -1, 0),
      bColor,
    );
    // ฝาล่าง
    addQuad(
      const _V3(bx0, by1, bz0),
      const _V3(bx1, by1, bz0),
      const _V3(bx1, by1, bz1),
      const _V3(bx0, by1, bz1),
      const _V3(0, 1, 0),
      bColor,
    );

    // วาดครึ่งหลังของสายปลอกคอ (depth <= 0) ก่อน แล้ววาดแท็กเมื่ออยู่ด้านหลัง หรือวาดครึ่งหน้าทับ
    final tagAnchor = const _V3(0, 22, rOut + 3);
    final tagDepth = cam.rotate(tagAnchor).z;
    final tagOnFront = tagDepth >= 0;

    void paintFaces({required bool frontHalf}) {
      final subset = faces
          .where((f) => frontHalf ? f.depth >= 0 : f.depth < 0)
          .toList()
        ..sort((a, b) => a.depth.compareTo(b.depth));
      for (final f in subset) {
        if (f.isStroke) {
          canvas.drawLine(
            f.points[0],
            f.points[1],
            Paint()
              ..color = f.color
              ..strokeWidth = f.strokeWidth
              ..strokeCap = StrokeCap.round,
          );
        } else {
          final path = Path()..addPolygon(f.points, true);
          canvas.drawPath(path, Paint()..color = f.color);
          canvas.drawPath(
            path,
            Paint()
              ..color = f.color
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.7,
          );
        }
      }
    }

    void paintAttachedTag() {
      final tagScreen = cam.project(tagAnchor);
      _drawTag(
        canvas,
        _Cam(cx: tagScreen.dx, cy: tagScreen.dy, yaw: yaw, pitch: -0.18),
        scale: 0.92,
        withRing: true,
      );
    }

    // เมื่อแท็กอยู่ฝั่งหลังของปลอกคอ วาดไว้หลังสุดเพื่อให้สายปลอกคอทึบบังแท็กจริง (ไม่ทะลุ)
    if (!tagOnFront) paintAttachedTag();
    paintFaces(frontHalf: false);
    paintFaces(frontHalf: true);
    if (tagOnFront) paintAttachedTag();
  }

  // แสงตกกระทบจากซ้ายบนด้านหน้า
  static const double _lx = -0.35;
  static const double _ly = -0.55;
  static const double _lz = 0.76;

  double _intensity(_V3 n) {
    final len = math.sqrt(n.x * n.x + n.y * n.y + n.z * n.z);
    if (len == 0) return 0;
    final d = (n.x * _lx + n.y * _ly + n.z * _lz) / len;
    return d.clamp(0.0, 1.0);
  }

  Color _shade(Color base, double intensity) {
    final shade = 0.28 + 0.72 * intensity;
    final dark = Color.lerp(base, Colors.black, 0.36)!;
    final light = Color.lerp(base, Colors.white, 0.22)!;
    final c = Color.lerp(dark, light, shade)!;
    if (intensity > 0.76) {
      final spec = math.pow((intensity - 0.76) / 0.24, 1.6).toDouble() * 0.42;
      return Color.lerp(c, Colors.white, spec.clamp(0.0, 0.65))!;
    }
    return c;
  }

  /// วาดแท็กเป็นวัตถุทึบ: ผนังข้าง ขอบมนโค้งกลมหลายขั้น ฝาหน้า/หลัง (เฉพาะด้านที่หันเข้าหากล้อง)
  void _drawTag(
    Canvas canvas,
    _Cam cam, {
    required double scale,
    bool withRing = true,
  }) {
    final outline = _outline;
    final n = outline.length;
    final d = 12.0 * scale;
    final b = 5.4 * scale;
    final zb = d - b;
    const k = 0.85;
    const bevelSteps = 5;

    var area = 0.0;
    for (var i = 0; i < n; i++) {
      final p = outline[i];
      final q = outline[(i + 1) % n];
      area += p.dx * q.dy - q.dx * p.dy;
    }
    final clockwise = area > 0;

    final faces = <_Face>[];

    // เพิ่มส่วนของห่วงโลหะ 3 มิติ (Torus) เข้าไปในรายการเพื่อเรียงลำดับความลึกร่วมกับตัวเรือน
    if (withRing) {
      _collectRingFaces(faces, cam, scale);
    }

    void addFace(List<_V3> verts, _V3 normal) {
      final rn = cam.rotate(normal);
      if (rn.z <= 0.02) return;
      var zSum = 0.0;
      final pts = <Offset>[];
      for (final v in verts) {
        zSum += cam.rotate(v).z;
        pts.add(cam.project(v));
      }
      faces.add(
        _Face(pts, zSum / verts.length, _shade(tagColor, _intensity(rn))),
      );
    }

    // คำนวณ normal เฉลี่ยตามจุดยอดเพื่อไล่เฉดขอบโค้งได้เนียนกว่าขอบเหลี่ยม
    final edgeNormals = <Offset>[];
    for (var i = 0; i < n; i++) {
      final p = outline[i];
      final q = outline[(i + 1) % n];
      final e = q - p;
      final nx = clockwise ? e.dy : -e.dy;
      final ny = clockwise ? -e.dx : e.dx;
      final len = math.sqrt(nx * nx + ny * ny);
      edgeNormals.add(len == 0 ? Offset.zero : Offset(nx / len, ny / len));
    }

    for (var i = 0; i < n; i++) {
      final j = (i + 1) % n;
      final p = outline[i] * scale;
      final q = outline[j] * scale;
      final en = edgeNormals[i];
      if (en == Offset.zero) continue;
      final nx = en.dx;
      final ny = en.dy;

      // ผนังข้างตรงกลาง
      addFace(
        [_V3(p.dx, p.dy, zb), _V3(q.dx, q.dy, zb), _V3(q.dx, q.dy, -zb), _V3(p.dx, p.dy, -zb)],
        _V3(nx, ny, 0),
      );

      // ขอบโค้งมนหน้า-หลังแบบหลายขั้น (Quarter-circle Fillet)
      for (var s = 0; s < bevelSteps; s++) {
        final t0 = (s / bevelSteps) * (math.pi / 2);
        final t1 = ((s + 1) / bevelSteps) * (math.pi / 2);
        final tm = (t0 + t1) / 2;

        final s0 = k + (1 - k) * math.cos(t0);
        final s1 = k + (1 - k) * math.cos(t1);
        final z0 = zb + b * math.sin(t0);
        final z1 = zb + b * math.sin(t1);

        final cosM = math.cos(tm);
        final sinM = math.sin(tm);

        // ขอบมนด้านหน้า
        addFace(
          [
            _V3(p.dx * s0, p.dy * s0, z0),
            _V3(q.dx * s0, q.dy * s0, z0),
            _V3(q.dx * s1, q.dy * s1, z1),
            _V3(p.dx * s1, p.dy * s1, z1),
          ],
          _V3(nx * cosM, ny * cosM, sinM),
        );

        // ขอบมนด้านหลัง
        addFace(
          [
            _V3(p.dx * s0, p.dy * s0, -z0),
            _V3(q.dx * s0, q.dy * s0, -z0),
            _V3(q.dx * s1, q.dy * s1, -z1),
            _V3(p.dx * s1, p.dy * s1, -z1),
          ],
          _V3(nx * cosM, ny * cosM, -sinM),
        );
      }
    }

    faces.sort((a, b) => a.depth.compareTo(b.depth));
    for (final f in faces) {
      if (f.isStroke) {
        canvas.drawLine(
          f.points[0],
          f.points[1],
          Paint()
            ..color = f.color
            ..strokeWidth = f.strokeWidth
            ..strokeCap = StrokeCap.round,
        );
      } else {
        final path = Path()..addPolygon(f.points, true);
        canvas.drawPath(path, Paint()..color = f.color);
        // เส้นอุดรอยต่อบาง 0.3px เฉพาะกันช่องว่าง anti-aliasing โดยไม่เกิดรอยเส้นชัด
        canvas.drawPath(
          path,
          Paint()
            ..color = f.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.35,
        );
      }
    }

    final frontVisible = cam.rotate(const _V3(0, 0, 1)).z > 0.02;
    final backVisible = cam.rotate(const _V3(0, 0, -1)).z > 0.02;

    List<Offset> capPoints(double z) => [
      for (final o in outline) cam.project(_V3(o.dx * scale * k, o.dy * scale * k, z)),
    ];

    if (frontVisible) {
      final pts = capPoints(d);
      _fillCap(canvas, pts, cam.rotate(const _V3(0, 0, 1)));
      _drawFrontPlate(canvas, cam, scale, d);
    } else if (backVisible) {
      final pts = capPoints(-d);
      _fillCap(canvas, pts, cam.rotate(const _V3(0, 0, -1)));
      _drawBackPlate(canvas, cam, scale, d);
    }
  }

  void _fillCap(Canvas canvas, List<Offset> pts, _V3 normal) {
    final path = Path()..addPolygon(pts, true);
    final rect = path.getBounds();
    final i = _intensity(normal);
    final mid = _shade(tagColor, i);
    final light = _shade(tagColor, (i + 0.08).clamp(0.0, 1.0));
    final dark = _shade(tagColor, (i - 0.08).clamp(0.0, 1.0));
    canvas.drawPath(
      path,
      Paint()
        ..shader = ui.Gradient.linear(
          rect.topLeft,
          rect.bottomRight,
          [light, mid, dark],
          const [0.0, 0.5, 1.0],
        ),
    );
  }

  /// เพิ่มส่วนของห่วงโลหะแบบ 3D Torus ที่โค้งกลมมนมันวาวเหมือนโลหะจริง
  void _collectRingFaces(List<_Face> faces, _Cam cam, double scale) {
    final cy = -0.35 * _bodyH * scale;
    final bigR = 5.6 * scale;
    final tubeR = 1.45 * scale;
    const uSegs = 28;
    const vSegs = 8;

    _V3 torusPoint(double u, double v) {
      final cu = math.cos(u);
      final su = math.sin(u);
      final cv = math.cos(v);
      final sv = math.sin(v);
      final rr = bigR + tubeR * cv;
      return _V3(rr * cu, cy + rr * su, tubeR * sv);
    }

    _V3 torusNormal(double u, double v) {
      final cu = math.cos(u);
      final su = math.sin(u);
      final cv = math.cos(v);
      final sv = math.sin(v);
      return _V3(cv * cu, cv * su, sv);
    }

    for (var i = 0; i < uSegs; i++) {
      final u0 = i / uSegs * math.pi * 2;
      final u1 = (i + 1) / uSegs * math.pi * 2;
      final um = (u0 + u1) / 2;
      for (var j = 0; j < vSegs; j++) {
        final v0 = j / vSegs * math.pi * 2;
        final v1 = (j + 1) / vSegs * math.pi * 2;
        final vm = (v0 + v1) / 2;

        final rn = cam.rotate(torusNormal(um, vm));
        if (rn.z <= 0.0) continue;

        final p00 = torusPoint(u0, v0);
        final p10 = torusPoint(u1, v0);
        final p11 = torusPoint(u1, v1);
        final p01 = torusPoint(u0, v1);

        final zSum = cam.rotate(p00).z +
            cam.rotate(p10).z +
            cam.rotate(p11).z +
            cam.rotate(p01).z;

        final light = _intensity(rn);
        final metalBase = Color.lerp(
          const Color(0xFF4B5552),
          const Color(0xFFB4C0BC),
          light,
        )!;
        final metalColor = light > 0.72
            ? Color.lerp(metalBase, const Color(0xFFF6FAF9), (light - 0.72) / 0.28)!
            : metalBase;

        faces.add(
          _Face(
            [cam.project(p00), cam.project(p10), cam.project(p11), cam.project(p01)],
            zSum / 4,
            metalColor,
          ),
        );
      }
    }
  }

  Color get _inkColor {
    if (tagColor.computeLuminance() > 0.7) return const Color(0xFF8A7A6A);
    return tagColor;
  }

  /// แผ่นหน้าสีครีม + ลายหน้าแมว (จัดกึ่งกลางแท็กและหนวดพอดีในวงกลมตรงเว็บจริง)
  void _drawFrontPlate(Canvas canvas, _Cam cam, double scale, double d) {
    final r = 0.275 * _bodyW * scale;
    final cy = 0.05 * _bodyH * scale;
    final z = d + 0.4 * scale;

    Offset pt(double ux, double uy) =>
        cam.project(_V3(ux * r, cy + uy * r, z));

    final plate = Path()
      ..addPolygon([
        for (var i = 0; i < 48; i++)
          pt(math.cos(i / 48 * math.pi * 2), math.sin(i / 48 * math.pi * 2)),
      ], true);
    canvas.drawPath(plate, Paint()..color = const Color(0xFFFFFCF4));

    final ink = Paint()
      ..color = _inkColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 1.65 * scale;

    for (final dir in [-1.0, 1.0]) {
      final eye = Path();
      for (var i = 0; i <= 8; i++) {
        final t = i / 8 * 2 - 1;
        final p = pt(dir * 0.34 + t * 0.13, -0.08 - 0.10 * (1 - t * t));
        if (i == 0) {
          eye.moveTo(p.dx, p.dy);
        } else {
          eye.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(eye, ink);

      for (var w = 0; w < 2; w++) {
        final y0 = 0.10 + w * 0.14;
        final a = pt(dir * 0.46, y0);
        final bb = pt(dir * 0.74, y0 + (w == 0 ? -0.05 : 0.07));
        canvas.drawLine(a, bb, ink);
      }
    }

    final nose = pt(0, 0.10);
    canvas.drawCircle(
      nose,
      1.7 * scale,
      Paint()..color = _inkColor,
    );
    final mouth = Path()
      ..moveTo(pt(-0.08, 0.24).dx, pt(-0.08, 0.24).dy)
      ..lineTo(pt(0, 0.18).dx, pt(0, 0.18).dy)
      ..lineTo(pt(0.08, 0.24).dx, pt(0.08, 0.24).dy);
    canvas.drawPath(mouth, ink..strokeWidth = 1.25 * scale);
  }

  /// ด้านหลัง: ฝาแบตเตอรี่สีเดียวกับตัวเรือน ร่องวงกลม 2 ชั้น จุดหมุด 2 จุด ร่องไขเหรียญด้านล่าง และ แมว.live Tag
  void _drawBackPlate(Canvas canvas, _Cam cam, double scale, double d) {
    final r = 0.28 * _bodyW * scale;
    final cy = 0.05 * _bodyH * scale;
    final z = -(d + 0.4 * scale);

    Offset pt(double ux, double uy, [double rr = 1.0]) =>
        cam.project(_V3(-ux * r * rr, cy + uy * r * rr, z));

    List<Offset> circle(double rr) => [
      for (var i = 0; i < 48; i++)
        pt(math.cos(i / 48 * math.pi * 2), math.sin(i / 48 * math.pi * 2), rr),
    ];

    final seamColor = Color.lerp(tagColor, Colors.black, 0.22)!;
    final isLightBody = tagColor.computeLuminance() > 0.65;
    final labelColor = isLightBody
        ? AppColors.tagTextMuted.withValues(alpha: 0.78)
        : Colors.white.withValues(alpha: 0.85);

    canvas.drawPath(
      Path()..addPolygon(circle(1.0), true),
      Paint()
        ..color = seamColor.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4 * scale,
    );
    canvas.drawPath(
      Path()..addPolygon(circle(0.84), true),
      Paint()
        ..color = seamColor.withValues(alpha: 0.40)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 * scale,
    );

    // หมุดเล็กซ้าย-ขวา
    for (final dir in [-1.0, 1.0]) {
      canvas.drawCircle(
        pt(dir * 0.60, 0.08),
        1.5 * scale,
        Paint()..color = seamColor.withValues(alpha: 0.75),
      );
    }

    // ร่องไขเหรียญด้านล่าง
    canvas.drawLine(
      pt(-0.18, 0.58),
      pt(0.18, 0.58),
      Paint()
        ..color = seamColor.withValues(alpha: 0.78)
        ..strokeWidth = 2.0 * scale
        ..strokeCap = StrokeCap.round,
    );

    final p0 = pt(0, -0.14);
    final pL = pt(-0.35, -0.14);
    final pR = pt(0.35, -0.14);
    final pD = pt(0, 0.20);

    final dx = pR.dx - pL.dx;
    final dy = pR.dy - pL.dy;
    final angle = math.atan2(dy, dx);
    final distX = Offset(dx, dy).distance;

    final dyY = pD.dy - p0.dy;
    final dxY = pD.dx - p0.dx;
    final distY = Offset(dxY, dyY).distance;

    final sNominalX = 0.70 * r * (cam.focal / (cam.focal + d));
    final sNominalY = 0.34 * r * (cam.focal / (cam.focal + d));
    final scaleX = (distX / sNominalX).clamp(0.05, 1.2);
    final scaleY = (distY / sNominalY).clamp(0.05, 1.2);

    if (scaleX > 0.12) {
      final tp = TextPainter(
        text: TextSpan(
          text: 'แมว.live Tag',
          style: TextStyle(
            fontSize: 3.8 * scale,
            fontWeight: FontWeight.w500,
            color: labelColor,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();
      canvas.save();
      canvas.translate(p0.dx, p0.dy);
      canvas.rotate(angle);
      canvas.scale(scaleX, scaleY);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _Tag3dPainter oldDelegate) {
    return oldDelegate.mode != mode ||
        oldDelegate.tagColor != tagColor ||
        oldDelegate.collarColor != collarColor ||
        oldDelegate.yaw != yaw ||
        oldDelegate.pitch != pitch;
  }
}

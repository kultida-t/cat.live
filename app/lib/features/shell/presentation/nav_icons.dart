import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum NavIconName { home, feed, nearby, ai, help, myCat }

const _off = (from: '#CDBFB0', to: '#9C8A79');
const _on = (from: '#9A7760', to: '#4A3428');
const _hl = 'rgba(255,255,255,0.45)';

String _shapes(NavIconName name, String fill) {
  switch (name) {
    case NavIconName.home:
      return '<path d="M4 15.2 16 4.5l12 10.7V27a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2Z" fill="$fill"/>'
          '<path d="M7 14.5 16 6.6l6 5.3" fill="none" stroke="$_hl" stroke-width="1.8" stroke-linecap="round"/>'
          '<rect x="13" y="19" width="6" height="10" rx="1.5" fill="#fff" opacity="0.75"/>';
    case NavIconName.feed:
      return [
        [4, 4],
        [17, 4],
        [4, 17],
        [17, 17],
      ].map((p) {
        final x = p[0], y = p[1];
        return '<rect x="$x" y="$y" width="11" height="11" rx="3.2" fill="$fill"/>'
            '<rect x="${x + 2}" y="${y + 1.6}" width="5" height="2.2" rx="1.1" fill="$_hl"/>';
      }).join();
    case NavIconName.nearby:
      return '<path d="M16 3c5.8 0 10 4.3 10 9.8C26 20 16 29 16 29S6 20 6 12.8C6 7.3 10.2 3 16 3Z" fill="$fill"/>'
          '<circle cx="16" cy="12.5" r="4" fill="#fff" opacity="0.8"/>'
          '<path d="M9.5 9.5a7 7 0 0 1 4-4" fill="none" stroke="$_hl" stroke-width="1.8" stroke-linecap="round"/>';
    case NavIconName.ai:
      // วาดเฉพาะฟองแชท ดาว 2 ดวงวาดแยกใน _AnimatedAiStars เพื่อกระพริบ+หมุนสลับจังหวะได้ตรงเว็บ
      return '<path d="M16 3.5c7 0 12.5 4.9 12.5 11.1S23 25.7 16 25.7c-1.4 0-2.7-.2-4-.5L5.2 28.5l1.7-5.4C4.8 21.1 3.5 18 3.5 14.6 3.5 8.4 9 3.5 16 3.5Z" fill="$fill"/>'
          '<path d="M8 9.8c1.6-2.5 4.4-4 7.6-4.2" fill="none" stroke="$_hl" stroke-width="1.8" stroke-linecap="round"/>';
    case NavIconName.help:
      return '<path d="M16 28S3.5 20.6 3.5 11.9A6.6 6.6 0 0 1 16 8.4a6.6 6.6 0 0 1 12.5 3.5C28.5 20.6 16 28 16 28Z" fill="$fill"/>'
          '<ellipse cx="9.8" cy="11" rx="2.6" ry="1.7" transform="rotate(-35 9.8 11)" fill="$_hl"/>';
    case NavIconName.myCat:
      // วาดเฉพาะหัวแมวกับจมูก ดวงตา (ตาขาว+ตาดำ+กระพริบ+กลอกตา) วาดใน _CatEyesPainter
      return '<path d="M5 5.5 11 10h10l6-4.5V18c0 6.1-4.9 10.5-11 10.5S5 24.1 5 18Z" fill="$fill"/>'
          '<path d="M8 9.5 10.6 11.6M24 9.5l-2.6 2.1" fill="none" stroke="$_hl" stroke-width="1.6" stroke-linecap="round"/>'
          '<path d="M14.8 21.6h2.4L16 22.9Z" fill="#F4A3B4"/>';
  }
}

/// ไอคอนแท็บล่างแบบไล่สี — ใช้ SVG และแอนิเมชันชุดเดียวกับเว็บ prototype (www.แมว.live)
class NavIcon extends StatelessWidget {
  const NavIcon({
    super.key,
    required this.name,
    required this.active,
    this.size = 30,
  });

  final NavIconName name;
  final bool active;
  final double size;

  @override
  Widget build(BuildContext context) {
    final g = active ? _on : _off;
    final svg =
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">'
        '<defs><linearGradient id="g" x1="0" y1="0" x2="0" y2="1">'
        '<stop offset="0" stop-color="${g.from}"/><stop offset="1" stop-color="${g.to}"/>'
        '</linearGradient></defs>${_shapes(name, 'url(#g)')}</svg>';

    final baseIcon = SvgPicture.string(svg, width: size, height: size);

    if (name == NavIconName.ai) {
      return SizedBox(
        width: size,
        height: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            baseIcon,
            _AnimatedAiStars(size: size, active: active),
          ],
        ),
      );
    }

    if (name == NavIconName.help && active) {
      return _AnimatedHelpHeart(child: baseIcon);
    }

    if (name == NavIconName.myCat) {
      return SizedBox(
        width: size,
        height: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            baseIcon,
            _AnimatedCatEyes(size: size),
          ],
        ),
      );
    }

    return baseIcon;
  }
}

/// ดาว 4 แฉก 2 ดวงในไอคอน Cat AI — กระพริบและหมุนสลับจังหวะเมื่อ Active (nav-twinkle 1.8s, delay 0.7s)
class _AnimatedAiStars extends StatefulWidget {
  const _AnimatedAiStars({required this.size, required this.active});

  final double size;
  final bool active;

  @override
  State<_AnimatedAiStars> createState() => _AnimatedAiStarsState();
}

class _AnimatedAiStarsState extends State<_AnimatedAiStars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant _AnimatedAiStars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      _syncAnimation();
    }
  }

  void _syncAnimation() {
    if (!widget.active || MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) => CustomPaint(
        size: Size.square(widget.size),
        painter: _AiStarsPainter(
          t: _controller.value,
          active: widget.active,
        ),
      ),
    );
  }
}

class _AiStarsPainter extends CustomPainter {
  const _AiStarsPainter({required this.t, required this.active});

  final double t;
  final bool active;

  // คำนวณค่า nav-twinkle: 0%/100% (scale 1, rot 0, op 1) -> 50% (scale 0.7, rot 20°, op 0.75)
  ({double scale, double angleRad, double opacity}) _twinkleAt(double phase) {
    if (!active) return (scale: 1.0, angleRad: 0.0, opacity: 1.0);
    final p = Curves.easeInOut.transform(
      phase <= 0.5 ? phase * 2 : (1.0 - phase) * 2,
    );
    return (
      scale: 1.0 - 0.3 * p,
      angleRad: (20.0 * p) * math.pi / 180.0,
      opacity: 1.0 - 0.25 * p,
    );
  }

  void _drawStar(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required ({double scale, double angleRad, double opacity}) state,
    required Color color,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(state.angleRad);
    canvas.scale(state.scale);

    final r = radius;
    final c = r * 0.16;
    final path = Path()
      ..moveTo(0, -r)
      ..quadraticBezierTo(c, -c, r, 0)
      ..quadraticBezierTo(c, c, 0, r)
      ..quadraticBezierTo(-c, c, -r, 0)
      ..quadraticBezierTo(-c, -c, 0, -r)
      ..close();

    final paint = Paint()
      ..color = color.withValues(alpha: state.opacity);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 32.0;
    final starColor = active ? const Color(0xFFFFE7A3) : Colors.white;

    // ดาวดวงใหญ่ (ศูนย์กลาง 14.6, 15.0, รัศมี 6.6)
    _drawStar(
      canvas,
      center: Offset(14.6 * s, 15.0 * s),
      radius: 6.6 * s,
      state: _twinkleAt(t),
      color: starColor,
    );

    // ดาวดวงเล็ก (ศูนย์กลาง 21.4, 10.2, รัศมี 2.6, delay 0.7s / 1.8s)
    final t2 = (t + 0.7 / 1.8) % 1.0;
    _drawStar(
      canvas,
      center: Offset(21.4 * s, 10.2 * s),
      radius: 2.6 * s,
      state: _twinkleAt(t2),
      color: starColor,
    );
  }

  @override
  bool shouldRepaint(_AiStarsPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.active != active;
}

/// แอนิเมชันลูกตาแมว: กระพริบตา (nav-blink 4.5s) + กลอกตาไปมา (nav-look 6s)
class _AnimatedCatEyes extends StatefulWidget {
  const _AnimatedCatEyes({required this.size});

  final double size;

  @override
  State<_AnimatedCatEyes> createState() => _AnimatedCatEyesState();
}

class _AnimatedCatEyesState extends State<_AnimatedCatEyes>
    with TickerProviderStateMixin {
  late final AnimationController _lookCtrl;
  late final AnimationController _blinkCtrl;
  late final Animation<Offset> _offset;
  late final Animation<double> _scaleY;

  @override
  void initState() {
    super.initState();
    _lookCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    );
    _offset = TweenSequence<Offset>([
      TweenSequenceItem(tween: ConstantTween(Offset.zero), weight: 30),
      TweenSequenceItem(
        tween: Tween(
          begin: Offset.zero,
          end: const Offset(0.9, -0.3),
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 8,
      ),
      TweenSequenceItem(
        tween: ConstantTween(const Offset(0.9, -0.3)),
        weight: 17,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: const Offset(0.9, -0.3),
          end: const Offset(-0.9, 0.2),
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 8,
      ),
      TweenSequenceItem(
        tween: ConstantTween(const Offset(-0.9, 0.2)),
        weight: 17,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: const Offset(-0.9, 0.2),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 8,
      ),
      TweenSequenceItem(tween: ConstantTween(Offset.zero), weight: 12),
    ]).animate(_lookCtrl);

    _blinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    );
    _scaleY = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 92),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.1,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 3,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.1,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 5,
      ),
    ]).animate(_blinkCtrl);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _lookCtrl.stop();
      _lookCtrl.value = 0;
      _blinkCtrl.stop();
      _blinkCtrl.value = 0;
    } else {
      if (!_lookCtrl.isAnimating) _lookCtrl.repeat();
      if (!_blinkCtrl.isAnimating) _blinkCtrl.repeat();
    }
  }

  @override
  void dispose() {
    _lookCtrl.dispose();
    _blinkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_lookCtrl, _blinkCtrl]),
      builder: (_, _) => CustomPaint(
        size: Size.square(widget.size),
        painter: _CatEyesPainter(
          offset: _offset.value,
          scaleY: _scaleY.value,
        ),
      ),
    );
  }
}

class _CatEyesPainter extends CustomPainter {
  const _CatEyesPainter({required this.offset, required this.scaleY});

  final Offset offset;
  final double scaleY;

  static final _whitePaint = Paint()..color = Colors.white;
  static final _pupilPaint = Paint()..color = const Color(0xFF3D2C22);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 32.0;
    final eyeCenterY = 17.0 * s;

    canvas.save();
    canvas.translate(0, eyeCenterY);
    canvas.scale(1.0, scaleY);
    canvas.translate(0, -eyeCenterY);

    for (final cx in const [11.6, 20.4]) {
      // ตาขาว
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx * s, 17.0 * s),
          width: 5.2 * s,
          height: 6.0 * s,
        ),
        _whitePaint,
      );
      // ตาดำ
      canvas.drawCircle(
        Offset((cx + offset.dx) * s, (17.2 + offset.dy) * s),
        1.5 * s,
        _pupilPaint,
      );
      // แสงสะท้อนในตา
      canvas.drawCircle(
        Offset((cx + 0.5 + offset.dx) * s, (16.6 + offset.dy) * s),
        0.5 * s,
        _whitePaint,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_CatEyesPainter oldDelegate) =>
      oldDelegate.offset != offset || oldDelegate.scaleY != scaleY;
}

/// แอนิเมชันหัวใจเต้นเป็นจังหวะชีพจรบนแท็บ "ช่วยเหลือ" เมื่อ Active (nav-beat 2.4s)
class _AnimatedHelpHeart extends StatefulWidget {
  const _AnimatedHelpHeart({required this.child});

  final Widget child;

  @override
  State<_AnimatedHelpHeart> createState() => _AnimatedHelpHeartState();
}

class _AnimatedHelpHeartState extends State<_AnimatedHelpHeart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 70),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.12,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 8,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.12,
          end: 0.97,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 8,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.97,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 14,
      ),
    ]).animate(_controller);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      alignment: const Alignment(0, 0.06), // ประมาณ (16, 17) บน viewBox 32x32
      scale: _scale,
      child: widget.child,
    );
  }
}

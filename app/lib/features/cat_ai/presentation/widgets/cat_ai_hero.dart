import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import 'cat_ai_l10n.dart';

/// ปุ่มไมค์ใหญ่กลางหน้า พร้อมดาวกระพริบรอบ ๆ และข้อความ "แตะเพื่อเริ่มพูด"
class CatAiHero extends StatefulWidget {
  const CatAiHero({super.key, required this.isEn, required this.onTap});

  final bool isEn;
  final VoidCallback onTap;

  @override
  State<CatAiHero> createState() => _CatAiHeroState();
}

class _CatAiHeroState extends State<CatAiHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _twinkle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _twinkle.dispose();
    super.dispose();
  }

  Widget _sparkle({
    required double left,
    required double top,
    required double size,
    required double delay,
  }) {
    return Positioned(
      left: left,
      top: top,
      child: AnimatedBuilder(
        animation: _twinkle,
        builder: (_, child) {
          final t = (_twinkle.value + delay) % 1.0;
          final pulse = 1 - (2 * t - 1).abs();
          return Opacity(
            opacity: 0.45 + 0.55 * pulse,
            child: Transform.scale(scale: 0.8 + 0.3 * pulse, child: child),
          );
        },
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(painter: const _SparklePainter()),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final label = CatAiL10n.tapToSpeak(widget.isEn);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              _sparkle(left: 136, top: 16, size: 28, delay: 0),
              _sparkle(left: 167, top: 57, size: 14, delay: 0.33),
              _sparkle(left: 25, top: 141, size: 18, delay: 0.66),
              const _PingHalo(),
              Container(
                width: 160,
                height: 160,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [AppColors.catAiHaloGlow, Color(0x003E8F8A)],
                    stops: [0.45, 0.7],
                  ),
                ),
              ),
              Container(
                width: 132,
                height: 132,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.7),
                  boxShadow: const [
                    BoxShadow(color: AppColors.catAiMicRing, spreadRadius: 1),
                  ],
                ),
              ),
              Semantics(
                button: true,
                label: label,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onTap,
                  child: Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        center: Alignment(-0.3, -0.44),
                        colors: [
                          AppColors.catAiMicLight,
                          AppColors.catAiMicMid,
                          AppColors.catAiMicDark,
                        ],
                        stops: [0, 0.45, 1],
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x662F6F6B),
                          blurRadius: 28,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          top: 12,
                          child: Container(
                            width: 56,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                        ),
                        const Icon(
                          LucideIcons.mic,
                          size: 46,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppColors.text2),
        ),
      ],
    );
  }
}

/// ดาวสี่แฉกแบบไล่สีแนวตั้ง ตรงกับดาวบนเว็บจริง
/// วงแสงที่กระจายออกและจางหายซ้ำ ๆ รอบไมค์ (ตรงกับแอนิเมชัน ping บนเว็บจริง)
class _PingHalo extends StatefulWidget {
  const _PingHalo();

  @override
  State<_PingHalo> createState() => _PingHaloState();
}

class _PingHaloState extends State<_PingHalo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ping = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void dispose() {
    _ping.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ping,
      builder: (_, _) {
        final t = Curves.easeOut.transform(_ping.value);
        return Opacity(
          opacity: 0.6 * (1 - t),
          child: Transform.scale(
            scale: 1 + t,
            child: Container(
              width: 124,
              height: 124,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.catAiStethoscopeBg,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SparklePainter extends CustomPainter {
  const _SparklePainter();

  @override
  void paint(Canvas canvas, Size size) {
    // พิกัดตาม viewBox -1..1 ของดาวบนเว็บ แปลงเป็นขนาดจริงของวิดเจ็ต
    Offset p(double x, double y) =>
        Offset((x + 1) / 2 * size.width, (y + 1) / 2 * size.height);
    // แต่ละคู่คือ (จุดควบคุม, จุดปลาย) ของเส้นโค้งหนึ่งช่วงของแฉก
    const segments = <(Offset, Offset)>[
      (Offset(.16, -.16), Offset(1, 0)),
      (Offset(.16, .16), Offset(0, 1)),
      (Offset(-.16, .16), Offset(-1, 0)),
      (Offset(-.16, -.16), Offset(0, -1)),
    ];
    final path = Path()..moveTo(p(0, -1).dx, p(0, -1).dy);
    for (final (control, end) in segments) {
      final c = p(control.dx, control.dy);
      final e = p(end.dx, end.dy);
      path.cubicTo(c.dx, c.dy, c.dx, c.dy, e.dx, e.dy);
    }
    path.close();
    // เงาฟุ้งเล็กน้อยใต้ดาว ตามค่า drop-shadow บนเว็บ
    canvas.drawPath(
      path.shift(Offset(0, size.height * 0.07)),
      Paint()
        ..color = const Color(0x4D2F6F6B)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.catAiSparkStart, AppColors.catAiSparkEnd],
      ).createShader(Offset.zero & size);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) => false;
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';

enum _QuickKind { feed, ai, help }

class _QuickActionMeta {
  const _QuickActionMeta({
    required this.kind,
    required this.title,
    required this.semantics,
    required this.route,
    required this.bg,
    required this.border,
    required this.ink,
    required this.iconColor,
  });

  final _QuickKind kind;
  final String title;
  final String semantics;
  final String route;
  final Color bg;
  final Color border;
  final Color ink;
  final Color iconColor;
}

const _actions = [
  _QuickActionMeta(
    kind: _QuickKind.feed,
    title: 'ฟีดแมว',
    semantics: 'ฟีดแมว ดูโพสต์และเรื่องราวน่ารักของแมวในชุมชน',
    route: '/community',
    bg: AppColors.quickFeedBg,
    border: AppColors.quickFeedBorder,
    ink: AppColors.quickFeedInk,
    iconColor: AppColors.quickFeedIcon,
  ),
  _QuickActionMeta(
    kind: _QuickKind.ai,
    title: 'ถาม Cat AI',
    semantics: 'ถาม Cat AI ปรึกษาเรื่องแมวได้ทุกเวลา',
    route: '/cat-ai',
    bg: AppColors.quickAiBg,
    border: AppColors.quickAiBorder,
    ink: AppColors.quickAiInk,
    iconColor: AppColors.quickAiIcon,
  ),
  _QuickActionMeta(
    kind: _QuickKind.help,
    title: 'ขอความ\nช่วยเหลือ',
    semantics: 'ขอความช่วยเหลือ แจ้งแมวหาย หรือพบแมวต้องการความช่วยเหลือ',
    route: '/help',
    bg: AppColors.quickHelpBg,
    border: AppColors.quickHelpBorder,
    ink: AppColors.quickHelpInk,
    iconColor: AppColors.quickHelpIcon,
  ),
];

/// การ์ดทางลัด 3 ใบใต้แบนเนอร์ (ฟีดแมว / ถาม Cat AI / ขอความช่วยเหลือ)
class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Row(
        children: [
          for (var i = 0; i < _actions.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(
              child: _QuickCard(
                meta: _actions[i],
                onTap: () => context.go(_actions[i].route),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({required this.meta, required this.onTap});

  final _QuickActionMeta meta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: meta.semantics,
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: 1 / 1.05,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: meta.bg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: meta.border, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F4A3428),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(22),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 10,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(46, 46),
                      painter: _QuickIconPainter(
                        kind: meta.kind,
                        color: meta.iconColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      meta.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        color: meta.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// วาดไอคอนทั้ง 3 อันจาก path เดียวกับ SVG บนหน้าเว็บจริง (viewBox 48x48)
class _QuickIconPainter extends CustomPainter {
  const _QuickIconPainter({required this.kind, required this.color});

  final _QuickKind kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 48, size.height / 48);

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final whiteFill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    switch (kind) {
      case _QuickKind.feed:
        // หน้าแมว: หูแหลมซ้ายขวา + แก้มมน
        final cat = Path()
          ..moveTo(24, 13)
          ..cubicTo(27.5, 13, 30.4, 13.8, 32.6, 15)
          ..lineTo(38, 9)
          ..lineTo(38, 22)
          ..cubicTo(39.3, 24, 40, 26.2, 40, 28.6)
          ..cubicTo(40, 36.4, 32.8, 41, 24, 41)
          ..cubicTo(15.2, 41, 8, 36.4, 8, 28.6)
          ..cubicTo(8, 26.2, 8.7, 24, 10, 22)
          ..lineTo(10, 9)
          ..lineTo(15.4, 15)
          ..cubicTo(17.6, 13.8, 20.5, 13, 24, 13)
          ..close();
        canvas.drawPath(cat, fill);
        canvas.drawCircle(const Offset(18, 27), 2, whiteFill);
        canvas.drawCircle(const Offset(30, 27), 2, whiteFill);
        final nose = Path()
          ..moveTo(22.5, 32)
          ..lineTo(25.5, 32)
          ..lineTo(24, 33.6)
          ..close();
        canvas.drawPath(nose, whiteFill);

      case _QuickKind.ai:
        // บับเบิลแชทพร้อมหางแหลม + จุดไข่ปลา 3 จุด
        final bubble = Path()
          ..moveTo(24, 8)
          ..cubicTo(33.4, 8, 41, 14.3, 41, 22.2)
          ..cubicTo(41, 30.1, 33.4, 36.4, 24, 36.4)
          ..cubicTo(22.3, 36.4, 20.6, 36.2, 19, 35.8)
          ..lineTo(10, 41)
          ..lineTo(12.4, 32.9)
          ..cubicTo(9, 30.3, 7, 26.5, 7, 22.2)
          ..cubicTo(7, 14.3, 14.6, 8, 24, 8)
          ..close();
        canvas.drawPath(bubble, fill);
        canvas.drawCircle(const Offset(17, 22.5), 2.2, whiteFill);
        canvas.drawCircle(const Offset(24, 22.5), 2.2, whiteFill);
        canvas.drawCircle(const Offset(31, 22.5), 2.2, whiteFill);

      case _QuickKind.help:
        // หมุด Location Pin + กากบาทพยาบาลหัวมน
        final pin = Path()
          ..moveTo(24, 44)
          ..cubicTo(24, 44, 9, 30.5, 9, 19.5)
          ..arcToPoint(
            const Offset(39, 19.5),
            radius: const Radius.elliptical(15, 15),
          )
          ..cubicTo(39, 30.5, 24, 44, 24, 44)
          ..close();
        canvas.drawPath(pin, fill);
        final cross = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.5
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(const Offset(24, 12.5), const Offset(24, 25.5), cross);
        canvas.drawLine(const Offset(17.5, 19), const Offset(30.5, 19), cross);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_QuickIconPainter old) =>
      old.kind != kind || old.color != color;
}

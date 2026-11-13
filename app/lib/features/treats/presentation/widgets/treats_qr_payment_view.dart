import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../l10n/treats_l10n.dart';

/// ขั้นตอนที่ 2: หน้าชำระเงินด้วย QR พร้อมเวลานับถอยหลัง 15 นาที
class TreatsQrPaymentView extends StatefulWidget {
  const TreatsQrPaymentView({
    super.key,
    required this.totalPrice,
    required this.totalCount,
    required this.isEn,
    required this.onBack,
    required this.onPaid,
  });

  final int totalPrice;
  final int totalCount;
  final bool isEn;
  final VoidCallback onBack;
  final VoidCallback onPaid;

  @override
  State<TreatsQrPaymentView> createState() => _TreatsQrPaymentViewState();
}

class _TreatsQrPaymentViewState extends State<TreatsQrPaymentView> {
  static const _initialSeconds = 900;
  int _secondsLeft = _initialSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft -= 1);
      } else {
        _timer?.cancel();
      }
    });
  }

  void _regenerate() {
    setState(() => _secondsLeft = _initialSeconds);
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mm = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final ss = (_secondsLeft % 60).toString().padLeft(2, '0');
    final expired = _secondsLeft == 0;
    final urgent = _secondsLeft < 60;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.4, 0.8, 1.0],
          colors: [
            AppColors.page,
            AppColors.page,
            AppColors.btn,
            AppColors.treatsSelectedBg,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 4),
              child: SizedBox(
                height: 44,
                child: Row(
                  children: [
                    Semantics(
                      button: true,
                      label: TreatsL10n.backLabel(widget.isEn),
                      excludeSemantics: true,
                      child: InkWell(
                        onTap: widget.onBack,
                        borderRadius: BorderRadius.circular(14),
                        child: const SizedBox(
                          width: 44,
                          height: 44,
                          child: Icon(
                            LucideIcons.chevronLeft,
                            size: 24,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      TreatsL10n.paymentTitle(widget.isEn),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.treatsWarmRule),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.sheetBarrier,
                                blurRadius: 20,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                TreatsL10n.paymentAmountLabel(
                                  widget.isEn,
                                  widget.totalCount,
                                ),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.text2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '฿${_formatInt(widget.totalPrice)}',
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  height: 1.05,
                                  color: AppColors.text,
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: _DashedRule(),
                              ),
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  AnimatedOpacity(
                                    duration: const Duration(milliseconds: 250),
                                    opacity: expired ? 0.3 : 1.0,
                                    child: ImageFiltered(
                                      imageFilter: ImageFilter.blur(
                                        sigmaX: expired ? 3 : 0,
                                        sigmaY: expired ? 3 : 0,
                                      ),
                                      child: const SizedBox(
                                        width: 210,
                                        height: 210,
                                        child: CustomPaint(
                                          painter: _MockQrPainter(),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (expired)
                                    ElevatedButton(
                                      onPressed: _regenerate,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.card,
                                        foregroundColor: AppColors.treatsInk,
                                        minimumSize: const Size(0, 44),
                                        shape: const StadiumBorder(),
                                        elevation: 4,
                                      ),
                                      child: Text(
                                        TreatsL10n.regenerateQr(widget.isEn),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text.rich(
                                TextSpan(
                                  text:
                                      '${TreatsL10n.payeeLabel(widget.isEn)} ',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.text2,
                                  ),
                                  children: const [
                                    TextSpan(
                                      text: 'แมว.live',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.text,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: urgent
                                      ? AppColors.treatsQrErrorBg
                                      : AppColors.btn,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      LucideIcons.clock3,
                                      size: 14,
                                      color: urgent
                                          ? AppColors.danger
                                          : AppColors.treatsInk,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      expired
                                          ? TreatsL10n.qrExpired(widget.isEn)
                                          : TreatsL10n.expiresIn(
                                              widget.isEn,
                                              mm,
                                              ss,
                                            ),
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: urgent
                                            ? AppColors.danger
                                            : AppColors.treatsInk,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          TreatsL10n.scanHint(widget.isEn),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: AppColors.text2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: expired ? null : widget.onPaid,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.btn,
                    foregroundColor: AppColors.text,
                    disabledBackgroundColor: AppColors.btn.withValues(
                      alpha: 0.45,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                      side: const BorderSide(
                        color: AppColors.btnBorder,
                        width: 1.5,
                      ),
                    ),
                  ),
                  child: Text(
                    TreatsL10n.paidCta(widget.isEn),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
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

class _DashedRule extends StatelessWidget {
  const _DashedRule();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 1),
      painter: _DashedRulePainter(),
    );
  }
}

class _DashedRulePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.treatsWarmRule
      ..strokeWidth = 1;
    const dash = 5.0;
    const gap = 4.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dash, 0), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MockQrPainter extends CustomPainter {
  const _MockQrPainter();

  static int _finderDot(int x, int y) {
    for (final origin in const [(0, 0), (18, 0), (0, 18)]) {
      final ox = origin.$1;
      final oy = origin.$2;
      if (x >= ox && x < ox + 7 && y >= oy && y < oy + 7) {
        final dx = x - ox;
        final dy = y - oy;
        final border = dx == 0 || dy == 0 || dx == 6 || dy == 6;
        final center = dx >= 2 && dx <= 4 && dy >= 2 && dy <= 4;
        return (border || center) ? 1 : 0;
      }
    }
    return -1;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(10)),
      Paint()..color = Colors.white,
    );
    final cell = size.width / 29;
    final darkPaint = Paint()..color = AppColors.text;

    for (var y = 0; y < 25; y++) {
      for (var x = 0; x < 25; x++) {
        final f = _finderDot(x, y);
        final inZone =
            (x < 8 && y < 8) || (x > 16 && y < 8) || (x < 8 && y > 16);
        final hash =
            ((0x466f45d * x) ^ (0x127409f * y) ^ (x * y * 0x4f9ffb7)) &
            0xFFFFFFFF;
        if (f == 1 || (f == -1 && !inZone && (hash % 7) < 3)) {
          canvas.drawRect(
            Rect.fromLTWH(
              (x + 2) * cell,
              (y + 2) * cell,
              cell * 1.02,
              cell * 1.02,
            ),
            darkPaint,
          );
        }
      }
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(12 * cell, 12 * cell, 5 * cell, 5 * cell),
        Radius.circular(cell * 1.2),
      ),
      Paint()..color = Colors.white,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(12.7 * cell, 12.7 * cell, 3.6 * cell, 3.6 * cell),
        Radius.circular(cell * 0.9),
      ),
      Paint()..color = AppColors.treatsInk,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

String _formatInt(int value) {
  final s = value.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

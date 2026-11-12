import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/cat_health_data.dart';
import 'health_shared_widgets.dart';

/// แท็บ 6: กราฟน้ำหนัก 6 เดือน แนวโน้ม และปุ่มบันทึกน้ำหนักวันนี้
class HealthWeightTab extends StatelessWidget {
  const HealthWeightTab({
    super.key,
    required this.healthBook,
    required this.latestWeightKg,
    required this.isEn,
    required this.onLogWeight,
  });

  final CatHealthBook healthBook;
  final double latestWeightKg;
  final bool isEn;
  final VoidCallback onLogWeight;

  @override
  Widget build(BuildContext context) {
    final points = healthBook.weightHistory;
    final latestPoint = points.isNotEmpty ? points.last : null;
    final shownKg = latestPoint?.kg ?? latestWeightKg;
    final monthLabel = latestPoint != null
        ? (isEn ? latestPoint.monthEn : latestPoint.monthTh)
        : (isEn ? 'Oct' : 'ต.ค.');
    final deltaText = isEn
        ? healthBook.weightDeltaEn
        : healthBook.weightDeltaTh;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (points.isEmpty)
          HealthEmptyStateCard(
            icon: LucideIcons.scale,
            title: isEn ? 'No weight logs yet' : 'ยังไม่มีบันทึกน้ำหนัก',
            subtitle: isEn
                ? 'Tap "+ Log today\'s weight" below to start tracking monthly growth.'
                : 'แตะ "+ บันทึกน้ำหนักวันนี้" เพื่อเริ่มติดตามกราฟน้ำหนักรายเดือน',
          )
        else ...[
          HealthCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEn
                      ? 'Latest weight · $monthLabel'
                      : 'น้ำหนักล่าสุด · $monthLabel',
                  style: const TextStyle(fontSize: 13, color: AppColors.muted),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      shownKg.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        isEn ? 'kg' : 'กก.',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (deltaText.isNotEmpty)
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: healthBook.weightDropping
                                    ? AppColors.healthDeltaDropBg
                                    : AppColors.healthDeltaGainBg,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    healthBook.weightDropping
                                        ? LucideIcons.trendingDown
                                        : LucideIcons.trendingUp,
                                    size: 14,
                                    color: healthBook.weightDropping
                                        ? AppColors.healthDeltaDropInk
                                        : AppColors.healthDeltaGainInk,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    deltaText,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: healthBook.weightDropping
                                          ? AppColors.healthDeltaDropInk
                                          : AppColors.healthDeltaGainInk,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 158,
                  width: double.infinity,
                  child: _WeightLineChart(points: points, isEn: isEn),
                ),
              ],
            ),
          ),
          if (healthBook.weightDropping) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.healthWeightAlertBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.healthWeightAlertBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(
                      LucideIcons.triangleAlert,
                      size: 17,
                      color: AppColors.healthWeightAlertInk,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      isEn
                          ? 'Weight keeps dropping. Check food portions and see a vet if it continues.'
                          : 'น้ำหนักลดลงต่อเนื่อง แนะนำให้สังเกตปริมาณอาหารและปรึกษาสัตวแพทย์หากยังลดลง',
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: AppColors.healthWeightAlertInk,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
        const SizedBox(height: 14),
        HealthOutlinedActionButton(
          icon: LucideIcons.plus,
          label: isEn ? "Log today's weight" : 'บันทึกน้ำหนักวันนี้',
          onPressed: onLogWeight,
        ),
      ],
    );
  }
}

class _WeightLineChart extends StatelessWidget {
  const _WeightLineChart({required this.points, required this.isEn});

  final List<WeightPoint> points;
  final bool isEn;

  @override
  Widget build(BuildContext context) {
    final minVal = points.map((p) => p.kg).reduce(math.min);
    final maxVal = points.map((p) => p.kg).reduce(math.max);
    final axisMin = ((minVal - 0.35) * 4).floorToDouble() / 4;
    final axisMax = math.max(axisMin + 1.0, ((maxVal + 0.35) * 4).ceilToDouble() / 4);
    final axisMid = (axisMin + axisMax) / 2;

    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              SizedBox(
                width: 36,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _fmtAxis(axisMax),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                    Text(
                      _fmtAxis(axisMid),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                    Text(
                      _fmtAxis(axisMin),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CustomPaint(
                  painter: _WeightChartPainter(
                    points: points,
                    axisMin: axisMin,
                    axisMax: axisMax,
                  ),
                  size: Size.infinite,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 44),
          child: Row(
            children: [
              for (var i = 0; i < points.length; i++)
                Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        isEn ? points[i].monthEn : points[i].monthTh,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: i == points.length - 1
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: i == points.length - 1
                              ? AppColors.text
                              : AppColors.muted,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _fmtAxis(double v) {
    final twoDec = v.toStringAsFixed(2);
    return twoDec.endsWith('0') ? v.toStringAsFixed(1) : twoDec;
  }
}

class _WeightChartPainter extends CustomPainter {
  const _WeightChartPainter({
    required this.points,
    required this.axisMin,
    required this.axisMax,
  });

  final List<WeightPoint> points;
  final double axisMin;
  final double axisMax;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1;

    for (final ratio in const [0.0, 0.5, 1.0]) {
      final y = 8 + (size.height - 16) * ratio;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (points.isEmpty) return;

    final span = (axisMax - axisMin).abs() < 0.01 ? 1.0 : axisMax - axisMin;
    final usableH = size.height - 16;
    final coords = <Offset>[];
    for (var i = 0; i < points.length; i++) {
      final x = ((i + 0.5) / points.length) * size.width;
      final normalized = ((points[i].kg - axisMin) / span).clamp(0.0, 1.0);
      final y = 8 + usableH * (1.0 - normalized);
      coords.add(Offset(x, y));
    }

    if (coords.length >= 2) {
      final path = Path()..moveTo(coords.first.dx, coords.first.dy);
      for (var i = 1; i < coords.length; i++) {
        path.lineTo(coords[i].dx, coords[i].dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = AppColors.ink
          ..strokeWidth = 2.2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    for (var i = 0; i < coords.length; i++) {
      final isLatest = i == coords.length - 1;
      if (isLatest) {
        canvas.drawCircle(coords[i], 5, Paint()..color = AppColors.card);
        canvas.drawCircle(
          coords[i],
          5,
          Paint()
            ..color = AppColors.ink
            ..strokeWidth = 2.2
            ..style = PaintingStyle.stroke,
        );
      } else {
        canvas.drawCircle(coords[i], 3.8, Paint()..color = AppColors.ink);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WeightChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.axisMin != axisMin ||
        oldDelegate.axisMax != axisMax;
  }
}

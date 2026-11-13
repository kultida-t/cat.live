import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/cat_ai_data.dart';
import 'cat_ai_l10n.dart';

/// ป้ายระดับความรุนแรงเหนือข้อความตอบ (สีเขียวอ่อนตามเว็บจริง)
class CatAiLevelBadge extends StatelessWidget {
  const CatAiLevelBadge({super.key, required this.level, required this.isEn});

  final CatAiLevel level;
  final bool isEn;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.catAiLevelSafeBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.catAiLevelSafeBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            LucideIcons.circle,
            size: 8,
            color: AppColors.catAiLevelSafeInk,
          ),
          const SizedBox(width: 6),
          Text(
            CatAiL10n.levelLabel(level, isEn),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.catAiLevelSafeInk,
            ),
          ),
        ],
      ),
    );
  }
}

/// การ์ดสรุปเพื่อบันทึกเข้าประวัติ (เส้นประตามเว็บจริง) พร้อมปุ่มแก้ไขและยืนยันบันทึก
class CatAiRecordCard extends StatelessWidget {
  const CatAiRecordCard({
    super.key,
    required this.record,
    required this.isEn,
    required this.onEdit,
    required this.onConfirm,
    required this.onViewHistory,
  });

  final CatAiRecordSummary record;
  final bool isEn;
  final VoidCallback onEdit;
  final VoidCallback onConfirm;
  final VoidCallback onViewHistory;

  @override
  Widget build(BuildContext context) {
    final rows = [
      (CatAiL10n.recordType(isEn), record.type),
      (CatAiL10n.recordTopic(isEn), record.topic),
      (CatAiL10n.recordDate(isEn), record.date),
      (CatAiL10n.recordDetails(isEn), record.details),
    ];
    return CustomPaint(
      foregroundPainter: _DashedBorderPainter(color: AppColors.btnBorder),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.soft,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  LucideIcons.clipboardList,
                  size: 16,
                  color: AppColors.text,
                ),
                const SizedBox(width: 8),
                Text(
                  CatAiL10n.recordTitle(isEn),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final (label, value) in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 84,
                      child: Text(
                        label,
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            if (record.saved)
              _SavedPill(
                label: CatAiL10n.recordSaved(isEn),
                actionLabel: CatAiL10n.recordViewHistory(isEn),
                onTap: onViewHistory,
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _CardButton(
                      label: CatAiL10n.recordEdit(isEn),
                      background: Colors.white,
                      border: AppColors.line2,
                      onTap: onEdit,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: _CardButton(
                      label: CatAiL10n.recordConfirm(isEn),
                      background: AppColors.btn,
                      border: AppColors.btnBorder,
                      onTap: onConfirm,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// แถบสถานะหลังบันทึกแล้ว: ข้อความยืนยันทางซ้าย และลิงก์ดูประวัติทางขวา
class _SavedPill extends StatelessWidget {
  const _SavedPill({
    required this.label,
    required this.actionLabel,
    required this.onTap,
  });

  final String label;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(
              LucideIcons.check,
              size: 16,
              color: AppColors.catAiLevelSafeInk,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.catAiLevelSafeInk,
                ),
              ),
            ),
            Text(
              actionLabel,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            const Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: AppColors.ink,
            ),
          ],
        ),
      ),
    );
  }
}

/// วาดกรอบเส้นประรอบการ์ด ให้ตรงกับเส้นประของเว็บจริง
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(16)),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 5), paint);
        distance += 9;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _CardButton extends StatelessWidget {
  const _CardButton({
    required this.label,
    required this.background,
    required this.border,
    required this.onTap,
  });

  final String label;
  final Color background;
  final Color border;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
        ),
      ),
    );
  }
}

/// แผ่นแก้ไขรายละเอียดในการ์ดสรุป คืนค่าข้อความใหม่เมื่อกดบันทึกการแก้ไข
Future<String?> showCatAiRecordEditSheet(
  BuildContext context, {
  required String initial,
  required bool isEn,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _RecordEditSheet(initial: initial, isEn: isEn),
  );
}

class _RecordEditSheet extends StatefulWidget {
  const _RecordEditSheet({required this.initial, required this.isEn});

  final String initial;
  final bool isEn;

  @override
  State<_RecordEditSheet> createState() => _RecordEditSheetState();
}

class _RecordEditSheetState extends State<_RecordEditSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              CatAiL10n.recordEditTitle(widget.isEn),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 3,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.line2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _CardButton(
              label: CatAiL10n.recordSaveEdit(widget.isEn),
              background: AppColors.btn,
              border: AppColors.btnBorder,
              onTap: () {
                final text = _controller.text.trim();
                if (text.isNotEmpty) Navigator.of(context).pop(text);
              },
            ),
          ],
        ),
      ),
    );
  }
}

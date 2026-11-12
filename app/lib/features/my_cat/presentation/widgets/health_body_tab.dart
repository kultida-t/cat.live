import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/my_cat_data.dart';
import 'health_shared_widgets.dart';
import 'my_cat_l10n.dart';

class _OrganHotspotSpec {
  const _OrganHotspotSpec({
    required this.organ,
    required this.tagX,
    required this.tagY,
    required this.dotX,
    required this.dotY,
    required this.dashed,
  });

  final BodyOrganId organ;
  final double tagX;
  final double tagY;
  final double dotX;
  final double dotY;
  final bool dashed;
}

const _organSpecs = <_OrganHotspotSpec>[
  _OrganHotspotSpec(
    organ: BodyOrganId.eyesEars,
    tagX: 6,
    tagY: 24,
    dotX: 156,
    dotY: 100,
    dashed: false,
  ),
  _OrganHotspotSpec(
    organ: BodyOrganId.mouthTeeth,
    tagX: 6,
    tagY: 96,
    dotX: 184,
    dotY: 125,
    dashed: false,
  ),
  _OrganHotspotSpec(
    organ: BodyOrganId.heartLungs,
    tagX: 6,
    tagY: 168,
    dotX: 175,
    dotY: 184,
    dashed: true,
  ),
  _OrganHotspotSpec(
    organ: BodyOrganId.stomachGut,
    tagX: 6,
    tagY: 240,
    dotX: 180,
    dotY: 231,
    dashed: true,
  ),
  _OrganHotspotSpec(
    organ: BodyOrganId.skinCoat,
    tagX: 302,
    tagY: 24,
    dotX: 220,
    dotY: 58,
    dashed: false,
  ),
  _OrganHotspotSpec(
    organ: BodyOrganId.kidneyLiver,
    tagX: 302,
    tagY: 104,
    dotX: 238,
    dotY: 224,
    dashed: true,
  ),
  _OrganHotspotSpec(
    organ: BodyOrganId.weight,
    tagX: 302,
    tagY: 184,
    dotX: 253,
    dotY: 238,
    dashed: false,
  ),
  _OrganHotspotSpec(
    organ: BodyOrganId.jointsBones,
    tagX: 302,
    tagY: 264,
    dotX: 209,
    dotY: 275,
    dashed: false,
  ),
];

/// แท็บ 2: แผนผังร่างกายแมว 8 จุดอวัยวะและสถานะรายจุด — เทียบตรงเว็บ www.แมว.live
class HealthBodyTab extends StatefulWidget {
  const HealthBodyTab({
    super.key,
    required this.cat,
    required this.isEn,
    required this.onUploadDocument,
  });

  final CatProfile cat;
  final bool isEn;
  final VoidCallback onUploadDocument;

  @override
  State<HealthBodyTab> createState() => _HealthBodyTabState();
}

class _HealthBodyTabState extends State<HealthBodyTab> {
  late BodyOrganId _selectedOrgan = _defaultOrganFor(widget.cat.healthBook);

  @override
  void didUpdateWidget(covariant HealthBodyTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cat.id != widget.cat.id) {
      _selectedOrgan = _defaultOrganFor(widget.cat.healthBook);
    }
  }

  BodyOrganId _defaultOrganFor(CatHealthBook book) {
    for (final status in const [
      BodyOrganStatus.abnormal,
      BodyOrganStatus.watch,
      BodyOrganStatus.normal,
    ]) {
      for (final spec in _organSpecs) {
        if (book.reportFor(spec.organ).status == status) {
          return spec.organ;
        }
      }
    }
    return BodyOrganId.eyesEars;
  }

  ({Color bg, Color stroke, Color ink, Color subInk}) _statusPalette(
    BodyOrganStatus status,
  ) {
    return switch (status) {
      BodyOrganStatus.normal => (
        bg: AppColors.card,
        stroke: AppColors.healthNormalStroke,
        ink: AppColors.healthNormalInk,
        subInk: AppColors.healthNormalInk,
      ),
      BodyOrganStatus.watch => (
        bg: AppColors.healthWatchBg,
        stroke: AppColors.healthWatchStroke,
        ink: AppColors.text,
        subInk: AppColors.healthWatchInk,
      ),
      BodyOrganStatus.abnormal => (
        bg: AppColors.healthAbnormalBg,
        stroke: AppColors.healthAbnormalStroke,
        ink: AppColors.healthAbnormalInk,
        subInk: AppColors.healthAbnormalInk,
      ),
      BodyOrganStatus.empty => (
        bg: AppColors.card,
        stroke: AppColors.healthEmptyStroke,
        ink: AppColors.text2,
        subInk: AppColors.muted,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final isEn = widget.isEn;
    final book = widget.cat.healthBook;
    final counts = <BodyOrganStatus, int>{
      for (final s in BodyOrganStatus.values) s: 0,
    };
    for (final spec in _organSpecs) {
      final st = book.reportFor(spec.organ).status;
      counts[st] = (counts[st] ?? 0) + 1;
    }

    final selectedReport = book.reportFor(_selectedOrgan);
    final selectedPalette = _statusPalette(selectedReport.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // สรุปสถานะด้านบนแบบจุดสี + ข้อความ (ไม่มีกรอบชิป)
        Wrap(
          spacing: 14,
          runSpacing: 8,
          children: [
            for (final status in BodyOrganStatus.values)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _statusPalette(status).stroke,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isEn
                        ? '${status.enLabel} ${counts[status] ?? 0}'
                        : '${status.thLabel} ${counts[status] ?? 0}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.text2,
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 10),
        // แผนผังแมวนั่ง 8 จุดวางบนพื้นครีมอ่อนของหน้าโดยตรง (ไม่มีกรอบการ์ดขาวล้อม)
        LayoutBuilder(
          builder: (context, constraints) {
            const canvasW = 400.0;
            const canvasH = 322.0;
            const tagW = 92.0;
            const tagH = 36.0;
            final w = constraints.maxWidth;
            final scale = w / canvasW;
            final h = canvasH * scale;

            return SizedBox(
              width: w,
              height: h,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 100 * scale,
                    top: 14 * scale,
                    width: 210.4 * scale,
                    height: 280 * scale,
                    child: _StyledSittingCat(catId: widget.cat.id),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _BodyMapLinePainter(
                        scale: scale,
                        tagW: tagW,
                        tagH: tagH,
                        selectedOrgan: _selectedOrgan,
                        statusColorOf: (organ) =>
                            _statusPalette(book.reportFor(organ).status).stroke,
                      ),
                    ),
                  ),
                  for (final spec in _organSpecs)
                    Positioned(
                      left: spec.tagX * scale,
                      top: spec.tagY * scale,
                      width: tagW * scale,
                      height: tagH * scale,
                      child: _OrganCalloutButton(
                        title: isEn ? spec.organ.enLabel : spec.organ.thLabel,
                        statusText: isEn
                            ? book.reportFor(spec.organ).status.enLabel
                            : book.reportFor(spec.organ).status.thLabel,
                        palette: _statusPalette(
                          book.reportFor(spec.organ).status,
                        ),
                        selected: _selectedOrgan == spec.organ,
                        onTap: () => setState(() => _selectedOrgan = spec.organ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        // การ์ดรายละเอียดจุดที่เลือก (เส้นขอบสีตามสถานะ ยกเว้นยังไม่มีข้อมูลใช้เส้นขอบปกติ)
        HealthCard(
          borderColor: selectedReport.status == BodyOrganStatus.empty
              ? AppColors.line
              : selectedPalette.stroke,
          borderRadius: 18,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isEn ? _selectedOrgan.enLabel : _selectedOrgan.thLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  HealthTagPill(
                    label: isEn
                        ? selectedReport.status.enLabel
                        : selectedReport.status.thLabel,
                    backgroundColor: selectedPalette.bg == AppColors.card
                        ? AppColors.soft
                        : selectedPalette.bg,
                    textColor: selectedPalette.subInk,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _summaryText(selectedReport, isEn),
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: AppColors.text2,
                ),
              ),
              if (selectedReport.status == BodyOrganStatus.empty) ...[
                const SizedBox(height: 12),
                HealthOutlinedActionButton(
                  icon: LucideIcons.upload,
                  label: isEn ? 'Upload document' : 'อัปโหลดเอกสาร',
                  onPressed: widget.onUploadDocument,
                ),
              ] else if ((isEn ? selectedReport.sourceEn : selectedReport.sourceTh)
                  .isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  isEn
                      ? 'From: ${selectedReport.sourceEn}'
                      : 'จาก: ${selectedReport.sourceTh}',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(
                LucideIcons.info,
                size: 15,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                isEn
                    ? 'Summarized only from notes and documents in this health book — not a medical diagnosis. Consult a vet if your cat shows abnormal signs.'
                    : 'สรุปจากบันทึกและเอกสารที่เก็บไว้ในสมุดสุขภาพเท่านั้น ไม่ใช่การวินิจฉัย หากแมวมีอาการผิดปกติให้ปรึกษาสัตวแพทย์',
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  color: AppColors.muted,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _summaryText(BodyOrganReport report, bool isEn) {
    final text = isEn ? report.summaryEn : report.summaryTh;
    if (text.isNotEmpty) return text;
    final organ = isEn ? _selectedOrgan.enLabel : _selectedOrgan.thLabel;
    final catName = MyCatL10n.catName(widget.cat.name, isEn);
    return isEn
        ? 'No info for $organ of $catName yet. Upload lab results or vet notes to summarize this area.'
        : 'ยังไม่มีข้อมูลของ$organของ$catName อัปโหลดผลตรวจหรือบันทึกจากสัตวแพทย์ เพื่อสรุปส่วนนี้ได้';
  }
}

class _StyledSittingCat extends StatelessWidget {
  const _StyledSittingCat({required this.catId});

  final String catId;

  @override
  Widget build(BuildContext context) {
    const assetPath = 'assets/images/my_cat/orange-sitting.webp';
    Widget image = Image.asset(
      assetPath,
      fit: BoxFit.contain,
      colorBlendMode: BlendMode.multiply,
      errorBuilder: (_, _, _) =>
          const Icon(LucideIcons.cat, size: 96, color: AppColors.muted),
    );

    if (catId == 'cat-mali') {
      image = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.51, 0.43, 0.06, 0, 14, //
          0.21, 0.73, 0.06, 0, 14, //
          0.21, 0.43, 0.36, 0, 14, //
          0, 0, 0, 1, 0,
        ]),
        child: image,
      );
    } else if (catId == 'cat-thuadam') {
      image = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.11, 0.22, 0.03, 0, -18, //
          0.11, 0.22, 0.03, 0, -18, //
          0.11, 0.22, 0.03, 0, -18, //
          0, 0, 0, 1, 0,
        ]),
        child: image,
      );
    }

    return image;
  }
}

class _OrganCalloutButton extends StatelessWidget {
  const _OrganCalloutButton({
    required this.title,
    required this.statusText,
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String statusText;
  final ({Color bg, Color stroke, Color ink, Color subInk}) palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$title $statusText',
      child: Material(
        color: palette.bg,
        borderRadius: BorderRadius.circular(12),
        elevation: selected ? 2 : 0,
        shadowColor: const Color(0x264A3428),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: palette.stroke,
                width: selected ? 2.0 : 1.2,
              ),
            ),
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                      color: palette.ink,
                    ),
                  ),
                  Text(
                    statusText,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                      height: 1.15,
                      color: palette.subInk,
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

class _BodyMapLinePainter extends CustomPainter {
  const _BodyMapLinePainter({
    required this.scale,
    required this.tagW,
    required this.tagH,
    required this.selectedOrgan,
    required this.statusColorOf,
  });

  final double scale;
  final double tagW;
  final double tagH;
  final BodyOrganId selectedOrgan;
  final Color Function(BodyOrganId) statusColorOf;

  @override
  void paint(Canvas canvas, Size size) {
    final shadowPaint = Paint()..color = const Color(0x144A3428);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(205 * scale, 304 * scale),
        width: 160 * scale,
        height: 16 * scale,
      ),
      shadowPaint,
    );

    for (final spec in _organSpecs) {
      final color = statusColorOf(spec.organ);
      final isSelected = spec.organ == selectedOrgan;
      final startX = spec.organ.isLeft
          ? (spec.tagX + tagW) * scale
          : spec.tagX * scale;
      final startY = (spec.tagY + tagH / 2) * scale;
      final endX = spec.dotX * scale;
      final endY = spec.dotY * scale;

      final linePaint = Paint()
        ..color = color
        ..strokeWidth = (isSelected ? 2.1 : 1.5) * scale.clamp(0.75, 1.15)
        ..style = PaintingStyle.stroke;

      if (spec.dashed) {
        _drawDashedLine(
          canvas,
          Offset(startX, startY),
          Offset(endX, endY),
          linePaint,
        );
      } else {
        canvas.drawLine(Offset(startX, startY), Offset(endX, endY), linePaint);
      }

      final dotRadius = (isSelected ? 5.2 : 4.2) * scale.clamp(0.75, 1.15);
      canvas.drawCircle(
        Offset(endX, endY),
        dotRadius + 2,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        Offset(endX, endY),
        dotRadius,
        Paint()..color = color,
      );
    }
  }

  void _drawDashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    final total = (b - a).distance;
    if (total <= 0) return;
    final dir = (b - a) / total;
    const dash = 4.0;
    const gap = 3.5;
    var d = 0.0;
    while (d < total) {
      final next = (d + dash).clamp(0.0, total);
      canvas.drawLine(a + dir * d, a + dir * next, paint);
      d += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _BodyMapLinePainter oldDelegate) {
    return oldDelegate.scale != scale ||
        oldDelegate.selectedOrgan != selectedOrgan;
  }
}

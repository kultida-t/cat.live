import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/cat_health_data.dart';
import 'health_shared_widgets.dart';

/// แท็บ 7: อัปโหลดและรายการเอกสารสุขภาพ (ผลตรวจเลือด ใบเสร็จ สมุดวัคซีน)
class HealthDocumentsTab extends StatelessWidget {
  const HealthDocumentsTab({
    super.key,
    required this.documents,
    required this.isEn,
    required this.onUploadTap,
  });

  final List<HealthDocumentItem> documents;
  final bool isEn;
  final VoidCallback onUploadTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          label: isEn ? 'Upload photo or PDF' : 'อัปโหลดรูปหรือ PDF',
          child: Material(
            color: AppColors.soft.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              onTap: onUploadTap,
              borderRadius: BorderRadius.circular(18),
              child: CustomPaint(
                painter: _DashedRoundedPainter(
                  color: AppColors.btnBorder,
                  radius: 18,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        LucideIcons.upload,
                        size: 24,
                        color: AppColors.ink,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isEn ? 'Upload photo or PDF' : 'อัปโหลดรูปหรือ PDF',
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isEn
                            ? 'Lab results, receipts, vaccine book, cat photos, or records'
                            : 'ผลตรวจ ใบเสร็จ สมุดวัคซีน รูปแมว หรือไฟล์ข้อมูล',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (documents.isEmpty)
          HealthEmptyStateCard(
            icon: LucideIcons.folderOpen,
            title: isEn ? 'No documents uploaded' : 'ยังไม่มีเอกสารแนบ',
            subtitle: isEn
                ? 'Tap the upload box above to attach lab results or vaccine book photos.'
                : 'แตะกล่องด้านบนเพื่อแนบผลตรวจ ใบเสร็จ หรือรูปถ่ายสมุดวัคซีน',
          )
        else
          for (var i = 0; i < documents.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _DocumentTile(item: documents[i], isEn: isEn),
          ],
        const SizedBox(height: 14),
        Text(
          isEn
              ? 'Stored documents help summarize health in the “Body” tab and Vet Summary · uploaded files stay on this page for now (not sent to server yet)'
              : 'เอกสารที่เก็บไว้ใช้สรุปสุขภาพในแท็บ “ร่างกาย” และ Vet Summary · ไฟล์ที่อัปโหลดตอนนี้เก็บแค่ในหน้านี้ ยังไม่ได้ส่งขึ้นเซิร์ฟเวอร์',
          style: const TextStyle(
            fontSize: 12,
            height: 1.45,
            color: AppColors.muted,
          ),
        ),
      ],
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({required this.item, required this.isEn});

  final HealthDocumentItem item;
  final bool isEn;

  @override
  Widget build(BuildContext context) {
    final date = isEn ? item.dateEn : item.dateTh;
    return HealthCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderRadius: 18,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: item.isPdf
                  ? AppColors.healthDocPdfBg
                  : AppColors.healthDocImgBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              item.isPdf ? LucideIcons.fileText : LucideIcons.image,
              size: 20,
              color: item.isPdf
                  ? AppColors.healthDocPdfInk
                  : AppColors.healthDocImgInk,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$date · ${item.sizeLabel}',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedRoundedPainter extends CustomPainter {
  const _DashedRoundedPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dash = 6.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        final next = (d + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(d, next), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}

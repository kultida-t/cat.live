import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import 'cat_ai_l10n.dart';

/// เมนู + แบบป๊อปอัปลอยเหนือแถบพิมพ์ตามเว็บจริง: แนบรูป / ดูสีหน้า / เรื่องที่ถามบ่อย
/// ฝั่งที่เรียกใช้เป็นคนซ่อนเมนูเองหลังผู้ใช้เลือกรายการ
class CatAiAddMenu extends StatelessWidget {
  const CatAiAddMenu({
    super.key,
    required this.isEn,
    required this.onPickImage,
    required this.onFaceCheck,
    required this.onQuestion,
  });

  final bool isEn;
  final ValueChanged<ImageSource> onPickImage;
  final VoidCallback onFaceCheck;
  final ValueChanged<String> onQuestion;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x245A4030),
            blurRadius: 32,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 560),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionTitle(CatAiL10n.addMenuAttachSection(isEn)),
              _MenuRow(
                icon: LucideIcons.camera,
                title: CatAiL10n.takePhotoTitle(isEn),
                hint: CatAiL10n.takePhotoHint(isEn),
                onTap: () => onPickImage(ImageSource.camera),
              ),
              _MenuRow(
                icon: LucideIcons.image,
                title: CatAiL10n.pickGalleryTitle(isEn),
                onTap: () => onPickImage(ImageSource.gallery),
              ),
              _MenuRow(
                icon: LucideIcons.scanFace,
                iconColor: AppColors.catAiScanInk,
                title: CatAiL10n.faceCheckLabel(isEn),
                hint: CatAiL10n.faceCheckHint(isEn),
                onTap: onFaceCheck,
              ),
              const Divider(height: 14, color: AppColors.line),
              _SectionTitle(CatAiL10n.addMenuFaqSection(isEn)),
              _MenuRow(
                icon: LucideIcons.stethoscope,
                title: CatAiL10n.faqSymptomTitle(isEn),
                hint: CatAiL10n.faqSymptomQuestion(isEn),
                onTap: () => onQuestion(CatAiL10n.faqSymptomQuestion(isEn)),
              ),
              _MenuRow(
                icon: LucideIcons.clipboardList,
                title: CatAiL10n.faqSummaryTitle(isEn),
                hint: CatAiL10n.faqSummaryQuestion(isEn),
                onTap: () => onQuestion(CatAiL10n.faqSummaryQuestion(isEn)),
              ),
              _MenuRow(
                icon: LucideIcons.activity,
                title: CatAiL10n.faqWeightTitle(isEn),
                hint: CatAiL10n.faqWeightQuestion(isEn),
                onTap: () => onQuestion(CatAiL10n.faqWeightQuestion(isEn)),
              ),
              _MenuRow(
                icon: LucideIcons.syringe,
                title: CatAiL10n.faqVaccineTitle(isEn),
                hint: CatAiL10n.faqVaccineQuestion(isEn),
                onTap: () => onQuestion(CatAiL10n.faqVaccineQuestion(isEn)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, color: AppColors.muted),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.hint,
    this.iconColor = AppColors.text,
  });

  final IconData icon;
  final String title;
  final String? hint;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: hint == null ? title : '$title $hint',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                Icon(icon, size: 22, color: iconColor),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                if (hint != null) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      hint!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

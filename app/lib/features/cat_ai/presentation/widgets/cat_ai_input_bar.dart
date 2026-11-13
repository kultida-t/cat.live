import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/cat_ai_data.dart';
import 'cat_ai_l10n.dart';

/// ปุ่มคำถามลัดเหนือช่องพิมพ์ (ไอคอนสีตามเว็บจริง)
class CatAiQuickQuestions extends StatelessWidget {
  const CatAiQuickQuestions({
    super.key,
    required this.questions,
    required this.isEn,
    required this.onSelect,
  });

  final List<CatAiQuickQuestion> questions;
  final bool isEn;
  final ValueChanged<CatAiQuickQuestion> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < questions.length; i++)
          Material(
            color: Colors.white.withValues(alpha: 0.75),
            shape: const StadiumBorder(),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () => onSelect(questions[i]),
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: const ShapeDecoration(
                  shape: StadiumBorder(),
                  shadows: [
                    BoxShadow(
                      color: Color(0x145A4030),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      i.isEven ? LucideIcons.syringe : LucideIcons.stethoscope,
                      size: 15,
                      color: i.isEven
                          ? AppColors.trackerSafeTeal
                          : AppColors.nearbyEmergencySiren,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isEn ? questions[i].labelEn : questions[i].labelTh,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// แถบพิมพ์ถาม: ปุ่ม +, ช่องพิมพ์, และปุ่มด้านขวา
/// ก่อนมีข้อความจะเป็น ดูสีหน้า + คุยกับหมอ, หลังมีข้อความจะเป็น ไมค์ + คุยกับหมอ
class CatAiInputBar extends StatelessWidget {
  const CatAiInputBar({
    super.key,
    required this.controller,
    required this.catName,
    required this.isEn,
    required this.isSending,
    required this.hasMessages,
    required this.onSubmit,
    required this.onAdd,
    required this.onFaceCheck,
    required this.onVoiceInput,
    required this.onVetCall,
  });

  final TextEditingController controller;
  final String catName;
  final bool isEn;
  final bool isSending;
  final bool hasMessages;
  final ValueChanged<String> onSubmit;
  final VoidCallback onAdd;
  final VoidCallback onFaceCheck;
  final VoidCallback onVoiceInput;
  final VoidCallback onVetCall;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.only(left: 6, right: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F5A4030),
            blurRadius: 28,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _RoundIconButton(
            label: CatAiL10n.addFileLabel(isEn),
            icon: LucideIcons.plus,
            background: Colors.transparent,
            iconColor: AppColors.text,
            onTap: onAdd,
          ),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !isSending,
              textInputAction: TextInputAction.send,
              onSubmitted: onSubmit,
              style: const TextStyle(fontSize: 15, color: AppColors.text),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: CatAiL10n.inputHint(catName, isEn),
                hintStyle: const TextStyle(
                  fontSize: 15,
                  color: AppColors.muted,
                ),
              ),
            ),
          ),
          if (hasMessages)
            _RoundIconButton(
              label: CatAiL10n.voiceInputLabel(isEn),
              icon: LucideIcons.mic,
              background: Colors.transparent,
              iconColor: AppColors.muted,
              onTap: onVoiceInput,
            )
          else
            _RoundIconButton(
              label: CatAiL10n.faceCheckLabel(isEn),
              icon: LucideIcons.scanFace,
              background: AppColors.catAiScanBg,
              iconColor: AppColors.catAiScanInk,
              onTap: onFaceCheck,
            ),
          const SizedBox(width: 6),
          _RoundIconButton(
            label: CatAiL10n.vetVoiceLabel(isEn),
            icon: LucideIcons.stethoscope,
            background: AppColors.catAiStethoscopeBg,
            iconColor: AppColors.catAiMicDark,
            onTap: onVetCall,
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.iconColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: background, shape: BoxShape.circle),
          child: Icon(icon, size: 20, color: iconColor),
        ),
      ),
    );
  }
}

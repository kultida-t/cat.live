import 'dart:typed_data';

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

/// รูปที่แนบไว้ก่อนส่ง แสดงเหนือช่องพิมพ์ พร้อมปุ่มลบรูป
class CatAiAttachmentPreview extends StatelessWidget {
  const CatAiAttachmentPreview({
    super.key,
    required this.bytes,
    required this.hint,
    required this.removeLabel,
    required this.onRemove,
  });

  final Uint8List bytes;
  final String hint;
  final String removeLabel;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
      decoration: BoxDecoration(
        color: AppColors.soft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line2),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              bytes,
              width: 44,
              height: 44,
              cacheWidth: 132,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hint,
              style: const TextStyle(
                fontSize: 13,
                height: 1.35,
                color: AppColors.text2,
              ),
            ),
          ),
          Semantics(
            button: true,
            label: removeLabel,
            child: InkWell(
              onTap: onRemove,
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(LucideIcons.x, size: 18, color: AppColors.muted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// แถบพิมพ์ถาม: ปุ่ม + (กลายเป็นกากบาทตอนเปิดเมนู), ช่องพิมพ์, และปุ่มด้านขวา
/// ไม่มีข้อความหรือรูปแนบ: ดูสีหน้า/ไมค์ + คุยกับหมอ, มีข้อความหรือรูปแนบ: ปุ่มส่ง
class CatAiInputBar extends StatelessWidget {
  const CatAiInputBar({
    super.key,
    required this.controller,
    required this.catName,
    required this.isEn,
    required this.isSending,
    required this.hasMessages,
    required this.hasAttachment,
    required this.isMenuOpen,
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
  final bool hasAttachment;
  final bool isMenuOpen;
  final VoidCallback onSubmit;
  final VoidCallback onAdd;
  final VoidCallback onFaceCheck;
  final VoidCallback onVoiceInput;
  final VoidCallback onVetCall;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final canSend =
            !isSending && (value.text.trim().isNotEmpty || hasAttachment);
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
                label: isMenuOpen
                    ? CatAiL10n.closeMenuLabel(isEn)
                    : CatAiL10n.addFileLabel(isEn),
                icon: isMenuOpen ? LucideIcons.x : LucideIcons.plus,
                background: isMenuOpen ? AppColors.btn : Colors.transparent,
                iconColor: AppColors.text,
                onTap: onAdd,
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: !isSending,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) {
                    if (canSend) onSubmit();
                  },
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
              if (canSend)
                _RoundIconButton(
                  label: CatAiL10n.sendLabel(isEn),
                  icon: LucideIcons.arrowUp,
                  background: AppColors.btn,
                  iconColor: AppColors.ink,
                  onTap: onSubmit,
                )
              else ...[
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
            ],
          ),
        );
      },
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

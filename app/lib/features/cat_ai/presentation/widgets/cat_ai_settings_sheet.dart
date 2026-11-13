import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/cat_ai_controller.dart';
import 'cat_ai_l10n.dart';

/// เปิดแผ่นตั้งค่า Cat AI จากด้านล่าง (รูปแบบคำตอบ และล้างการสนทนา)
Future<void> showCatAiSettingsSheet(BuildContext context, bool isEn) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _CatAiSettingsSheet(isEn: isEn),
  );
}

class _CatAiSettingsSheet extends ConsumerWidget {
  const _CatAiSettingsSheet({required this.isEn});

  final bool isEn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(catAiControllerProvider);
    final ctrl = ref.read(catAiControllerProvider.notifier);
    final hasMessages = state.messages.isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
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
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    CatAiL10n.settingsTitle(isEn),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  label: CatAiL10n.closeLabel(isEn),
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(12),
                    child: const SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(
                        LucideIcons.x,
                        size: 20,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              CatAiL10n.answerStyleTitle(isEn),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.text2,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _StyleOption(
                    label: CatAiL10n.detailedStyle(isEn),
                    selected: state.detailedAnswers,
                    onTap: () => ctrl.setDetailedAnswers(true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StyleOption(
                    label: CatAiL10n.shortStyle(isEn),
                    selected: !state.detailedAnswers,
                    onTap: () => ctrl.setDetailedAnswers(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Semantics(
              button: true,
              enabled: hasMessages,
              label: CatAiL10n.clearChat(isEn),
              child: OutlinedButton(
                onPressed: hasMessages
                    ? () {
                        ctrl.clearMessages();
                        Navigator.of(context).pop();
                      }
                    : null,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: AppColors.catAiClearBg,
                  disabledBackgroundColor: AppColors.catAiClearBg,
                  foregroundColor: AppColors.catAiSettingsDangerInk,
                  disabledForegroundColor: AppColors.catAiSettingsDangerInk
                      .withValues(alpha: 0.5),
                  side: const BorderSide(color: AppColors.line2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  CatAiL10n.clearChat(isEn),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              CatAiL10n.disclaimer(isEn),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _StyleOption extends StatelessWidget {
  const _StyleOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.btn : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.btnBorder : AppColors.line,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: AppColors.text,
            ),
          ),
        ),
      ),
    );
  }
}

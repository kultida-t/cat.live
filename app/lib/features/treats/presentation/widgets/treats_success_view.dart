import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../l10n/treats_l10n.dart';

/// ขั้นตอนที่ 3: หน้าส่งขนมสำเร็จ
class TreatsSuccessView extends StatelessWidget {
  const TreatsSuccessView({
    super.key,
    required this.recipientName,
    required this.totalCount,
    required this.openedFromPost,
    required this.isEn,
    required this.onSendAnother,
    required this.onBack,
  });

  final String recipientName;
  final int totalCount;
  final bool openedFromPost;
  final bool isEn;
  final VoidCallback onSendAnother;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
                    label: TreatsL10n.backLabel(isEn),
                    excludeSemantics: true,
                    child: InkWell(
                      onTap: onBack,
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
                    TreatsL10n.pageTitle(isEn),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          color: AppColors.btn,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.check,
                          size: 40,
                          color: AppColors.treatsOrange,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        TreatsL10n.successTitle(isEn, recipientName),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 280),
                        child: Text(
                          TreatsL10n.successSubtitle(isEn, totalCount),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.45,
                            color: AppColors.text2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: onSendAnother,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.btn,
                            foregroundColor: AppColors.text,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: const BorderSide(
                                color: AppColors.btnBorder,
                                width: 1.5,
                              ),
                            ),
                          ),
                          child: Text(
                            TreatsL10n.sendToAnother(isEn),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: TextButton(
                          onPressed: onBack,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.text,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            TreatsL10n.backToPrevious(
                              isEn,
                              fromFeed: openedFromPost,
                            ),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
    );
  }
}

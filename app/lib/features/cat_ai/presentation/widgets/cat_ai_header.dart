import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/cat_ai_data.dart';
import 'cat_ai_l10n.dart';

/// ส่วนหัวของ Cat AI: โลโก้ + ปุ่มตั้งค่า และแคปซูลแมวที่กำลังคุยอยู่
class CatAiHeader extends StatelessWidget {
  const CatAiHeader({
    super.key,
    required this.cat,
    required this.isEn,
    required this.onOpenSettings,
    required this.onCycleCat,
    required this.onEditCat,
    required this.onOpenMyCat,
  });

  final CatAiCat? cat;
  final bool isEn;
  final VoidCallback onOpenSettings;
  final VoidCallback onCycleCat;
  final VoidCallback onEditCat;
  final VoidCallback onOpenMyCat;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.page,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Row(
              children: [
                const SizedBox(width: 44, height: 44),
                Expanded(
                  child: Center(
                    child: Image.asset(
                      'assets/brand/maew-logo.png',
                      width: 123,
                      height: 36,
                      semanticLabel: 'แมว.live',
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  label: CatAiL10n.settingsLabel(isEn),
                  child: InkWell(
                    onTap: onOpenSettings,
                    borderRadius: BorderRadius.circular(12),
                    child: const SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(
                        LucideIcons.settings2,
                        size: 24,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (cat != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x264A3428),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(cat!.avatarAsset, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: InkWell(
                                onTap: onCycleCat,
                                borderRadius: BorderRadius.circular(8),
                                child: Text(
                                  cat!.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.text,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              LucideIcons.chevronDown,
                              size: 16,
                              color: AppColors.text,
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                '${cat!.breed} ${cat!.ageLabel}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.text2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Semantics(
                              button: true,
                              label: CatAiL10n.editCatLabel(isEn),
                              child: InkWell(
                                onTap: onEditCat,
                                borderRadius: BorderRadius.circular(8),
                                child: const Padding(
                                  padding: EdgeInsets.all(2),
                                  child: Icon(
                                    LucideIcons.pencil,
                                    size: 13,
                                    color: AppColors.text2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: CatAiL10n.myCatLabel(isEn),
                    child: InkWell(
                      onTap: onOpenMyCat,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: const Icon(
                          LucideIcons.pawPrint,
                          size: 22,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

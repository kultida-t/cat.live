import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../l10n/search_l10n.dart';

/// ส่วนหัวหน้าค้นหา: ปุ่มย้อนกลับ + ช่องค้นหาโฟกัสอัตโนมัติ + ปุ่มล้างข้อความ
class SearchHeader extends StatelessWidget {
  const SearchHeader({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.l10n,
    required this.hasQuery,
    required this.onBack,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final SearchL10n l10n;
  final bool hasQuery;
  final VoidCallback onBack;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.page,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
        child: Row(
          children: [
            Semantics(
              button: true,
              label: l10n.backLabel,
              excludeSemantics: true,
              child: InkWell(
                onTap: onBack,
                borderRadius: BorderRadius.circular(12),
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
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                decoration: BoxDecoration(
                  color: AppColors.soft,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.search,
                      size: 20,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Semantics(
                        textField: true,
                        label: l10n.searchLabel,
                        child: TextField(
                          controller: controller,
                          focusNode: focusNode,
                          autofocus: false,
                          textInputAction: TextInputAction.search,
                          onChanged: onChanged,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: AppColors.text,
                          ),
                          decoration: InputDecoration(
                            hintText: l10n.searchPlaceholder,
                            hintStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: AppColors.muted,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (hasQuery)
                      Semantics(
                        button: true,
                        label: l10n.clearSearchLabel,
                        excludeSemantics: true,
                        child: InkWell(
                          onTap: onClear,
                          borderRadius: BorderRadius.circular(999),
                          child: const SizedBox(
                            width: 36,
                            height: 36,
                            child: Icon(
                              LucideIcons.x,
                              size: 18,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

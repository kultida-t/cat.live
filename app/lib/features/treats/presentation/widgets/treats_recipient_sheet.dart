import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../domain/entities/treat_recipient.dart';
import '../l10n/treats_l10n.dart';

/// แผ่นล่างเลือกแมวที่จะส่งขนมให้ครบทั้ง 14 บัญชี พร้อมช่องค้นหา
Future<void> showTreatsRecipientSheet(
  BuildContext context, {
  required List<TreatRecipient> recipients,
  required String selectedId,
  required bool isEn,
  required ValueChanged<String> onSelect,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.sheetBarrier,
    builder: (_) => _TreatsRecipientSheet(
      recipients: recipients,
      selectedId: selectedId,
      isEn: isEn,
      onSelect: onSelect,
    ),
  );
}

class _TreatsRecipientSheet extends StatefulWidget {
  const _TreatsRecipientSheet({
    required this.recipients,
    required this.selectedId,
    required this.isEn,
    required this.onSelect,
  });

  final List<TreatRecipient> recipients;
  final String selectedId;
  final bool isEn;
  final ValueChanged<String> onSelect;

  @override
  State<_TreatsRecipientSheet> createState() => _TreatsRecipientSheetState();
}

class _TreatsRecipientSheetState extends State<_TreatsRecipientSheet> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final filtered = widget.recipients.where((r) {
      if (q.isEmpty) return true;
      return '${r.name} ${r.handle}'.toLowerCase().contains(q);
    }).toList();

    final maxHeight = MediaQuery.sizeOf(context).height * 0.82;

    return Container(
      height: maxHeight,
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
            color: AppColors.sheetBarrier,
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.line2,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    TreatsL10n.sheetTitle(
                      widget.isEn,
                      widget.recipients.length,
                    ),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  label: TreatsL10n.closeLabel(widget.isEn),
                  excludeSemantics: true,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(999),
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
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.soft,
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.search,
                    size: 18,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onChanged: (v) => setState(() => _query = v),
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.text,
                      ),
                      decoration: InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText: TreatsL10n.searchHint(widget.isEn),
                        hintStyle: const TextStyle(
                          fontSize: 15,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      TreatsL10n.searchEmpty(widget.isEn),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.muted,
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 8,
                          childAspectRatio: 0.78,
                        ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final r = filtered[index];
                      final selected = r.id == widget.selectedId;
                      return Semantics(
                        button: true,
                        selected: selected,
                        label: r.name,
                        excludeSemantics: true,
                        child: InkWell(
                          onTap: () {
                            widget.onSelect(r.id);
                            Navigator.of(context).pop();
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: selected
                                            ? AppColors.treatsInk
                                            : Colors.transparent,
                                        width: 2.5,
                                      ),
                                    ),
                                    child: AppAvatar(
                                      source: r.avatarUrl,
                                      bg: r.avatarBg,
                                      size: 60,
                                    ),
                                  ),
                                  if (selected)
                                    Positioned(
                                      right: -1,
                                      bottom: -1,
                                      child: Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: AppColors.treatsInk,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppColors.card,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          LucideIcons.check,
                                          size: 11,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                r.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: selected
                                      ? AppColors.text
                                      : AppColors.text2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/help_data.dart';
import 'help_l10n.dart';

/// ชุดสีประจำแต่ละหมวดหมู่ของหน้าช่วยเหลือ (ใช้ร่วมกันทั้งแถบหมวดหมู่ แท็ก และปุ่ม)
({Color bg, Color border, Color ink}) helpCategoryColors(HelpCategory category) =>
    switch (category) {
      HelpCategory.lost => (
          bg: const Color(0xFFFDE6DF),
          border: const Color(0xFFF3C7BA),
          ink: const Color(0xFF7A3224),
        ),
      HelpCategory.found => (
          bg: AppColors.quickFeedBg,
          border: AppColors.quickFeedBorder,
          ink: AppColors.quickFeedInk,
        ),
      HelpCategory.helpRequest => (
          bg: const Color(0xFFFEF3C7),
          border: const Color(0xFFFDE68A),
          ink: const Color(0xFF92400E),
        ),
      HelpCategory.adoption => (
          bg: const Color(0xFFEDE9FE),
          border: const Color(0xFFD5CCFA),
          ink: const Color(0xFF553C9A),
        ),
      HelpCategory.foster => (
          bg: const Color(0xFFEBF2FF),
          border: const Color(0xFFC7D9F9),
          ink: const Color(0xFF2A4B8D),
        ),
    };

/// แถบหมวดหมู่ประกาศย่อยแนวนอน พร้อมป้ายจำนวนและเฟดขอบ (ไม่มีปุ่มลูกศร)
class HelpCategoryChips extends StatefulWidget {
  const HelpCategoryChips({
    super.key,
    required this.selectedCategory,
    required this.totalCount,
    required this.countFor,
    required this.isEn,
    required this.onSelectAll,
    required this.onToggle,
  });

  final HelpCategory? selectedCategory;
  final int totalCount;
  final int Function(HelpCategory) countFor;
  final bool isEn;
  final VoidCallback onSelectAll;
  final ValueChanged<HelpCategory> onToggle;

  @override
  State<HelpCategoryChips> createState() => _HelpCategoryChipsState();
}

class _HelpCategoryChipsState extends State<HelpCategoryChips> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _allKey = GlobalKey();
  final Map<HelpCategory, GlobalKey> _categoryKeys = {
    for (final c in HelpCategory.values) c: GlobalKey(),
  };
  bool _canScrollLeft = false;
  bool _canScrollRight = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateFades);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateFades());
  }

  @override
  void didUpdateWidget(covariant HelpCategoryChips oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategory != widget.selectedCategory) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _focusSelected());
    }
  }

  void _focusSelected() {
    final targetKey = widget.selectedCategory == null
        ? _allKey
        : _categoryKeys[widget.selectedCategory];
    final ctx = targetKey?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.5,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateFades);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateFades() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final left = pos.pixels > 4;
    final right = pos.pixels < pos.maxScrollExtent - 4;
    if (left != _canScrollLeft || right != _canScrollRight) {
      setState(() {
        _canScrollLeft = left;
        _canScrollRight = right;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ShaderMask(
        shaderCallback: (bounds) {
          final leftColor = _canScrollLeft ? Colors.transparent : Colors.white;
          final rightColor = _canScrollRight ? Colors.transparent : Colors.white;
          return LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [leftColor, Colors.white, Colors.white, rightColor],
            stops: const [0.0, 0.06, 0.88, 1.0],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: ListView.separated(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          itemCount: HelpCategory.values.length + 1,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            if (index == 0) {
              final isAllSelected = widget.selectedCategory == null;
              return KeyedSubtree(
                key: _allKey,
                child: InkWell(
                  key: const ValueKey('help-chip-all'),
                  onTap: widget.onSelectAll,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isAllSelected ? AppColors.btn : AppColors.card,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isAllSelected
                            ? AppColors.btnBorder
                            : AppColors.line2,
                        width: isAllSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          HelpL10n.allCategories(widget.isEn),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isAllSelected
                                ? AppColors.ink
                                : AppColors.text,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: isAllSelected
                                ? Colors.white.withValues(alpha: 0.78)
                                : AppColors.soft,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${widget.totalCount}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isAllSelected
                                  ? AppColors.ink
                                  : AppColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            final category = HelpCategory.values[index - 1];
            final isSelected = widget.selectedCategory == category;
            final count = widget.countFor(category);
            final label = HelpL10n.categoryLabel(category, widget.isEn);
            final theme = helpCategoryColors(category);

            return KeyedSubtree(
              key: _categoryKeys[category],
              child: InkWell(
                key: ValueKey('help-chip-${category.name}'),
                onTap: () => widget.onToggle(category),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? theme.bg : AppColors.card,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isSelected ? theme.border : AppColors.line2,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? theme.ink : AppColors.text,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.78)
                              : AppColors.soft,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? theme.ink : AppColors.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

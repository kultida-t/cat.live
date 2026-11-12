import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../domain/entities/my_cat_data.dart';
import '../providers/my_cat_controller.dart';
import 'my_cat_l10n.dart';

/// แถวแคปซูลสลับโปรไฟล์ด้านบน: ตัวฉัน, แมวแต่ละตัว, + เพิ่มแมว พร้อมเฟดขอบซ้าย-ขวา
class ProfileSwitcherRow extends StatefulWidget {
  const ProfileSwitcherRow({
    super.key,
    required this.owner,
    required this.cats,
    required this.selectedTargetId,
    required this.onSelect,
    required this.onAddCat,
    this.isEn = false,
  });

  final OwnerProfile owner;
  final List<CatProfile> cats;
  final String selectedTargetId;
  final ValueChanged<String> onSelect;
  final VoidCallback onAddCat;
  final bool isEn;

  @override
  State<ProfileSwitcherRow> createState() => _ProfileSwitcherRowState();
}

class _ProfileSwitcherRowState extends State<ProfileSwitcherRow> {
  final ScrollController _scrollController = ScrollController();
  bool _canScrollLeft = false;
  bool _canScrollRight = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateFades);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateFades());
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
    final isEn = widget.isEn;
    return SizedBox(
      height: 52,
      child: ShaderMask(
        shaderCallback: (bounds) {
          final leftColor = _canScrollLeft ? Colors.transparent : Colors.white;
          final rightColor =
              _canScrollRight ? Colors.transparent : Colors.white;
          return LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [leftColor, Colors.white, Colors.white, rightColor],
            stops: const [0.0, 0.06, 0.88, 1.0],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              _ProfilePill(
                label: isEn ? 'Me' : 'ตัวฉัน',
                avatarSource: widget.owner.avatarSource,
                avatarBg: widget.owner.avatarBg,
                selected: widget.selectedTargetId == ownerTargetId,
                isOwner: true,
                onTap: () => widget.onSelect(ownerTargetId),
              ),
              for (final cat in widget.cats) ...[
                const SizedBox(width: 8),
                _ProfilePill(
                  label: MyCatL10n.catName(cat.name, isEn),
                  avatarSource: cat.avatarSource,
                  avatarBg: cat.avatarBg,
                  selected: widget.selectedTargetId == cat.id,
                  onTap: () => widget.onSelect(cat.id),
                ),
              ],
              const SizedBox(width: 8),
              _AddCatPill(
                label: isEn ? 'Add cat' : 'เพิ่มแมว',
                onTap: widget.onAddCat,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfilePill extends StatelessWidget {
  const _ProfilePill({
    required this.label,
    required this.avatarSource,
    required this.avatarBg,
    required this.selected,
    required this.onTap,
    this.isOwner = false,
  });

  final String label;
  final String avatarSource;
  final int avatarBg;
  final bool selected;
  final bool isOwner;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bgColor = !selected
        ? AppColors.card
        : (isOwner ? AppColors.ownerPillBg : AppColors.btn);
    final borderColor = !selected
        ? AppColors.line
        : (isOwner ? AppColors.ownerTealRing : AppColors.btnBorder);
    final textColor = !selected
        ? AppColors.text2
        : (isOwner ? AppColors.ownerTeal : AppColors.ink);

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: bgColor,
        shape: StadiumBorder(side: BorderSide(color: borderColor, width: 1.5)),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.fromLTRB(4, 4, 14, 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppAvatar(source: avatarSource, bg: avatarBg, size: 32),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddCatPill extends StatelessWidget {
  const _AddCatPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: AppColors.card,
        shape: const StadiumBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: CustomPaint(
            painter: _DashedStadiumPainter(color: AppColors.addCatDashedBorder),
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.plus,
                    size: 15,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedStadiumPainter extends CustomPainter {
  const _DashedStadiumPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.height / 2),
    );
    final path = Path()..addRRect(rrect);
    const dashWidth = 5.0;
    const dashSpace = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + dashWidth).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedStadiumPainter oldDelegate) =>
      oldDelegate.color != color;
}

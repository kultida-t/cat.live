import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/tag_product_data.dart';
import '../l10n/tag_l10n.dart';
import 'tag_3d_viewer.dart';

/// ส่วน Hero + การ์ดปลอกคอ 6 สี + ใช้ง่ายใน 3 ขั้น + ทั้งบ้านช่วยกันดูแลน้อง (ตรงตามเว็บจริง)
class TagSectionsTop extends StatelessWidget {
  const TagSectionsTop({
    super.key,
    required this.data,
    required this.selectedTagColor,
    required this.selectedCollarColor,
    required this.isEn,
    required this.onSelectTagColor,
    required this.onSelectCollarColor,
  });

  final TagProductData data;
  final TagColorOption selectedTagColor;
  final TagColorOption selectedCollarColor;
  final bool isEn;
  final ValueChanged<String> onSelectTagColor;
  final ValueChanged<String> onSelectCollarColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeroSection(
          tagColors: data.tagColors,
          selectedTagColor: selectedTagColor,
          isEn: isEn,
          onSelectTagColor: onSelectTagColor,
        ),
        const SizedBox(height: 56),
        _CollarMatchCard(
          collarColors: data.collarColors,
          selectedTagColor: Color(selectedTagColor.colorValue),
          selectedCollarColor: selectedCollarColor,
          isEn: isEn,
          onSelectCollarColor: onSelectCollarColor,
        ),
        const SizedBox(height: 68),
        _StepsSection(isEn: isEn),
        const SizedBox(height: 68),
        _FamilySection(isEn: isEn),
      ],
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.tagColors,
    required this.selectedTagColor,
    required this.isEn,
    required this.onSelectTagColor,
  });

  final List<TagColorOption> tagColors;
  final TagColorOption selectedTagColor;
  final bool isEn;
  final ValueChanged<String> onSelectTagColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Text(
          TagL10n.pageTitle(isEn),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.tagTeal,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          TagL10n.heroHeadline(isEn),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 38,
            height: 1.18,
            fontWeight: FontWeight.w800,
            color: AppColors.tagTextDark,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Tag3dViewer(
          mode: Tag3dMode.tagOnly,
          tagColor: Color(selectedTagColor.colorValue),
          height: 276,
        ),
        const SizedBox(height: 18),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          children: tagColors.map((option) {
            final isSelected = option.id == selectedTagColor.id;
            final label = isEn ? option.nameEn : option.nameTh;
            return _ColorDotButton(
              color: Color(option.colorValue),
              size: 36,
              isSelected: isSelected,
              semanticLabel: '${TagL10n.orderSheetTagLabel(isEn)} $label',
              onTap: () => onSelectTagColor(option.id),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            TagL10n.heroCaption(isEn),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15.5,
              height: 1.55,
              color: AppColors.tagTextMuted,
            ),
          ),
        ),
      ],
    );
  }
}

class _CollarMatchCard extends StatefulWidget {
  const _CollarMatchCard({
    required this.collarColors,
    required this.selectedTagColor,
    required this.selectedCollarColor,
    required this.isEn,
    required this.onSelectCollarColor,
  });

  final List<TagColorOption> collarColors;
  final Color selectedTagColor;
  final TagColorOption selectedCollarColor;
  final bool isEn;
  final ValueChanged<String> onSelectCollarColor;

  @override
  State<_CollarMatchCard> createState() => _CollarMatchCardState();
}

class _CollarMatchCardState extends State<_CollarMatchCard> {
  Timer? _cycleTimer;
  bool _userPicked = false;

  @override
  void initState() {
    super.initState();
    _cycleTimer = Timer.periodic(const Duration(milliseconds: 2600), (_) {
      if (_userPicked || !mounted || widget.collarColors.isEmpty) return;
      final currentIndex = widget.collarColors.indexWhere(
        (c) => c.id == widget.selectedCollarColor.id,
      );
      final nextIndex = (currentIndex + 1) % widget.collarColors.length;
      widget.onSelectCollarColor(widget.collarColors[nextIndex].id);
    });
  }

  @override
  void dispose() {
    _cycleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment(0, -0.1),
          radius: 0.95,
          colors: [
            AppColors.card,
            AppColors.tagCollarCardMid,
            AppColors.tagCollarCardEnd,
          ],
          stops: [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.tagCollarCardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.tagTealDeep.withValues(alpha: 0.14),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Tag3dViewer(
            mode: Tag3dMode.collarWithTag,
            tagColor: widget.selectedTagColor,
            collarColor: Color(widget.selectedCollarColor.colorValue),
            height: 224,
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 2,
            children: widget.collarColors.map((option) {
              final isSelected = option.id == widget.selectedCollarColor.id;
              final label = widget.isEn ? option.nameEn : option.nameTh;
              return _ColorDotButton(
                color: Color(option.colorValue),
                size: 28,
                isSelected: isSelected,
                semanticLabel:
                    '${TagL10n.orderSheetCollarLabel(widget.isEn)} $label',
                onTap: () {
                  _userPicked = true;
                  widget.onSelectCollarColor(option.id);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ColorDotButton extends StatelessWidget {
  const _ColorDotButton({
    required this.color,
    required this.size,
    required this.isSelected,
    required this.semanticLabel,
    required this.onTap,
  });

  final Color color;
  final double size;
  final bool isSelected;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: semanticLabel,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: AnimatedScale(
              scale: isSelected ? 1.08 : 1.0,
              duration: const Duration(milliseconds: 160),
              child: Container(
                width: size + (isSelected ? 6 : 0),
                height: size + (isSelected ? 6 : 0),
                padding: EdgeInsets.all(isSelected ? 2.5 : 0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: AppColors.tagTeal, width: 2)
                      : null,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.card, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.tagTextDark.withValues(alpha: 0.12),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepsSection extends StatelessWidget {
  const _StepsSection({required this.isEn});

  final bool isEn;

  @override
  Widget build(BuildContext context) {
    final steps = TagL10n.steps(isEn);
    const icons = [
      LucideIcons.tag,
      LucideIcons.smartphone,
      LucideIcons.mapPin,
    ];

    return Column(
      children: [
        Text(
          TagL10n.stepsTitle(isEn),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.tagTextDark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          TagL10n.stepsSubtitle(isEn),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13.5, color: AppColors.tagTextMuted),
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(steps.length, (i) {
            final (title, desc) = steps[i];
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  children: [
                    SizedBox(
                      width: 62,
                      height: 62,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: AppColors.tagCardMintSoft,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              icons[i],
                              size: 22,
                              color: AppColors.tagTeal,
                            ),
                          ),
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                color: AppColors.tagTeal,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.tagTextDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      desc,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: AppColors.tagTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _FamilySection extends StatelessWidget {
  const _FamilySection({required this.isEn});

  final bool isEn;

  @override
  Widget build(BuildContext context) {
    final cards = TagL10n.familyCards(isEn);

    return Column(
      children: [
        Text(
          TagL10n.familyTitle(isEn),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.tagTextDark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          TagL10n.familySubtitle(isEn),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13.5, color: AppColors.tagTextMuted),
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(cards.length, (i) {
            final (title, desc) = cards[i];
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
                child: Column(
                  children: [
                    _MiniPhoneFrame(
                      bgColor: switch (i) {
                        0 => AppColors.tagBgTop,
                        1 => AppColors.tagCardBlueSoft,
                        _ => null,
                      },
                      bgGradient: i == 2
                          ? const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.catAiMicMid,
                                AppColors.tagTealDeep,
                              ],
                            )
                          : null,
                      child: switch (i) {
                        0 => _FamilyShareMock(isEn: isEn),
                        1 => _FamilyMapMock(isEn: isEn),
                        _ => _FamilyLostMock(isEn: isEn),
                      },
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.tagTextDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      desc,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.tagTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _MiniPhoneFrame extends StatelessWidget {
  const _MiniPhoneFrame({
    required this.child,
    this.bgColor,
    this.bgGradient,
  });

  final Widget child;
  final Color? bgColor;
  final Gradient? bgGradient;

  @override
  Widget build(BuildContext context) {
    // ใช้สัดส่วน 150x300 ย่อลงในกรอบ 88x176 ตรงตามเว็บจริง (84x168)
    return Center(
      child: SizedBox(
        width: 88,
        height: 176,
        child: FittedBox(
          fit: BoxFit.contain,
          child: Container(
            width: 150,
            height: 300,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AppColors.tagPhoneFrame,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: AppColors.tagPhoneFrame.withValues(alpha: 0.14),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                color: bgColor,
                gradient: bgGradient,
                borderRadius: BorderRadius.circular(21),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 7),
                  Container(
                    width: 46,
                    height: 11,
                    decoration: BoxDecoration(
                      color: AppColors.tagPhoneFrame,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                      child: child,
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

class _FamilyShareMock extends StatelessWidget {
  const _FamilyShareMock({required this.isEn});

  final bool isEn;

  @override
  Widget build(BuildContext context) {
    final names = TagL10n.mockCaregiverNames(isEn);
    const dotColors = [
      AppColors.tagCollarPeach,
      AppColors.tagCaregiverBlue,
      AppColors.tagCollarButter,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // รูปปลอกคอ+แท็กสีเขียวมิ้นต์ตรงตามเว็บจริง
        SizedBox(
          width: 72,
          height: 52,
          child: CustomPaint(painter: _MiniGreenCollarTagPainter()),
        ),
        const SizedBox(height: 6),
        Text(
          TagL10n.mockTagTitle(isEn),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.tagTextDark,
          ),
        ),
        Text(
          TagL10n.mockOwnerStatus(isEn),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10, color: AppColors.tagTextMuted),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  TagL10n.mockCoCaregivers(isEn),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.tagTextMuted,
                  ),
                ),
                const SizedBox(height: 8),
                for (var i = 0; i < names.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Row(
                      children: [
                        Container(
                          width: 11,
                          height: 11,
                          decoration: BoxDecoration(
                            color: dotColors[i % dotColors.length],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          flex: 2,
                          child: Text(
                            names[i],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.tagTextDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          flex: 3,
                          child: Text(
                            TagL10n.mockCanViewLocation(isEn),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                              fontSize: 8.5,
                              color: AppColors.tagTextMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniGreenCollarTagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()..color = AppColors.tagColorTeal;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, h * 0.06, w, h * 0.24),
        const Radius.circular(3),
      ),
      paint,
    );
    final tx = w * 0.24;
    final ty = h * 0.22;
    final tw = w * 0.52;
    final th = h * 0.72;
    final path = Path()
      ..moveTo(tx + tw * 0.24, ty + th * 0.22)
      ..quadraticBezierTo(tx + tw * 0.12, ty + th * 0.02, tx + tw * 0.06, ty + th * 0.18)
      ..quadraticBezierTo(tx, ty + th * 0.42, tx + tw * 0.02, ty + th * 0.56)
      ..cubicTo(
        tx + tw * 0.04,
        ty + th * 1.02,
        tx + tw * 0.96,
        ty + th * 1.02,
        tx + tw * 0.98,
        ty + th * 0.56,
      )
      ..quadraticBezierTo(tx + tw, ty + th * 0.42, tx + tw * 0.94, ty + th * 0.18)
      ..quadraticBezierTo(tx + tw * 0.88, ty + th * 0.02, tx + tw * 0.76, ty + th * 0.22)
      ..quadraticBezierTo(tx + tw * 0.5, ty + th * 0.28, tx + tw * 0.24, ty + th * 0.22)
      ..close();
    canvas.drawPath(path, paint);
    canvas.drawCircle(
      Offset(w * 0.50, ty + th * 0.60),
      tw * 0.26,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(w * 0.50, ty + th * 0.60),
      tw * 0.09,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FamilyMapMock extends StatelessWidget {
  const _FamilyMapMock({required this.isEn});

  final bool isEn;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: CustomPaint(painter: _MiniMapGridPainter()),
          ),
        ),
        Positioned(
          right: 26,
          top: 44,
          child: Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              color: AppColors.tagMapUserDot,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
        Center(
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.tagCollarPeach,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
            ),
            child: Center(
              child: Text(
                TagL10n.mockMapPinShort(isEn),
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 6,
          right: 6,
          bottom: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  TagL10n.sampleCatName(isEn),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.tagTextDark,
                  ),
                ),
                Text(
                  TagL10n.mockMapTime(isEn),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.tagTextMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniMapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.tagCardBlueSoft,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.08, size.height * 0.08, 42, 48),
        const Radius.circular(6),
      ),
      Paint()..color = AppColors.tagMapBuildingGreen,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.56, size.height * 0.42, 48, 52),
        const Radius.circular(6),
      ),
      Paint()..color = AppColors.tagMapBuildingBlue,
    );

    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 6;
    canvas.drawLine(
      Offset(0, size.height * 0.36),
      Offset(size.width, size.height * 0.28),
      road,
    );
    canvas.drawLine(
      Offset(size.width * 0.52, 0),
      Offset(size.width * 0.38, size.height),
      road,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FamilyLostMock extends StatelessWidget {
  const _FamilyLostMock({required this.isEn});

  final bool isEn;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 6),
        Text(
          TagL10n.mockLostModeBadge(isEn),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.78),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          TagL10n.mockLostModeHeading(isEn),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const Spacer(),
        SizedBox(
          width: 96,
          height: 96,
          child: Stack(
            alignment: Alignment.center,
            children: [
              for (final d in [96.0, 68.0, 42.0])
                Container(
                  width: d,
                  height: d,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                ),
              Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        _MiniDarkChip(
          icon: LucideIcons.bell,
          label: TagL10n.mockNotifiedCaregivers(isEn),
        ),
        const SizedBox(height: 5),
        _MiniDarkChip(
          icon: LucideIcons.search,
          label: TagL10n.mockNearbyHelp(isEn),
        ),
      ],
    );
  }
}

class _MiniDarkChip extends StatelessWidget {
  const _MiniDarkChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          Icon(icon, size: 11, color: Colors.white),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 9.5, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

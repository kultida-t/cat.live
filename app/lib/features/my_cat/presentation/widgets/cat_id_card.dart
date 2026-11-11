import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr/qr.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_image.dart';
import '../../domain/entities/my_cat_data.dart';
import 'my_cat_l10n.dart';

/// ชุดสีของบัตร Cat ID ทั้ง 7 ธีม ตรงตามเว็บ www.แมว.live/my-cat/profile
class CatIdSkinStyle {
  const CatIdSkinStyle({
    required this.swatch,
    required this.gradientColors,
    required this.gradientStops,
    required this.cardText,
    required this.accent,
    required this.pillText,
    required this.dashedAndWatermark,
  });

  final Color swatch;
  final List<Color> gradientColors;
  final List<double> gradientStops;
  final Color cardText;
  final Color accent;
  final Color pillText;
  final Color dashedAndWatermark;

  static CatIdSkinStyle of(CatIdSkin skin) {
    return switch (skin) {
      CatIdSkin.honey => const CatIdSkinStyle(
        swatch: Color(0xFFFFE89A),
        gradientColors: [
          Color(0xFFFFF3C4),
          Color(0xFFFFE89A),
          Color(0xFFF6D77A),
        ],
        gradientStops: [0.0, 0.55, 1.0],
        cardText: Color(0xFF4A3428),
        accent: Color(0xFF6E4B00),
        pillText: Color(0xFF6E4B00),
        dashedAndWatermark: Color(0x386E4B00),
      ),
      CatIdSkin.peach => const CatIdSkinStyle(
        swatch: Color(0xFFFFD0AE),
        gradientColors: [
          Color(0xFFFFE8D6),
          Color(0xFFFFD0AE),
          Color(0xFFF7B98A),
        ],
        gradientStops: [0.0, 0.55, 1.0],
        cardText: Color(0xFF4A2A16),
        accent: Color(0xFF8A3A10),
        pillText: Color(0xFF8A3A10),
        dashedAndWatermark: Color(0x388A3A10),
      ),
      CatIdSkin.mint => const CatIdSkinStyle(
        swatch: Color(0xFFBFE9E0),
        gradientColors: [
          Color(0xFFE6F7F3),
          Color(0xFFC9EEE6),
          Color(0xFFA9DCD3),
        ],
        gradientStops: [0.0, 0.55, 1.0],
        cardText: Color(0xFF1F3B37),
        accent: Color(0xFF0B5E58),
        pillText: Color(0xFF0B5E58),
        dashedAndWatermark: Color(0x380B5E58),
      ),
      CatIdSkin.sky => const CatIdSkinStyle(
        swatch: Color(0xFFCFE3FF),
        gradientColors: [
          Color(0xFFEEF4FF),
          Color(0xFFD6E4FA),
          Color(0xFFB5C8EC),
        ],
        gradientStops: [0.0, 0.55, 1.0],
        cardText: Color(0xFF1F2E4D),
        accent: Color(0xFF5A4030),
        pillText: Color(0xFF5A4030),
        dashedAndWatermark: Color(0x385A4030),
      ),
      CatIdSkin.lavender => const CatIdSkinStyle(
        swatch: Color(0xFFE3D8FA),
        gradientColors: [
          Color(0xFFF4EFFD),
          Color(0xFFE3D8FA),
          Color(0xFFC9B9F2),
        ],
        gradientStops: [0.0, 0.55, 1.0],
        cardText: Color(0xFF2E2450),
        accent: Color(0xFF5B2DB0),
        pillText: Color(0xFF5B2DB0),
        dashedAndWatermark: Color(0x335B2DB0),
      ),
      CatIdSkin.pink => const CatIdSkinStyle(
        swatch: Color(0xFFFBD3E1),
        gradientColors: [
          Color(0xFFFFF0F5),
          Color(0xFFFBD9E5),
          Color(0xFFF2B5CB),
        ],
        gradientStops: [0.0, 0.55, 1.0],
        cardText: Color(0xFF4A2433),
        accent: Color(0xFF9C2452),
        pillText: Color(0xFF9C2452),
        dashedAndWatermark: Color(0x339C2452),
      ),
      CatIdSkin.night => const CatIdSkinStyle(
        swatch: Color(0xFF2A303D),
        gradientColors: [
          Color(0xFF3B4254),
          Color(0xFF2A303D),
          Color(0xFF1E222C),
        ],
        gradientStops: [0.0, 0.60, 1.0],
        cardText: Colors.white,
        accent: Color(0xFFC9D2E3),
        pillText: Color(0xFF2A303D),
        dashedAndWatermark: Color(0x2EFFFFFF),
      ),
    };
  }

  LinearGradient get linearGradient => LinearGradient(
    begin: const Alignment(-0.34, -0.94),
    end: const Alignment(0.34, 0.94),
    colors: gradientColors,
    stops: gradientStops,
  );
}

/// บัตรประจำตัวแมวดิจิทัลพร้อมหูแมว ลายน้ำรอยเท้าทึบ ข้อมูลสุขภาพ และ QR โปรไฟล์สาธารณะ
class CatIdCard extends StatelessWidget {
  const CatIdCard({
    super.key,
    required this.cat,
    required this.ownerHandle,
    required this.skin,
    this.isEn = false,
  });

  final CatProfile cat;
  final String ownerHandle;
  final CatIdSkin skin;
  final bool isEn;

  @override
  Widget build(BuildContext context) {
    final style = CatIdSkinStyle.of(skin);
    final details = cat.idCard;
    final catName = MyCatL10n.catName(cat.name, isEn);
    final birthOrAge = details.birthDateLabel.isNotEmpty
        ? MyCatL10n.thaiDate(details.birthDateLabel, isEn)
        : MyCatL10n.age(cat.ageLabel, isEn);
    final watchText = MyCatL10n.watchNote(details.watchNote, isEn);
    final qrUrl = AppConfig.catProfileUrl(cat.publicId);

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.only(top: 17),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // เงาใต้บัตรแยกชั้นไว้ด้านหลังหูแมว เพื่อไม่ให้เงาตัดผ่านโคนหูด้านบน
            Positioned(
              top: 18,
              left: 6,
              right: 6,
              bottom: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x524A3428),
                      blurRadius: 24,
                      spreadRadius: -4,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
              ),
            ),
            // หูแมวซ้าย-ขวาด้านบนของบัตร (ตัดส่วนเกินใต้ขอบบนบัตรออกเพื่อไม่ให้แว็บหรือซ้อน)
            Positioned(
              top: -24,
              left: 0,
              right: 0,
              height: 25,
              child: ClipRect(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(top: 7, left: 40, child: _CatEar(style: style)),
                    Positioned(top: 7, right: 40, child: _CatEar(style: style)),
                  ],
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                gradient: style.linearGradient,
                borderRadius: BorderRadius.circular(28),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  // ลายน้ำรอยเท้าแมวแบบทึบมุมขวาล่าง ตรงกับ SVG เว็บจริง
                  Positioned(
                    right: -32,
                    bottom: -40,
                    child: IgnorePointer(
                      child: Transform.rotate(
                        angle: -12 * math.pi / 180,
                        child: _FilledPawIcon(
                          size: 176,
                          color: style.dashedAndWatermark,
                        ),
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    layoutBuilder: (currentChild, previousChildren) {
                      return Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          for (final prev in previousChildren)
                            IgnorePointer(child: prev),
                          ?currentChild,
                        ],
                      );
                    },
                    child: Column(
                      key: ValueKey('${cat.id}-${skin.name}-$isEn'),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ส่วนหัวบัตร
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isEn ? 'Cat ID Card' : 'บัตรประจำตัวแมว',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: style.cardText,
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      'CAT ID CARD · แมว.live',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 2.0,
                                        color: style.accent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                LucideIcons.nfc,
                                size: 22,
                                color: style.accent,
                              ),
                            ],
                          ),
                        ),
                        _DashedDivider(color: style.dashedAndWatermark),
                        // รูปโปรไฟล์ + ป้ายรอยเท้าทึบ + ชื่อ + รหัส ID
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          child: Row(
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: 104,
                                    height: 104,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 3,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x334A3428),
                                          blurRadius: 10,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(21),
                                      child: AppImage(source: cat.avatarSource),
                                    ),
                                  ),
                                  Positioned(
                                    right: -8,
                                    bottom: -8,
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      alignment: Alignment.center,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Color(0x334A3428),
                                            blurRadius: 6,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const _FilledPawIcon(
                                        size: 18,
                                        color: Color(0xFFC9892B),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      catName,
                                      style: TextStyle(
                                        fontSize: 26,
                                        height: 1.2,
                                        fontWeight: FontWeight.w700,
                                        color: style.cardText,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0x8CFFFFFF),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Text(
                                        cat.publicId,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1.4,
                                          color: style.pillText,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // ข้อมูลพื้นฐาน 3x2
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 10,
                                    child: _CardField(
                                      label: isEn ? 'Breed' : 'สายพันธุ์',
                                      value: MyCatL10n.breed(cat.breed, isEn),
                                      maxLines: 1,
                                      style: style,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 13,
                                    child: _CardField(
                                      label: isEn ? 'Color' : 'สี',
                                      value: MyCatL10n.coatColor(
                                        details.coatColor,
                                        isEn,
                                      ),
                                      maxLines: 1,
                                      style: style,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 6,
                                    child: _CardField(
                                      label: isEn ? 'Sex' : 'เพศ',
                                      value: MyCatL10n.genderShort(
                                        cat.gender,
                                        isEn,
                                      ),
                                      maxLines: 1,
                                      style: style,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 10,
                                    child: _CardField(
                                      label: isEn ? 'Neutered' : 'ทำหมัน',
                                      value: MyCatL10n.neuteredShort(
                                        cat.neutered,
                                        isEn,
                                      ),
                                      maxLines: 1,
                                      style: style,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 13,
                                    child: _CardField(
                                      label: isEn ? 'Birthdate' : 'วันเกิด',
                                      value: birthOrAge,
                                      maxLines: 1,
                                      style: style,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 6,
                                    child: _CardField(
                                      label: isEn ? 'Weight' : 'น้ำหนัก',
                                      value: isEn
                                          ? '${cat.weightText} kg'
                                          : '${cat.weightText} กก.',
                                      maxLines: 1,
                                      style: style,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // ส่วนข้อมูลสุขภาพ
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _DashedDivider(color: style.dashedAndWatermark),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Text(
                                    isEn ? 'Health' : 'สุขภาพ',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: style.accent,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0x8CFFFFFF),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: _healthDotColor(
                                              cat.healthBadge,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          MyCatL10n.healthStatusBadge(
                                            cat.healthBadge,
                                            isEn,
                                          ),
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            color: style.pillText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _CardField(
                                      label: isEn
                                          ? 'Last vaccine'
                                          : 'วัคซีนล่าสุด',
                                      value: MyCatL10n.thaiDate(
                                        details.lastVaccineDate,
                                        isEn,
                                      ),
                                      subValue:
                                          details.lastVaccineName.isNotEmpty
                                          ? details.lastVaccineName
                                          : null,
                                      style: style,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _CardField(
                                      label: isEn
                                          ? 'Next due'
                                          : 'ครบกำหนดครั้งถัดไป',
                                      value: MyCatL10n.thaiDate(
                                        details.nextDueDate,
                                        isEn,
                                      ),
                                      subValue: details.nextDueDetail.isNotEmpty
                                          ? MyCatL10n.nextDueDetail(
                                              details.nextDueDetail,
                                              isEn,
                                            )
                                          : null,
                                      style: style,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _DashedDivider(color: style.dashedAndWatermark),
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _CardField(
                                      label: isEn ? 'Blood type' : 'กรุ๊ปเลือด',
                                      value: MyCatL10n.bloodType(
                                        details.bloodType,
                                        isEn,
                                      ),
                                      style: style,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _CardField(
                                      label: isEn
                                          ? 'Allergies'
                                          : 'แพ้ยา / อาหาร',
                                      value: MyCatL10n.allergy(
                                        details.allergy,
                                        isEn,
                                      ),
                                      style: style,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _CardField(
                                label: isEn
                                    ? 'Chronic conditions'
                                    : 'โรคประจำตัว',
                                value: MyCatL10n.chronicConditions(
                                  details.chronicConditions,
                                  isEn,
                                ),
                                valueSize: 13,
                                style: style,
                              ),
                              if (watchText.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                _CardField(
                                  label: isEn
                                      ? 'Symptoms to watch'
                                      : 'อาการที่ต้องติดตาม',
                                  value: watchText,
                                  valueSize: 13,
                                  style: style,
                                ),
                              ],
                            ],
                          ),
                        ),
                        // ส่วนท้ายบัตร: ไมโครชิป + ผู้ดูแลหลัก + วันออกบัตร + QR
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                          child: Column(
                            children: [
                              _DashedDivider(color: style.dashedAndWatermark),
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isEn ? 'Microchip' : 'ไมโครชิป',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                            color: style.accent,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          isEn
                                              ? '•••• •••• [Number]'
                                              : '•••• •••• [หมายเลข]',
                                          style: TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 13,
                                            letterSpacing: 0.8,
                                            color: style.cardText,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          isEn
                                              ? 'Primary caregiver'
                                              : 'ผู้ดูแลหลัก',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                            color: style.accent,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          ownerHandle,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: style.cardText,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          isEn
                                              ? 'Issued ${MyCatL10n.thaiDate(details.issuedDateLabel, true)}'
                                              : 'ออกบัตร ${details.issuedDateLabel}',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            color: style.accent,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Semantics(
                                    image: true,
                                    label: isEn
                                        ? 'QR to public profile of $catName'
                                        : 'QR ไปหน้าโปรไฟล์สาธารณะของ$catName',
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x264A3428),
                                            blurRadius: 8,
                                            offset: Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: CatIdQrMatrix(
                                        data: qrUrl,
                                        size: 80,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Color _healthDotColor(CatHealthBadge badge) {
    return switch (badge) {
      CatHealthBadge.good => const Color(0xFF3BA55C),
      CatHealthBadge.watch => const Color(0xFFE0A82E),
      CatHealthBadge.poor => const Color(0xFFD9654F),
    };
  }
}

/// ไอคอนรอยเท้าแมวแบบทึบตาม SVG ของเว็บจริง (viewBox 0 0 32 32, 5 วงรี)
class _FilledPawIcon extends StatelessWidget {
  const _FilledPawIcon({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _FilledPawPainter(color: color)),
    );
  }
}

class _FilledPawPainter extends CustomPainter {
  const _FilledPawPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 32.0;
    final sy = size.height / 32.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    void oval(double cx, double cy, double rx, double ry) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx * sx, cy * sy),
          width: rx * 2 * sx,
          height: ry * 2 * sy,
        ),
        paint,
      );
    }

    oval(16, 21.5, 7.2, 6);
    oval(6.5, 13.5, 3, 3.8);
    oval(12, 7.5, 3, 3.9);
    oval(20, 7.5, 3, 3.9);
    oval(25.5, 13.5, 3, 3.8);
  }

  @override
  bool shouldRepaint(_FilledPawPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _CatEar extends StatelessWidget {
  const _CatEar({required this.style});

  final CatIdSkinStyle style;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Transform.rotate(
        angle: math.pi / 4,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: style.linearGradient,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(12)),
          ),
        ),
      ),
    );
  }
}

class _CardField extends StatelessWidget {
  const _CardField({
    required this.label,
    required this.value,
    required this.style,
    this.subValue,
    this.valueSize = 13.5,
    this.maxLines,
  });

  final String label;
  final String value;
  final String? subValue;
  final CatIdSkinStyle style;
  final double valueSize;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: style.accent,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          maxLines: maxLines,
          overflow: maxLines != null ? TextOverflow.ellipsis : null,
          style: TextStyle(
            fontSize: valueSize,
            height: 1.35,
            fontWeight: FontWeight.w600,
            color: style.cardText,
          ),
        ),
        if (subValue != null)
          Text(
            subValue!,
            style: TextStyle(fontSize: 11.5, color: style.accent),
          ),
      ],
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1.5,
      width: double.infinity,
      child: CustomPaint(painter: _DashedLinePainter(color: color)),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.butt;
    const dashWidth = 4.5;
    const dashSpace = 3.5;
    var x = 0.0;
    while (x < size.width) {
      final end = math.min(x + dashWidth, size.width);
      canvas.drawLine(Offset(x, 0.75), Offset(end, 0.75), paint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

/// วาด QR Code จริงด้วยสีน้ำตาลเข้ม #4A3428 บนพื้นขาว (แคชผลลัพธ์ไว้ไม่คำนวณซ้ำตอนแอนิเมชัน)
class CatIdQrMatrix extends StatefulWidget {
  const CatIdQrMatrix({super.key, required this.data, this.size = 80});

  final String data;
  final double size;

  @override
  State<CatIdQrMatrix> createState() => _CatIdQrMatrixState();
}

class _CatIdQrMatrixState extends State<CatIdQrMatrix> {
  late QrImage _qrImage;

  @override
  void initState() {
    super.initState();
    _qrImage = _buildQr(widget.data);
  }

  @override
  void didUpdateWidget(CatIdQrMatrix oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _qrImage = _buildQr(widget.data);
    }
  }

  static QrImage _buildQr(String data) {
    final qrCode = QrCode(
      payload: QrPayload.fromString(data),
      errorCorrectLevel: QrErrorCorrectLevel.low,
    );
    return QrImage(qrCode);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(painter: _QrPainter(qrImage: _qrImage)),
    );
  }
}

class _QrPainter extends CustomPainter {
  const _QrPainter({required this.qrImage});

  final QrImage qrImage;

  @override
  void paint(Canvas canvas, Size size) {
    final count = qrImage.moduleCount;
    final cell = size.width / count;
    final darkPaint = Paint()..color = AppColors.text;

    for (var r = 0; r < count; r++) {
      for (var c = 0; c < count; c++) {
        if (qrImage.isDark(r, c)) {
          canvas.drawRect(
            Rect.fromLTWH(c * cell, r * cell, cell + 0.2, cell + 0.2),
            darkPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_QrPainter oldDelegate) => oldDelegate.qrImage != qrImage;
}

/// แถบเลือกสีบัตร Cat ID ทั้ง 7 สีพร้อมวงแหวนคู่รอบสีที่เลือก
class CatIdSkinSelector extends StatelessWidget {
  const CatIdSkinSelector({
    super.key,
    required this.selected,
    required this.onSelect,
    this.isEn = false,
  });

  final CatIdSkin selected;
  final ValueChanged<CatIdSkin> onSelect;
  final bool isEn;

  @override
  Widget build(BuildContext context) {
    final skinLabel = MyCatL10n.skinLabel(selected, isEn);
    return Column(
      children: [
        Text(
          isEn ? 'Card color · $skinLabel' : 'สีบัตร · $skinLabel',
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.text2,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final skin in CatIdSkin.values)
              _SkinSwatchButton(
                skin: skin,
                selected: skin == selected,
                isEn: isEn,
                onTap: () => onSelect(skin),
              ),
          ],
        ),
      ],
    );
  }
}

class _SkinSwatchButton extends StatelessWidget {
  const _SkinSwatchButton({
    required this.skin,
    required this.selected,
    required this.isEn,
    required this.onTap,
  });

  final CatIdSkin skin;
  final bool selected;
  final bool isEn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = CatIdSkinStyle.of(skin);
    final label = MyCatL10n.skinLabel(skin, isEn);

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: style.swatch,
              border: Border.all(
                color: selected ? AppColors.page : const Color(0x1A000000),
                width: selected ? 2 : 1,
              ),
              boxShadow: selected
                  ? const [
                      BoxShadow(
                        color: AppColors.ink,
                        spreadRadius: 2,
                        blurRadius: 0,
                      ),
                    ]
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

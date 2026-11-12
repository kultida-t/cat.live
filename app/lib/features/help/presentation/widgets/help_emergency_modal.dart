import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/help_data.dart';
import 'help_l10n.dart';

/// ป๊อปอัปฉุกเฉิน: 6 อาการวิกฤต <-> รายการ รพ.สัตว์ใกล้คุณ (เมื่อกด โทรด่วน · รพ.สัตว์ใกล้ฉัน)
Future<void> showHelpEmergencyModal({
  required BuildContext context,
  required List<EmergencySymptom> symptoms,
  required EmergencyHospital hospital,
  required bool isEn,
  required ValueChanged<String> onCallPhone,
  required ValueChanged<String> onNavigateQuery,
  required VoidCallback onViewOnMap,
  required VoidCallback onAskCatAi,
}) {
  const symptomVisuals = [
    (icon: LucideIcons.wind, bg: Color(0xFFDBEAFE), color: Color(0xFF1D4ED8)),
    (icon: LucideIcons.zap, bg: Color(0xFFFEF3C7), color: Color(0xFFB45309)),
    (icon: LucideIcons.droplet, bg: Color(0xFFDDF2EE), color: Color(0xFF0F766E)),
    (icon: LucideIcons.pill, bg: Color(0xFFEDE9FE), color: Color(0xFF6D28D9)),
    (icon: LucideIcons.heartPulse, bg: Color(0xFFFCE7F3), color: Color(0xFFBE185D)),
    (icon: LucideIcons.car, bg: Color(0xFFFFEDD5), color: Color(0xFFC2410C)),
  ];

  final clinics = [
    (
      nameTh: 'รพ.สัตว์ทองหล่อ 24 ชม.',
      nameEn: 'Thonglor Pet Hospital 24h',
      statusTh: 'เปิด 24 ชม. · 0.6 กม.',
      statusEn: 'Open 24 hrs · 0.6 km',
      is24h: true,
      phone: hospital.phone,
    ),
    (
      nameTh: 'โรงพยาบาลสัตว์ปากซอย 24 ชม.',
      nameEn: 'Pak Soi Animal Hospital 24h',
      statusTh: 'เปิด 24 ชม. · 1.2 กม.',
      statusEn: 'Open 24 hrs · 1.2 km',
      is24h: true,
      phone: '02-012-3456',
    ),
    (
      nameTh: 'คลินิกสัตว์ลาดพร้าว 24 ชม.',
      nameEn: 'Lat Phrao Vet Clinic 24h',
      statusTh: 'เปิด 24 ชม. · 1.8 กม.',
      statusEn: 'Open 24 hrs · 1.8 km',
      is24h: true,
      phone: '02-088-7766',
    ),
    (
      nameTh: 'คลินิกรักษ์แมว',
      nameEn: 'Rak Maew Vet Clinic',
      statusTh: 'เปิดอยู่ · ปิด 20:00 · 0.8 กม.',
      statusEn: 'Open · Closes 20:00 · 0.8 km',
      is24h: false,
      phone: '02-045-9911',
    ),
  ];

  return showDialog<void>(
    context: context,
    barrierColor: AppColors.sheetBarrier,
    builder: (dialogCtx) {
      var showClinics = false;

      return StatefulBuilder(
        builder: (ctx, setModalState) => Dialog(
          backgroundColor: AppColors.card,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          LucideIcons.siren,
                          color: Color(0xFFC8372D),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          showClinics
                              ? HelpL10n.nearbyClinicsTitle(isEn)
                              : HelpL10n.emergencyModalTitle(isEn),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: showClinics
                                ? const Color(0xFF8F1C13)
                                : const Color(0xFF2C1810),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        icon: const Icon(LucideIcons.x, size: 20),
                        color: AppColors.muted,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (!showClinics) ...[
                    Text(
                      HelpL10n.emergencySymptomsHeading(isEn),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Column(
                        children: [
                          for (var i = 0; i < symptoms.length; i++) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 9,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: symptomVisuals[
                                              i % symptomVisuals.length]
                                          .bg,
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    child: Icon(
                                      symptomVisuals[i % symptomVisuals.length]
                                          .icon,
                                      size: 16,
                                      color: symptomVisuals[
                                              i % symptomVisuals.length]
                                          .color,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      symptoms[i].title(isEn),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF2C1810),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (i < symptoms.length - 1)
                              const Divider(height: 1, color: AppColors.line),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      HelpL10n.emergencyNearestHospitalLabel(isEn),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2C1810),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF5F5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  hospital.name(isEn),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2C1810),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${HelpL10n.distanceText(hospital.distanceKm, isEn)} · ${hospital.hours(isEn)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF7E6E65),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () {
                              Navigator.pop(dialogCtx);
                              onNavigateQuery(hospital.name(isEn));
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF2C1810),
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFFFCA5A5)),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              minimumSize: Size.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            child: Text(
                              HelpL10n.navigateLabel(isEn),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () =>
                            setModalState(() => showClinics = true),
                        icon: const Icon(LucideIcons.phone, size: 17),
                        label: Text(HelpL10n.callEmergencyNow(isEn)),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFC8372D),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () {
                              Navigator.pop(dialogCtx);
                              onViewOnMap();
                            },
                            icon: const Icon(LucideIcons.mapPin, size: 15),
                            label: Text(HelpL10n.viewOnMapLabel(isEn)),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF3D2314),
                              textStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () {
                              Navigator.pop(dialogCtx);
                              onAskCatAi();
                            },
                            icon: const Icon(LucideIcons.sparkles, size: 15),
                            label: Text(HelpL10n.askCatAiLabel(isEn)),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF3D2314),
                              textStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // มุมมองรายการ รพ.สัตว์ใกล้คุณ
                    InkWell(
                      onTap: () => setModalState(() => showClinics = false),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.chevronLeft,
                              size: 16,
                              color: Color(0xFF3D2314),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              HelpL10n.backToSymptoms(isEn),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF3D2314),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final clinic in clinics) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCF9F6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isEn ? clinic.nameEn : clinic.nameTh,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF2C1810),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isEn ? clinic.statusEn : clinic.statusTh,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: clinic.is24h
                                          ? const Color(0xFF0F766E)
                                          : AppColors.muted,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pop(dialogCtx);
                                      onNavigateQuery(
                                        isEn ? clinic.nameEn : clinic.nameTh,
                                      );
                                    },
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          LucideIcons.navigation,
                                          size: 12,
                                          color: Color(0xFF3D2314),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          HelpL10n.navigateLabel(isEn),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF3D2314),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              onPressed: () {
                                Navigator.pop(dialogCtx);
                                onCallPhone(clinic.phone);
                              },
                              icon: const Icon(LucideIcons.phone, size: 15),
                              label: Text(HelpL10n.callButton(isEn)),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFC8372D),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        HelpL10n.clinicFootnote(isEn),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

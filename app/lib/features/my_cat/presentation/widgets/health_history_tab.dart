import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/cat_health_data.dart';
import 'health_shared_widgets.dart';

/// แท็บ 1: ประวัติสุขภาพ — การ์ดนัดถัดไปและไทม์ไลน์แนวตั้งเทียบตรงเว็บ www.แมว.live
class HealthHistoryTab extends StatelessWidget {
  const HealthHistoryTab({
    super.key,
    required this.healthBook,
    required this.isEn,
    required this.onFindClinic,
    required this.onAddRecord,
  });

  final CatHealthBook healthBook;
  final bool isEn;
  final VoidCallback onFindClinic;
  final VoidCallback onAddRecord;

  @override
  Widget build(BuildContext context) {
    final next = healthBook.nextAppointment;
    final records = healthBook.records;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (next != null) ...[
          _NextAppointmentCard(
            appointment: next,
            isEn: isEn,
            onFindClinic: onFindClinic,
          ),
          const SizedBox(height: 16),
        ],
        if (records.isEmpty)
          HealthEmptyStateCard(
            icon: LucideIcons.clipboardList,
            title: isEn ? 'No health records yet' : 'ยังไม่มีบันทึกสุขภาพ',
            subtitle: isEn
                ? 'Tap "+ Add note" below to start logging visits, vaccines, or symptoms.'
                : 'แตะ "+ เพิ่มบันทึก" ด้านล่างเพื่อเริ่มจดอาการ วัคซีน หรือการตรวจสุขภาพ',
          )
        else
          for (var i = 0; i < records.length; i++)
            _TimelineEntryRow(
              entry: records[i],
              isEn: isEn,
              isFirst: i == 0,
              isLast: i == records.length - 1,
            ),
        const SizedBox(height: 14),
        HealthOutlinedActionButton(
          icon: LucideIcons.plus,
          label: isEn ? 'Add note' : 'เพิ่มบันทึก',
          backgroundColor: AppColors.btn,
          borderColor: AppColors.btnBorder,
          foregroundColor: AppColors.ink,
          onPressed: onAddRecord,
        ),
      ],
    );
  }
}

class _NextAppointmentCard extends StatelessWidget {
  const _NextAppointmentCard({
    required this.appointment,
    required this.isEn,
    required this.onFindClinic,
  });

  final HealthNextAppointment appointment;
  final bool isEn;
  final VoidCallback onFindClinic;

  @override
  Widget build(BuildContext context) {
    final date = isEn ? appointment.dateEn : appointment.dateTh;
    final remaining = isEn
        ? 'in ${appointment.daysLeft} days'
        : 'อีก ${appointment.daysLeft} วัน';
    return HealthCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            constraints: const BoxConstraints(minWidth: 52),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8F0),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.btnBorder),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${appointment.daysLeft}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isEn ? 'days' : 'วัน',
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEn ? 'Next appointment' : 'นัดถัดไป',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  isEn ? appointment.titleEn : appointment.titleTh,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$date · $remaining',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: onFindClinic,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 38),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              backgroundColor: AppColors.card,
              foregroundColor: AppColors.text,
              side: const BorderSide(color: AppColors.btnBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              isEn ? 'Find a clinic' : 'หาคลินิก',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineEntryRow extends StatelessWidget {
  const _TimelineEntryRow({
    required this.entry,
    required this.isEn,
    required this.isFirst,
    required this.isLast,
  });

  final HealthRecordEntry entry;
  final bool isEn;
  final bool isFirst;
  final bool isLast;

  ({Color dot, String categoryText}) _categoryStyle() {
    final isBloodTest =
        entry.noteTh == 'ตรวจเลือด' || entry.noteEn == 'Blood test';
    if (isBloodTest || entry.category == HealthRecordCategory.bloodTest) {
      return (
        dot: const Color(0xFFA78BFA),
        categoryText: isEn ? 'Blood test' : 'ตรวจเลือด',
      );
    }
    return switch (entry.category) {
      HealthRecordCategory.bloodTest => (
        dot: const Color(0xFFA78BFA),
        categoryText: isEn ? 'Blood test' : 'ตรวจเลือด',
      ),
      HealthRecordCategory.illness => (
        dot: const Color(0xFFEE8FAE),
        categoryText: isEn ? 'Illness' : 'อาการป่วย',
      ),
      HealthRecordCategory.checkup => (
        dot: const Color(0xFFE6B83A),
        categoryText: isEn ? 'Checkup' : 'ตรวจประจำปี',
      ),
      HealthRecordCategory.deworming => (
        dot: const Color(0xFF4DB8A4),
        categoryText: isEn ? 'Deworming' : 'ถ่ายพยาธิ',
      ),
      HealthRecordCategory.vaccine => (
        dot: AppColors.healthVaccineBlue,
        categoryText: isEn ? 'Vaccine' : 'วัคซีน',
      ),
      HealthRecordCategory.surgery => (
        dot: const Color(0xFF8F7058),
        categoryText: isEn ? 'Surgery' : 'ผ่าตัด',
      ),
      HealthRecordCategory.weight => (
        dot: AppColors.healthDewormTeal,
        categoryText: isEn ? 'Weight' : 'น้ำหนัก',
      ),
      HealthRecordCategory.other => (
        dot: AppColors.muted,
        categoryText: isEn ? 'Other' : 'อื่น ๆ',
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final style = _categoryStyle();
    final date = isEn ? entry.dateEn : entry.dateTh;
    final title = isEn ? entry.titleEn : entry.titleTh;
    final details = isEn ? entry.detailsEn : entry.detailsTh;
    final source = isEn ? entry.sourceEn : entry.sourceTh;
    final isCatAi =
        source.contains('Cat AI') || entry.sourceTh.contains('Cat AI');

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 22,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Positioned(
                  top: isFirst ? 22 : 0,
                  bottom: isLast ? null : 0,
                  height: isLast ? 22 : null,
                  child: Container(width: 1.5, color: AppColors.line),
                ),
                Positioned(
                  top: 18,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: style.dot,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: HealthCard(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                borderRadius: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '$date · ',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.muted,
                                  ),
                                ),
                                TextSpan(
                                  text: style.categoryText,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: style.dot,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (source.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isCatAi
                                  ? const Color(0xFFEDE9FE)
                                  : const Color(0xFFD5F0EB),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isCatAi
                                      ? LucideIcons.sparkles
                                      : LucideIcons.fileText,
                                  size: 12,
                                  color: isCatAi
                                      ? const Color(0xFF5B21B6)
                                      : AppColors.ownerTeal,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  source,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: isCatAi
                                        ? const Color(0xFF5B21B6)
                                        : AppColors.ownerTeal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    if (details.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        details,
                        style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.38,
                          color: AppColors.text2,
                        ),
                      ),
                    ],
                    if (entry.treatmentTh.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        isEn ? entry.treatmentEn : entry.treatmentTh,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.healthMedPurple,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

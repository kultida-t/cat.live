import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/cat_health_data.dart';
import 'health_shared_widgets.dart';

const _svgMedicine = '''
<svg viewBox="0 0 24 24" fill="none" stroke="#4A3428" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><g transform="rotate(-40 12 12)"><path d="M12 8.2H8a3.8 3.8 0 0 0 0 7.6h4z" fill="#FFD95A"/><path d="M12 8.2h4a3.8 3.8 0 0 1 0 7.6h-4z" fill="#F7A8C2"/></g><path d="M6.7 9.2c.4-.7 1-1.1 1.8-1.3" stroke-width="1.2" stroke="#FFFFFF"/></svg>
''';

/// แท็บ 4: รายการยา — หัวข้อ "ยาที่ใช้" นอกการ์ด + สถานะตัวอักษรล้วนตรงเว็บ www.แมว.live
class HealthMedicineTab extends StatelessWidget {
  const HealthMedicineTab({
    super.key,
    required this.medications,
    required this.isEn,
    required this.onAddMedication,
  });

  final List<MedicationItem> medications;
  final bool isEn;
  final VoidCallback onAddMedication;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            SvgPicture.string(_svgMedicine, width: 22, height: 22),
            const SizedBox(width: 8),
            Text(
              isEn ? 'Medications' : 'ยาที่ใช้',
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (medications.isEmpty)
          HealthEmptyStateCard(
            icon: LucideIcons.pill,
            title: isEn ? 'No medications recorded' : 'ยังไม่มีรายการยา',
            subtitle: isEn
                ? 'Tap "+ Add medication" below when your vet prescribes medicine.'
                : 'แตะ "+ เพิ่มยา" ด้านล่างเมื่อคุณหมอสั่งยาหรืออาหารเสริม',
          )
        else
          HealthCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < medications.length; i++) ...[
                  if (i > 0)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1, color: AppColors.line),
                    ),
                  _MedicationTile(item: medications[i], isEn: isEn),
                ],
              ],
            ),
          ),
        const SizedBox(height: 14),
        HealthOutlinedActionButton(
          icon: LucideIcons.plus,
          label: isEn ? 'Add medication' : 'เพิ่มยา',
          onPressed: onAddMedication,
        ),
      ],
    );
  }
}

class _MedicationTile extends StatelessWidget {
  const _MedicationTile({required this.item, required this.isEn});

  final MedicationItem item;
  final bool isEn;

  @override
  Widget build(BuildContext context) {
    final name = isEn ? item.nameEn : item.nameTh;
    final dosage = isEn ? item.dosageEn : item.dosageTh;
    final period = isEn ? item.periodEn : item.periodTh;
    final reason = isEn ? item.reasonEn : item.reasonTh;
    final clinic = isEn ? item.clinicEn : item.clinicTh;
    final metaParts = [
      period,
      if (reason.isNotEmpty) reason,
      if (clinic.isNotEmpty) clinic,
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              item.isActive
                  ? (isEn ? 'In use' : 'กำลังใช้')
                  : (isEn ? 'Completed' : 'ครบแล้ว'),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: item.isActive ? FontWeight.w600 : FontWeight.w500,
                color: item.isActive
                    ? AppColors.healthMedPurple
                    : AppColors.muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          dosage,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: AppColors.text2,
          ),
        ),
        if (metaParts.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            metaParts,
            style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
          ),
        ],
      ],
    );
  }
}

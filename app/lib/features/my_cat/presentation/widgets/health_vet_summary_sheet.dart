import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/my_cat_data.dart';
import 'my_cat_l10n.dart';
import 'sheet_chrome.dart';

/// ชีต "Vet Summary" — สรุปสั้น ๆ สำหรับยื่นให้สัตวแพทย์ตรงตามเว็บ www.แมว.live
Future<void> showVetSummarySheet(
  BuildContext context, {
  required List<CatProfile> cats,
  required CatProfile initialCat,
  required OwnerProfile owner,
  required bool isEn,
  required ValueChanged<String> onNotify,
}) {
  return showMyCatSheet<void>(
    context,
    builder: (_) => _VetSummarySheet(
      cat: initialCat,
      owner: owner,
      isEn: isEn,
      onNotify: onNotify,
    ),
  );
}

class _VetSummarySheet extends StatelessWidget {
  const _VetSummarySheet({
    required this.cat,
    required this.owner,
    required this.isEn,
    required this.onNotify,
  });

  final CatProfile cat;
  final OwnerProfile owner;
  final bool isEn;
  final ValueChanged<String> onNotify;

  String _buildSummaryText() {
    final book = cat.healthBook;
    final catName = MyCatL10n.catName(cat.name, isEn);
    final breed = MyCatL10n.breed(cat.breed, isEn);
    final age = MyCatL10n.age(cat.ageLabel, isEn);
    final ownerName = MyCatL10n.ownerName(owner.displayName, isEn);
    final phone = cat.trackerInfo.contactPhone;
    final weightDelta = isEn ? book.weightDeltaEn : book.weightDeltaTh;
    final next = book.nextAppointment;
    final activeMeds = book.medications.where((m) => m.isActive).toList();

    final lines = <String>[
      'Vet Summary · $catName (${cat.publicId})',
      isEn
          ? '$breed · ${cat.gender == CatGender.female ? 'Female' : 'Male'} · ${cat.neutered ? 'Neutered' : 'Intact'} · Age $age'
          : '$breed · ${cat.gender.label} · ${cat.neutered ? 'ทำหมันแล้ว' : 'ยังไม่ทำหมัน'} · อายุ $age',
      isEn
          ? 'Latest weight ${cat.weightText} kg${weightDelta.isNotEmpty ? ' ($weightDelta)' : ''}'
          : 'น้ำหนักล่าสุด ${cat.weightText} กก.${weightDelta.isNotEmpty ? ' ($weightDelta)' : ''}',
      if (next != null)
        isEn
            ? 'Next appointment: ${next.titleEn} · ${next.dateEn}'
            : 'นัดถัดไป: ${next.titleTh} · ${next.dateTh}',
      '',
      isEn ? 'Owner: $ownerName · $phone' : 'เจ้าของ: $ownerName · $phone',
      '',
      isEn ? 'Vaccination history:' : 'ประวัติวัคซีน:',
      if (book.vaccines.isEmpty)
        isEn ? '• No vaccine records yet' : '• ยังไม่มีประวัติวัคซีน'
      else
        for (final v in book.vaccines)
          isEn
              ? '• ${v.dateEn} · ${v.nameEn} (${v.doseEn})${v.lotNumber.isNotEmpty ? ' Lot ${v.lotNumber} Exp ${v.expiryDate}' : ''}${v.clinicEn.isNotEmpty ? ' — ${v.clinicEn}' : ''}'
              : '• ${v.dateTh} · ${v.nameTh} (${v.doseTh})${v.lotNumber.isNotEmpty ? ' ล็อต ${v.lotNumber} หมดอายุ ${v.expiryDate}' : ''}${v.clinicTh.isNotEmpty ? ' — ${v.clinicTh}' : ''}',
      '',
      isEn ? 'Active medications:' : 'ยาที่ใช้อยู่:',
      if (activeMeds.isEmpty)
        isEn ? '• None' : '• ไม่มี'
      else
        for (final m in activeMeds)
          isEn
              ? '• ${m.nameEn} · ${m.dosageEn} (${m.periodEn})'
              : '• ${m.nameTh} · ${m.dosageTh} (${m.periodTh})',
      isEn ? 'Allergies: ${book.allergyEn}' : 'แพ้ยา: ${book.allergyTh}',
      '',
      isEn ? 'Recent records:' : 'บันทึกล่าสุด:',
      if (book.records.isEmpty)
        isEn ? '• No health logs yet' : '• ยังไม่มีบันทึกสุขภาพ'
      else
        for (final r in book.records.take(5))
          isEn
              ? '• ${r.dateEn} · ${r.category.enLabel}: ${r.titleEn}${r.detailsEn.isNotEmpty ? ' — ${r.detailsEn}' : ''}'
              : '• ${r.dateTh} · ${r.category.thLabel}: ${r.titleTh}${r.detailsTh.isNotEmpty ? ' — ${r.detailsTh}' : ''}',
    ];

    return lines.join('\n');
  }

  Future<void> _copy(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    onNotify(isEn ? 'Vet summary copied' : 'คัดลอก Vet Summary แล้ว');
  }

  Future<void> _sendToClinic(BuildContext context, String text) async {
    try {
      await SharePlus.instance.share(ShareParams(text: text));
    } on Exception {
      onNotify(
        isEn
            ? 'Ready to send Vet Summary to clinic'
            : 'เตรียมส่ง Vet Summary ให้คลินิกแล้ว',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final summaryText = _buildSummaryText();
    final catName = MyCatL10n.catName(cat.name, isEn);

    return MyCatSheetFrame(
      title: 'Vet Summary',
      maxHeightFactor: 0.9,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEn
                  ? 'Brief summary for your vet · generated from $catName’s health book'
                  : 'สรุปสั้น ๆ สำหรับยื่นให้สัตวแพทย์ · สร้างจากสมุดสุขภาพของ$catName',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.page,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.line),
              ),
              child: SelectableText(
                summaryText,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.5,
                  color: AppColors.text,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copy(context, summaryText),
                    icon: const Icon(LucideIcons.copy, size: 16),
                    label: Text(
                      isEn ? 'Copy' : 'คัดลอก',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      backgroundColor: AppColors.card,
                      foregroundColor: AppColors.text,
                      side: const BorderSide(color: AppColors.line2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _sendToClinic(context, summaryText),
                    icon: const Icon(LucideIcons.share2, size: 16),
                    label: Text(
                      isEn ? 'Send to clinic' : 'ส่งให้คลินิก',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      backgroundColor: AppColors.btn,
                      foregroundColor: AppColors.ink,
                      side: const BorderSide(color: AppColors.btnBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/my_cat_data.dart';
import 'health_shared_widgets.dart';
import 'my_cat_l10n.dart';

const _svgPetInfo = '''
<svg viewBox="0 0 24 24" fill="none" stroke="#4A3428" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><path d="M12 12.5c-2.6 0-5 2.5-5 4.7 0 1.6 1.3 2.3 2.6 2.3 1 0 1.4-.4 2.4-.4s1.4.4 2.4.4c1.3 0 2.6-.7 2.6-2.3 0-2.2-2.4-4.7-5-4.7z" fill="#F9C98F"/><ellipse cx="6" cy="10.2" rx="1.7" ry="2.1" fill="#F7A8C2"/><ellipse cx="10" cy="6.6" rx="1.7" ry="2.2" fill="#F7A8C2"/><ellipse cx="14" cy="6.6" rx="1.7" ry="2.2" fill="#F7A8C2"/><ellipse cx="18" cy="10.2" rx="1.7" ry="2.1" fill="#F7A8C2"/></svg>
''';

const _svgOwnerInfo = '''
<svg viewBox="0 0 24 24" fill="none" stroke="#4A3428" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><path d="M4.5 20c0-3.6 3.2-5.5 7.5-5.5s7.5 1.9 7.5 5.5z" fill="#B9A6F2"/><circle cx="12" cy="9" r="4.2" fill="#FFE1C4"/><path d="M10.2 9.3v.5M13.8 9.3v.5" stroke-width="1.8"/><path d="M10.6 11.1c.9.7 1.9.7 2.8 0" stroke-width="1.3"/><circle cx="9" cy="11" r=".9" fill="#F7A8C2" stroke="none"/><circle cx="15" cy="11" r=".9" fill="#F7A8C2" stroke="none"/></svg>
''';

const _svgVaccine = '''
<svg viewBox="0 0 24 24" fill="none" stroke="#4A3428" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><g transform="rotate(45 12 12)"><path d="M12 1.8v3.2M9.2 5h5.6"/><rect x="9.4" y="5" width="5.2" height="10" rx="1.6" fill="#BFE0FF"/><path d="M9.4 9.2h2.2M9.4 11.8h2.2" stroke-width="1.2"/><path d="M10.8 15v2.6M13.2 15v2.6"/><path d="M12 17.6v4" stroke-width="1.4"/></g><path d="M6.6 8.1c-.6-1.1-2.2-.8-2.2.6 0 1.1 2.2 2.4 2.2 2.4s2.2-1.3 2.2-2.4c0-1.4-1.6-1.7-2.2-.6z" fill="#F28C8C" stroke-width="1.1"/></svg>
''';

const _svgParasite = '''
<svg viewBox="0 0 24 24" fill="none" stroke="#4A3428" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><path d="M9.5 6.2 8 4.2M14.5 6.2 16 4.2" stroke-width="1.3"/><path d="M12 5.8c-3.6 0-6 2.7-6 6.2 0 3.6 2.7 6.5 6 6.5s6-2.9 6-6.5c0-3.5-2.4-6.2-6-6.2z" fill="#F28C8C"/><path d="M12 6v12.5" stroke-width="1.3"/><circle cx="9" cy="10.5" r="1" fill="#4A3428" stroke="none"/><circle cx="15" cy="10.5" r="1" fill="#4A3428" stroke="none"/><circle cx="9.3" cy="14.6" r=".9" fill="#4A3428" stroke="none"/><circle cx="14.7" cy="14.6" r=".9" fill="#4A3428" stroke="none"/></svg>
''';

const _svgOtherNotes = '''
<svg viewBox="0 0 24 24" fill="none" stroke="#4A3428" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><rect x="5" y="5" width="14" height="16" rx="2.4" fill="#FFF3C4"/><path d="M9 3.5h6v3H9z" fill="#9ED8CF"/><path d="M12 17.2s-3-1.8-3-4a1.7 1.7 0 0 1 3-1 1.7 1.7 0 0 1 3 1c0 2.2-3 4-3 4z" fill="#FF9FB5" stroke-width="1.2"/></svg>
''';

/// แท็บ 3: สมุดวัคซีน — หัวข้ออยู่นอกการ์ด เส้นคั่นบางระหว่างแถว ตรงตามเว็บ www.แมว.live
class HealthVaccineTab extends StatelessWidget {
  const HealthVaccineTab({
    super.key,
    required this.cat,
    required this.owner,
    required this.isEn,
    required this.onAddVaccine,
    required this.onNotify,
  });

  final CatProfile cat;
  final OwnerProfile owner;
  final bool isEn;
  final VoidCallback onAddVaccine;
  final ValueChanged<String> onNotify;

  Future<void> _callClinic(String phone, String clinic) async {
    final uri = Uri(scheme: 'tel', path: phone);
    try {
      final launched = await launchUrl(uri);
      if (!launched) {
        onNotify(isEn ? 'Call $clinic ($phone)' : 'โทรหา $clinic ($phone)');
      }
    } on Exception {
      onNotify(isEn ? 'Call $clinic ($phone)' : 'โทรหา $clinic ($phone)');
    }
  }

  String _coatLabel(CatProfile cat, bool isEn) {
    if (cat.id == 'cat-mali') {
      return isEn
          ? 'Cream · dark brown face, ears, tail & paws (colorpoint)'
          : 'ครีม · หน้า หู หาง และเท้าสีน้ำตาลเข้ม (colorpoint)';
    }
    return MyCatL10n.coatColor(cat.idCard.coatColor, isEn);
  }

  String _birthLabel(CatProfile cat, bool isEn) {
    final displayAge = MyCatL10n.age(cat.ageLabel, isEn);
    if (cat.id == 'cat-mali') {
      return isEn ? 'Aug 2023 (age $displayAge)' : 'ส.ค. 2566 (อายุ $displayAge)';
    }
    return cat.idCard.birthDateLabel.isEmpty
        ? displayAge
        : '${MyCatL10n.thaiDate(cat.idCard.birthDateLabel, isEn)} (${isEn ? 'age $displayAge' : 'อายุ $displayAge'})';
  }

  String _addressLabel(OwnerProfile owner, bool isEn) {
    final district = MyCatL10n.ownerDistrict(owner.district, isEn);
    if (district == 'บางซื่อ กรุงเทพฯ') return 'บางซื่อ กรุงเทพฯ 10800';
    if (district == 'Bang Sue, Bangkok') return 'Bang Sue, Bangkok 10800';
    return district.isEmpty ? (isEn ? 'Bangkok' : 'กรุงเทพฯ') : district;
  }

  @override
  Widget build(BuildContext context) {
    final book = cat.healthBook;
    final displayCat = MyCatL10n.catName(cat.name, isEn);
    final displayBreed = MyCatL10n.breed(cat.breed, isEn);
    final displayOwner = MyCatL10n.ownerName(owner.displayName, isEn);
    final hasRemarks = (isEn ? book.remarksEn : book.remarksTh).isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. ข้อมูลสัตว์เลี้ยง
        _ExternalSectionHeader(
          svg: _svgPetInfo,
          title: isEn ? 'Pet information' : 'ข้อมูลสัตว์เลี้ยง',
        ),
        const SizedBox(height: 8),
        HealthCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              _DividedInfoRow(
                label: isEn ? 'Name' : 'ชื่อ',
                value: displayCat,
              ),
              _DividedInfoRow(
                label: isEn ? 'Species / Breed' : 'ชนิด / สายพันธุ์',
                value: isEn ? 'Cat · $displayBreed' : 'แมว · $displayBreed',
              ),
              _DividedInfoRow(
                label: isEn ? 'Sex' : 'เพศ',
                value: isEn
                    ? '${cat.gender == CatGender.female ? 'Female' : 'Male'} / ${cat.neutered ? 'Neutered' : 'Intact'}'
                    : '${cat.gender.label} / ${cat.neutered ? 'ทำหมันแล้ว' : 'ยังไม่ทำหมัน'}',
              ),
              _DividedInfoRow(
                label: isEn ? 'Color / Markings' : 'สี / ลักษณะเด่น',
                value: _coatLabel(cat, isEn),
              ),
              _DividedInfoRow(
                label: isEn ? 'Birthdate' : 'วันเกิด',
                value: _birthLabel(cat, isEn),
              ),
              _DividedInfoRow(
                label: isEn ? 'Latest weight' : 'น้ำหนักล่าสุด',
                value: isEn
                    ? '${cat.weightText} kg'
                    : '${cat.weightText} กก.',
              ),
              _DividedInfoRow(
                label: 'Cat ID',
                value: cat.publicId,
                isLast: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. ข้อมูลเจ้าของ
        _ExternalSectionHeader(
          svg: _svgOwnerInfo,
          title: isEn ? 'Owner information' : 'ข้อมูลเจ้าของ',
        ),
        const SizedBox(height: 8),
        HealthCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              _DividedInfoRow(
                label: isEn ? 'Owner name' : 'ชื่อเจ้าของ',
                value: displayOwner,
              ),
              _DividedInfoRow(
                label: isEn ? 'Phone' : 'เบอร์โทรศัพท์',
                value: cat.trackerInfo.contactPhone,
              ),
              _DividedInfoRow(
                label: isEn ? 'Address' : 'ที่อยู่',
                value: _addressLabel(owner, isEn),
                isLast: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 3. ประวัติการฉีดวัคซีน
        _ExternalSectionHeader(
          svg: _svgVaccine,
          title: isEn ? 'Vaccination records' : 'ประวัติการฉีดวัคซีน',
        ),
        const SizedBox(height: 8),
        HealthCard(
          padding: const EdgeInsets.all(16),
          child: book.vaccines.isEmpty
              ? Text(
                  isEn
                      ? 'No vaccination records yet. Tap "Add vaccination" below to log one.'
                      : 'ยังไม่มีประวัติวัคซีน กด "เพิ่มการฉีดวัคซีน" ด้านล่างเพื่อบันทึก',
                  style: const TextStyle(fontSize: 13, color: AppColors.muted),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < book.vaccines.length; i++) ...[
                      if (i > 0)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1, color: AppColors.line),
                        ),
                      _VaccineRecordTile(
                        record: book.vaccines[i],
                        isEn: isEn,
                        onCallClinic: _callClinic,
                      ),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: 16),

        // 4. ถ่ายพยาธิ / ป้องกันเห็บหมัด
        _ExternalSectionHeader(
          svg: _svgParasite,
          title: isEn
              ? 'Deworming / tick & flea'
              : 'ถ่ายพยาธิ / ป้องกันเห็บหมัด',
        ),
        const SizedBox(height: 8),
        HealthCard(
          child: book.parasitePrevention == null
              ? Text(
                  isEn
                      ? 'No record yet'
                      : 'ยังไม่มีข้อมูลการถ่ายพยาธิ/หยดเห็บหมัด',
                  style: const TextStyle(fontSize: 13, color: AppColors.muted),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEn
                          ? book.parasitePrevention!.productEn
                          : book.parasitePrevention!.productTh,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${isEn ? book.parasitePrevention!.dateEn : book.parasitePrevention!.dateTh} · ${isEn ? book.parasitePrevention!.noteEn : book.parasitePrevention!.noteTh}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.text2,
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 16),

        // 5. บันทึกสุขภาพอื่น ๆ
        _ExternalSectionHeader(
          svg: _svgOtherNotes,
          title: isEn ? 'Other health notes' : 'บันทึกสุขภาพอื่น ๆ',
        ),
        const SizedBox(height: 8),
        HealthCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              _DividedInfoRow(
                label: isEn ? 'Drug allergies' : 'แพ้ยา',
                value: isEn ? book.allergyEn : book.allergyTh,
              ),
              _DividedInfoRow(
                label: isEn ? 'Past illnesses' : 'ประวัติเจ็บป่วย',
                value: isEn ? book.pastIllnessEn : book.pastIllnessTh,
              ),
              _DividedInfoRow(
                label: isEn ? 'Surgical history' : 'การผ่าตัด',
                value: isEn ? book.surgeryEn : book.surgeryTh,
                isLast: !hasRemarks,
              ),
              if (hasRemarks)
                _DividedInfoRow(
                  label: isEn ? 'Remarks' : 'หมายเหตุ',
                  value: isEn ? book.remarksEn : book.remarksTh,
                  isLast: true,
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        HealthOutlinedActionButton(
          icon: LucideIcons.plus,
          label: isEn ? 'Add vaccination' : 'เพิ่มการฉีดวัคซีน',
          onPressed: onAddVaccine,
        ),
      ],
    );
  }
}

class _ExternalSectionHeader extends StatelessWidget {
  const _ExternalSectionHeader({
    required this.svg,
    required this.title,
  });

  final String svg;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SvgPicture.string(svg, width: 22, height: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
        ),
      ],
    );
  }
}

class _DividedInfoRow extends StatelessWidget {
  const _DividedInfoRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: isLast
          ? null
          : const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.line)),
            ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                height: 1.35,
                color: AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VaccineRecordTile extends StatelessWidget {
  const _VaccineRecordTile({
    required this.record,
    required this.isEn,
    required this.onCallClinic,
  });

  final VaccineRecord record;
  final bool isEn;
  final Future<void> Function(String phone, String clinic) onCallClinic;

  @override
  Widget build(BuildContext context) {
    final name = isEn ? record.nameEn : record.nameTh;
    final date = isEn ? record.dateEn : record.dateTh;
    final dose = isEn ? record.doseEn : record.doseTh;
    final nextDue = isEn ? record.nextDueEn : record.nextDueTh;
    final clinic = isEn ? record.clinicEn : record.clinicTh;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ),
            if (record.hasSticker) ...[
              const SizedBox(width: 8),
              const SizedBox(
                width: 32,
                height: 24,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Icon(
                    LucideIcons.badgeCheck,
                    size: 20,
                    color: AppColors.ownerTeal,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 3),
        Text(
          isEn
              ? '$date · $dose · Next: $nextDue'
              : '$date · $dose · นัดถัดไป $nextDue',
          style: const TextStyle(fontSize: 12.5, color: AppColors.text2),
        ),
        if (record.hasSticker) ...[
          const SizedBox(height: 6),
          Text(
            isEn
                ? '${record.productName} · ${record.manufacturer} · Lot ${record.lotNumber} · Exp ${record.expiryDate}'
                : '${record.productName} · ${record.manufacturer} · ล็อต ${record.lotNumber} · หมดอายุ ${record.expiryDate}',
            style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
          ),
        ],
        if (clinic.isNotEmpty ||
            record.vetName.isNotEmpty ||
            record.clinicPhone.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  [
                    if (clinic.isNotEmpty) clinic,
                    if (record.vetName.isNotEmpty) record.vetName,
                    if (record.licenseNumber.isNotEmpty)
                      isEn
                          ? 'License ${record.licenseNumber}'
                          : 'ใบอนุญาต ${record.licenseNumber}',
                  ].join(' · '),
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ),
              if (record.clinicPhone.isNotEmpty) ...[
                const SizedBox(width: 8),
                Semantics(
                  button: true,
                  label: isEn ? 'Call $clinic' : 'โทรหา $clinic',
                  child: Tooltip(
                    message: isEn ? 'Call $clinic' : 'โทรหา $clinic',
                    child: InkWell(
                      onTap: () => onCallClinic(record.clinicPhone, clinic),
                      borderRadius: BorderRadius.circular(999),
                      child: const SizedBox(
                        width: 32,
                        height: 32,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Icon(
                            LucideIcons.phone,
                            size: 18,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

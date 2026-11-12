import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/cat_health_data.dart';
import 'sheet_chrome.dart';

const _healthSheetCategories = [
  HealthRecordCategory.vaccine,
  HealthRecordCategory.deworming,
  HealthRecordCategory.bloodTest,
  HealthRecordCategory.illness,
  HealthRecordCategory.checkup,
  HealthRecordCategory.weight,
];

/// ชีต "เพิ่มบันทึกสุขภาพ" — ตรงตามหน้าเว็บ www.แมว.live (ปุ่มบันทึกมุมขวาบน, ป้ายหัวข้อด้านบนช่องกรอก)
Future<void> showAddHealthRecordSheet(
  BuildContext context, {
  required bool isEn,
  HealthRecordCategory initialCategory = HealthRecordCategory.checkup,
  String? initialTitle,
  String? initialDateTh,
  String? initialDateEn,
  required ValueChanged<HealthRecordEntry> onSave,
}) {
  return showMyCatSheet<void>(
    context,
    builder: (_) => _AddHealthRecordSheet(
      isEn: isEn,
      initialCategory: initialCategory,
      initialTitle: initialTitle,
      initialDateTh: initialDateTh,
      initialDateEn: initialDateEn,
      onSave: onSave,
    ),
  );
}

class _AddHealthRecordSheet extends StatefulWidget {
  const _AddHealthRecordSheet({
    required this.isEn,
    required this.initialCategory,
    this.initialTitle,
    this.initialDateTh,
    this.initialDateEn,
    required this.onSave,
  });

  final bool isEn;
  final HealthRecordCategory initialCategory;
  final String? initialTitle;
  final String? initialDateTh;
  final String? initialDateEn;
  final ValueChanged<HealthRecordEntry> onSave;

  @override
  State<_AddHealthRecordSheet> createState() => _AddHealthRecordSheetState();
}

class _AddHealthRecordSheetState extends State<_AddHealthRecordSheet> {
  final _formKey = GlobalKey<FormState>();
  late HealthRecordCategory _category =
      _healthSheetCategories.contains(widget.initialCategory)
      ? widget.initialCategory
      : HealthRecordCategory.checkup;
  late final TextEditingController _titleCtrl = TextEditingController(
    text: widget.initialTitle ?? '',
  );
  final _detailsCtrl = TextEditingController();
  late bool _canSave = (widget.initialTitle ?? '').trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _titleCtrl.addListener(_onTitleChanged);
  }

  void _onTitleChanged() {
    final next = _titleCtrl.text.trim().isNotEmpty;
    if (next != _canSave) setState(() => _canSave = next);
  }

  @override
  void dispose() {
    _titleCtrl.removeListener(_onTitleChanged);
    _titleCtrl.dispose();
    _detailsCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final title = _titleCtrl.text.trim();
    final details = _detailsCtrl.text.trim();
    final dateTh = widget.initialDateTh ?? '12 พ.ย. 2569';
    final dateEn = widget.initialDateEn ?? '12 Nov 2026';

    widget.onSave(
      HealthRecordEntry(
        id: 'rec-${DateTime.now().microsecondsSinceEpoch}',
        category: _category,
        dateTh: dateTh,
        dateEn: dateEn,
        titleTh: title,
        titleEn: title,
        detailsTh: details,
        detailsEn: details,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEn = widget.isEn;
    final shownDate = isEn
        ? (widget.initialDateEn ?? 'Today (12 Nov 2026)')
        : (widget.initialDateTh ?? 'วันนี้ (12 พ.ย. 2569)');

    return MyCatSheetFrame(
      title: isEn ? 'Add health note' : 'เพิ่มบันทึกสุขภาพ',
      trailingAction: _SheetSavePillButton(
        label: isEn ? 'Save' : 'บันทึก',
        enabled: _canSave,
        onPressed: _submit,
      ),
      maxHeightFactor: 0.9,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEn ? 'Category' : 'ประเภท',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final cat in _healthSheetCategories)
                    _CategoryChipPill(
                      label: isEn ? cat.enLabel : cat.thLabel,
                      selected: _category == cat,
                      onTap: () => setState(() => _category = cat),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              _HealthLabeledInput(
                controller: _titleCtrl,
                label: isEn ? 'Title' : 'หัวข้อ',
                hint: isEn
                    ? 'e.g. Morning checkup or 4.5 kg'
                    : 'เช่น ชั่งน้ำหนัก หรือ อาการที่พบ',
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? (isEn ? 'Please enter a title' : 'กรุณากรอกหัวข้อ')
                    : null,
              ),
              const SizedBox(height: 12),
              _HealthLabeledInput(
                controller: _detailsCtrl,
                label: isEn ? 'Details' : 'รายละเอียด',
                hint: isEn
                    ? 'Symptoms, meds, clinic, or vet advice'
                    : 'อาการ ยา คลินิก หรือสิ่งที่หมอแนะนำ',
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              Text(
                isEn
                    ? 'Date: $shownDate · You can log from photos or Cat AI in Documents & Cat AI'
                    : 'วันที่: $shownDate · บันทึกจากรูปหรือ Cat AI ได้ที่แท็บเอกสารและหน้า Cat AI',
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ชีต "เพิ่มการฉีดวัคซีน" — จัดวางตรงตามหน้าเว็บ www.แมว.live
Future<void> showAddVaccineSheet(
  BuildContext context, {
  required bool isEn,
  required ValueChanged<VaccineRecord> onSave,
}) {
  return showMyCatSheet<void>(
    context,
    builder: (_) => _AddVaccineSheet(isEn: isEn, onSave: onSave),
  );
}

class _AddVaccineSheet extends StatefulWidget {
  const _AddVaccineSheet({required this.isEn, required this.onSave});

  final bool isEn;
  final ValueChanged<VaccineRecord> onSave;

  @override
  State<_AddVaccineSheet> createState() => _AddVaccineSheetState();
}

class _AddVaccineSheetState extends State<_AddVaccineSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  late final TextEditingController _dateCtrl = TextEditingController(
    text: widget.isEn ? '12 Nov 2026' : '12 พ.ย. 2569',
  );
  final _doseCtrl = TextEditingController();
  final _nextDueCtrl = TextEditingController();
  final _makerCtrl = TextEditingController();
  final _productCtrl = TextEditingController();
  final _lotCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _clinicCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _vetCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();
  bool _canSave = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(_onNameChanged);
  }

  void _onNameChanged() {
    final next = _nameCtrl.text.trim().isNotEmpty;
    if (next != _canSave) setState(() => _canSave = next);
  }

  @override
  void dispose() {
    _nameCtrl.removeListener(_onNameChanged);
    _nameCtrl.dispose();
    _dateCtrl.dispose();
    _doseCtrl.dispose();
    _nextDueCtrl.dispose();
    _makerCtrl.dispose();
    _productCtrl.dispose();
    _lotCtrl.dispose();
    _expiryCtrl.dispose();
    _clinicCtrl.dispose();
    _phoneCtrl.dispose();
    _vetCtrl.dispose();
    _licenseCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final name = _nameCtrl.text.trim();
    final date = _dateCtrl.text.trim();
    final dose = _doseCtrl.text.trim().isEmpty
        ? (widget.isEn ? 'Annual booster' : 'กระตุ้นประจำปี')
        : _doseCtrl.text.trim();
    final nextDue = _nextDueCtrl.text.trim().isEmpty
        ? (widget.isEn ? '12 Nov 2027' : '12 พ.ย. 2570')
        : _nextDueCtrl.text.trim();
    final clinic = _clinicCtrl.text.trim();

    widget.onSave(
      VaccineRecord(
        id: 'vax-${DateTime.now().microsecondsSinceEpoch}',
        nameTh: name,
        nameEn: name,
        dateTh: date,
        dateEn: date,
        doseTh: dose,
        doseEn: dose,
        nextDueTh: nextDue,
        nextDueEn: nextDue,
        manufacturer: _makerCtrl.text.trim(),
        productName: _productCtrl.text.trim(),
        lotNumber: _lotCtrl.text.trim(),
        expiryDate: _expiryCtrl.text.trim(),
        clinicTh: clinic,
        clinicEn: clinic,
        clinicPhone: _phoneCtrl.text.trim(),
        vetName: _vetCtrl.text.trim(),
        licenseNumber: _licenseCtrl.text.trim(),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEn = widget.isEn;
    return MyCatSheetFrame(
      title: isEn ? 'Add vaccination' : 'เพิ่มการฉีดวัคซีน',
      trailingAction: _SheetSavePillButton(
        label: isEn ? 'Save' : 'บันทึก',
        enabled: _canSave,
        onPressed: _submit,
      ),
      maxHeightFactor: 0.92,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HealthLabeledInput(
                controller: _nameCtrl,
                label: isEn ? 'Vaccine' : 'ชื่อวัคซีน',
                hint: isEn
                    ? 'Feline Combo Vaccine (FVRCP)'
                    : 'วัคซีนรวมหวัดแมว-ไข้หัด (FVRCP)',
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? (isEn
                          ? 'Please enter vaccine name'
                          : 'กรุณากรอกชื่อวัคซีน')
                    : null,
              ),
              const SizedBox(height: 12),
              _HealthLabeledInput(
                controller: _dateCtrl,
                label: isEn ? 'Date given' : 'วันที่ฉีด',
              ),
              const SizedBox(height: 12),
              _HealthLabeledInput(
                controller: _doseCtrl,
                label: isEn ? 'Dose / round' : 'ครั้งที่',
                hint: isEn
                    ? 'Dose 1 / annual booster'
                    : 'เข็มที่ 1 / กระตุ้นประจำปี',
              ),
              const SizedBox(height: 12),
              _HealthLabeledInput(
                controller: _nextDueCtrl,
                label: isEn ? 'Next appointment' : 'นัดครั้งถัดไป',
                hint: isEn ? 'e.g. 7 Nov 2027' : 'เช่น 7 พ.ย. 2570',
              ),
              const SizedBox(height: 18),
              Text(
                isEn ? 'Vaccine sticker' : 'สติ๊กเกอร์วัคซีน',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _HealthLabeledInput(
                      controller: _makerCtrl,
                      label: isEn ? 'Manufacturer' : 'บริษัทผู้ผลิต',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _HealthLabeledInput(
                      controller: _productCtrl,
                      label: isEn ? 'Product name' : 'ชื่อผลิตภัณฑ์',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _HealthLabeledInput(
                      controller: _lotCtrl,
                      label: isEn ? 'Lot number (Lot)' : 'เลขล็อต (Lot)',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _HealthLabeledInput(
                      controller: _expiryCtrl,
                      label: isEn ? 'Expiry date' : 'วันหมดอายุ',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                isEn ? 'Clinic and vet' : 'สถานพยาบาลและสัตวแพทย์',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _HealthLabeledInput(
                      controller: _clinicCtrl,
                      label: isEn
                          ? 'Clinic / animal hospital'
                          : 'คลินิก / โรงพยาบาลสัตว์',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _HealthLabeledInput(
                      controller: _phoneCtrl,
                      label: isEn ? 'Clinic phone' : 'เบอร์โทรคลินิก',
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _HealthLabeledInput(
                      controller: _vetCtrl,
                      label: isEn ? 'Signing vet' : 'ชื่อสัตวแพทย์ผู้ลงชื่อ',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _HealthLabeledInput(
                      controller: _licenseCtrl,
                      label: isEn ? 'License number' : 'เลขใบประกอบวิชาชีพ',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                isEn
                    ? 'Without a sticker or vet license number, it will be flagged as incomplete · you can photograph the real book in the Documents tab'
                    : 'หากไม่มีสติ๊กเกอร์หรือเลขใบอนุญาตหมอ ระบบจะติดป้ายว่าข้อมูลยังไม่ครบ · สามารถถ่ายรูปสมุดจริงเก็บไว้ในแท็บเอกสารได้',
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ชีต "เพิ่มยา" — จัดวางตรงตามหน้าเว็บ www.แมว.live
Future<void> showAddMedicationSheet(
  BuildContext context, {
  required bool isEn,
  required ValueChanged<MedicationItem> onSave,
}) {
  return showMyCatSheet<void>(
    context,
    builder: (_) => _AddMedicationSheet(isEn: isEn, onSave: onSave),
  );
}

class _AddMedicationSheet extends StatefulWidget {
  const _AddMedicationSheet({required this.isEn, required this.onSave});

  final bool isEn;
  final ValueChanged<MedicationItem> onSave;

  @override
  State<_AddMedicationSheet> createState() => _AddMedicationSheetState();
}

class _AddMedicationSheetState extends State<_AddMedicationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  final _periodCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _clinicCtrl = TextEditingController();
  bool _canSave = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(_onNameChanged);
  }

  void _onNameChanged() {
    final next = _nameCtrl.text.trim().isNotEmpty;
    if (next != _canSave) setState(() => _canSave = next);
  }

  @override
  void dispose() {
    _nameCtrl.removeListener(_onNameChanged);
    _nameCtrl.dispose();
    _dosageCtrl.dispose();
    _periodCtrl.dispose();
    _reasonCtrl.dispose();
    _clinicCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final name = _nameCtrl.text.trim();
    final dosage = _dosageCtrl.text.trim().isEmpty
        ? (widget.isEn ? 'As prescribed by vet' : 'ตามที่สัตวแพทย์สั่ง')
        : _dosageCtrl.text.trim();
    final period = _periodCtrl.text.trim().isEmpty
        ? (widget.isEn ? 'From 12 Nov 2026' : 'ตั้งแต่ 12 พ.ย. 2569')
        : _periodCtrl.text.trim();
    final reason = _reasonCtrl.text.trim();
    final clinic = _clinicCtrl.text.trim();

    widget.onSave(
      MedicationItem(
        id: 'med-${DateTime.now().microsecondsSinceEpoch}',
        nameTh: name,
        nameEn: name,
        isActive: true,
        dosageTh: dosage,
        dosageEn: dosage,
        periodTh: period,
        periodEn: period,
        reasonTh: reason,
        reasonEn: reason,
        clinicTh: clinic,
        clinicEn: clinic,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEn = widget.isEn;
    return MyCatSheetFrame(
      title: isEn ? 'Add medication' : 'เพิ่มยา',
      trailingAction: _SheetSavePillButton(
        label: isEn ? 'Save' : 'บันทึก',
        enabled: _canSave,
        onPressed: _submit,
      ),
      maxHeightFactor: 0.9,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HealthLabeledInput(
                controller: _nameCtrl,
                label: isEn ? 'Medicine name' : 'ชื่อยา',
                hint: isEn ? 'e.g. Amoxicillin' : 'เช่น Amoxicillin',
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? (isEn
                          ? 'Please enter medicine name'
                          : 'กรุณากรอกชื่อยา')
                    : null,
              ),
              const SizedBox(height: 12),
              _HealthLabeledInput(
                controller: _dosageCtrl,
                label: isEn ? 'Dosage & instructions' : 'ขนาดและวิธีให้',
                hint: isEn
                    ? 'e.g. Half tablet twice daily after meals'
                    : 'เช่น ครึ่งเม็ด วันละ 2 ครั้ง หลังอาหาร',
              ),
              const SizedBox(height: 12),
              _HealthLabeledInput(
                controller: _periodCtrl,
                label: isEn ? 'Duration' : 'ระยะเวลา',
                hint: isEn ? 'e.g. 5 days / ongoing' : 'เช่น 5 วัน / ต่อเนื่อง',
              ),
              const SizedBox(height: 12),
              _HealthLabeledInput(
                controller: _reasonCtrl,
                label: isEn ? 'Reason / condition' : 'ใช้เพื่อรักษา',
                hint: isEn ? 'e.g. Skin wound' : 'เช่น แผลที่ผิวหนัง',
              ),
              const SizedBox(height: 12),
              _HealthLabeledInput(
                controller: _clinicCtrl,
                label: isEn
                    ? 'Prescribed by (clinic/vet)'
                    : 'สั่งโดย (คลินิก/สัตวแพทย์)',
              ),
              const SizedBox(height: 12),
              Text(
                isEn
                    ? 'Always follow your vet’s instructions and inform the clinic if any allergic reaction appears.'
                    : 'ทุกครั้งที่ให้ยา ควรทำตามที่สัตวแพทย์สั่ง และแจ้งหมอหากมีอาการแพ้',
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ชีตเลือกอัปโหลดเอกสารสุขภาพ (รูปภาพจากอัลบั้ม หรือเพิ่มไฟล์ PDF ตัวอย่าง)
Future<void> showUploadDocumentSheet(
  BuildContext context, {
  required bool isEn,
  required ValueChanged<HealthDocumentItem> onAddDocument,
  required ValueChanged<String> onNotify,
}) {
  return showMyCatSheet<void>(
    context,
    builder: (sheetCtx) => MyCatSheetFrame(
      title: isEn ? 'Upload health document' : 'อัปโหลดเอกสารสุขภาพ',
      maxHeightFactor: 0.52,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _UploadOptionTile(
              icon: LucideIcons.image,
              iconBg: AppColors.healthDocImgBg,
              iconColor: AppColors.healthDocImgInk,
              title: isEn ? 'Choose photo from gallery' : 'เลือกรูปภาพจากอัลบั้ม',
              subtitle: isEn
                  ? 'Vaccine book photo or prescription sheet'
                  : 'ภาพถ่ายสมุดวัคซีน ใบสั่งยา หรือใบตรวจ',
              onTap: () async {
                Navigator.of(sheetCtx).pop();
                try {
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 85,
                  );
                  if (picked == null) return;
                  final name = picked.name.isNotEmpty
                      ? picked.name
                      : 'vaccine_photo.jpg';
                  onAddDocument(
                    HealthDocumentItem(
                      id: 'doc-${DateTime.now().microsecondsSinceEpoch}',
                      fileName: name,
                      dateTh: 'วันนี้ 12 พ.ย. 2569',
                      dateEn: 'Today 12 Nov 2026',
                      sizeLabel: '640 KB',
                      isPdf: false,
                    ),
                  );
                } on Exception {
                  onNotify(
                    isEn
                        ? 'Gallery unavailable on this device'
                        : 'ไม่สามารถเปิดอัลบั้มรูปบนอุปกรณ์นี้ได้',
                  );
                }
              },
            ),
            const SizedBox(height: 10),
            _UploadOptionTile(
              icon: LucideIcons.fileText,
              iconBg: AppColors.healthDocPdfBg,
              iconColor: AppColors.healthDocPdfInk,
              title: isEn ? 'Attach sample lab PDF' : 'แนบไฟล์ผลตรวจ PDF ตัวอย่าง',
              subtitle: isEn
                  ? 'Demo document for offline preview'
                  : 'จำลองแนบไฟล์ผลตรวจเลือด/ใบเสร็จเพื่อดูตัวอย่างทันที',
              onTap: () {
                Navigator.of(sheetCtx).pop();
                onAddDocument(
                  HealthDocumentItem(
                    id: 'doc-${DateTime.now().microsecondsSinceEpoch}',
                    fileName: isEn
                        ? 'Lab_Report_Nov2026.pdf'
                        : 'ผลตรวจสุขภาพ_พย2569.pdf',
                    dateTh: '12 พ.ย. 2569',
                    dateEn: '12 Nov 2026',
                    sizeLabel: '520 KB',
                    isPdf: true,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _SheetSavePillButton extends StatelessWidget {
  const _SheetSavePillButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 36),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          backgroundColor: enabled ? AppColors.btn : AppColors.page,
          disabledBackgroundColor: AppColors.page,
          foregroundColor: AppColors.ink,
          disabledForegroundColor: AppColors.unchecked,
          side: BorderSide(
            color: enabled ? AppColors.btnBorder : AppColors.line,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: enabled ? AppColors.ink : AppColors.unchecked,
          ),
        ),
      ),
    );
  }
}

class _CategoryChipPill extends StatelessWidget {
  const _CategoryChipPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.btn : AppColors.card,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? AppColors.btnBorder : AppColors.line2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppColors.ink : AppColors.text2,
            ),
          ),
        ),
      ),
    );
  }
}

class _HealthLabeledInput extends StatelessWidget {
  const _HealthLabeledInput({
    required this.controller,
    required this.label,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(fontSize: 14, color: AppColors.text),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13.5, color: AppColors.muted),
            filled: true,
            fillColor: AppColors.page,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.line2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.line2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.btnBorder,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _UploadOptionTile extends StatelessWidget {
  const _UploadOptionTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

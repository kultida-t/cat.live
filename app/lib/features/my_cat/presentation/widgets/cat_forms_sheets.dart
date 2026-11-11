import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/media/strip_image_metadata.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/social_brand_icons.dart';
import '../../domain/entities/my_cat_data.dart';
import 'my_cat_l10n.dart';
import 'sheet_chrome.dart';

const _defaultCatAvatars = [
  'asset:assets/images/hero/mali.jpg',
  'asset:assets/images/hero/somjeed.jpg',
  'asset:assets/images/hero/thuadam.jpg',
  'asset:assets/images/hero/kitten.jpg',
  'asset:assets/images/hero/tabby.jpg',
];

const _ageOptions = [
  'น้อยกว่า 3 เดือน',
  '3 เดือน',
  '6 เดือน',
  '9 เดือน',
  '1 ปี',
  '2 ปี',
  '3 ปี',
  '4 ปี',
  '5 ปี',
  '6 ปี',
  '7 ปี',
  '8 ปี',
  '9 ปี',
  '10 ปี',
  '11 ปี',
  '12 ปี',
  '13 ปี',
  '14 ปี',
  '15+ ปี',
];

/// หน้าฟอร์มเพิ่มแมว / แก้ไขโปรไฟล์แมว (เต็มจอ Scaffold เพื่อไม่ให้คีย์บอร์ด iOS ค้าง)
Future<void> showCatFormSheet(
  BuildContext context, {
  CatProfile? existingCat,
  Set<String> existingCatNames = const {},
  bool isEn = false,
  required Future<bool> Function(CatProfile cat) onSubmit,
}) {
  return Navigator.of(context, rootNavigator: true).push<void>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _CatFormPage(
        existingCat: existingCat,
        existingCatNames: existingCatNames,
        isEn: isEn,
        onSubmit: onSubmit,
      ),
    ),
  );
}

class _CatFormPage extends StatefulWidget {
  const _CatFormPage({
    this.existingCat,
    this.existingCatNames = const {},
    this.isEn = false,
    required this.onSubmit,
  });

  final CatProfile? existingCat;
  final Set<String> existingCatNames;
  final bool isEn;
  final Future<bool> Function(CatProfile cat) onSubmit;

  @override
  State<_CatFormPage> createState() => _CatFormPageState();
}

class _CatFormPageState extends State<_CatFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _breedCtrl;
  late final TextEditingController _weightCtrl;

  late String _ageLabel;
  late CatGender _gender;
  late bool _neutered;
  late CatHealthBadge _healthBadge;
  late String _selectedAvatar;
  String? _uploadedAvatar;
  bool _saving = false;

  bool get _isEdit => widget.existingCat != null;

  List<String> get _avatarChoices {
    final cat = widget.existingCat;
    final base = (cat != null && cat.photos.isNotEmpty)
        ? cat.photos.map((p) => p.imageSource).toList()
        : _defaultCatAvatars;
    return [
      if (_uploadedAvatar != null && !base.contains(_uploadedAvatar))
        _uploadedAvatar!,
      ...base,
    ];
  }

  List<String> get _effectiveAgeOptions => _ageOptions.contains(_ageLabel)
      ? _ageOptions
      : [_ageLabel, ..._ageOptions];

  @override
  void initState() {
    super.initState();
    final cat = widget.existingCat;
    _nameCtrl = TextEditingController(text: cat?.name ?? '');
    _breedCtrl = TextEditingController(text: cat?.breed ?? '');
    _weightCtrl = TextEditingController(
      text: cat != null ? cat.weightText : '3.5',
    );
    _ageLabel = cat?.ageLabel ?? '1 ปี';
    _gender = cat?.gender ?? CatGender.female;
    _neutered = cat?.neutered ?? true;
    _healthBadge = cat?.healthBadge ?? CatHealthBadge.good;
    _selectedAvatar = cat?.avatarSource ?? _defaultCatAvatars.first;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _breedCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatarFromGallery() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null || !mounted) return;
      final cleanBytes = await stripImageMetadata(await picked.readAsBytes());
      final file = File(
        '${Directory.systemTemp.path}/cat_avatar_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(cleanBytes, flush: true);
      if (!mounted) return;
      final source = 'file:${file.path}';
      setState(() {
        _uploadedAvatar = source;
        _selectedAvatar = source;
      });
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่สามารถเปิดคลังรูปภาพได้ในขณะนี้')),
      );
    }
  }

  List<String> get _kittenAgeOptions => _effectiveAgeOptions.take(4).toList();
  List<String> get _adultAgeOptions => _effectiveAgeOptions.skip(4).toList();

  Future<void> _pickAge() async {
    FocusScope.of(context).unfocus();
    final isEn = widget.isEn;
    final picked = await showMyCatSheet<String>(
      context,
      builder: (ctx) => MyCatSheetFrame(
        title: isEn ? 'Select cat age' : 'เลือกอายุแมว',
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEn ? 'Kitten' : 'ลูกแมว',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 8),
              _AgeChipGroup(
                options: _kittenAgeOptions,
                selected: _ageLabel,
                isEn: isEn,
                onSelect: (v) => Navigator.of(ctx).pop(v),
              ),
              const SizedBox(height: 14),
              Text(
                isEn ? 'Adult' : 'โตเต็มวัย',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 8),
              _AgeChipGroup(
                options: _adultAgeOptions,
                selected: _ageLabel,
                isEn: isEn,
                onSelect: (v) => Navigator.of(ctx).pop(v),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null && mounted) {
      setState(() => _ageLabel = picked);
    }
  }

  Future<void> _submit() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final weight = double.parse(_weightCtrl.text.trim());
    final cat = widget.existingCat;
    final breed = _breedCtrl.text.trim().isEmpty
        ? 'ไทยผสม'
        : _breedCtrl.text.trim();
    final payload = cat != null
        ? cat.copyWith(
            name: _nameCtrl.text.trim(),
            breed: breed,
            ageLabel: _ageLabel,
            weightKg: weight,
            gender: _gender,
            neutered: _neutered,
            healthBadge: _healthBadge,
            avatarSource: _selectedAvatar,
          )
        : CatProfile(
            id: '',
            publicId: '',
            name: _nameCtrl.text.trim(),
            breed: breed,
            gender: _gender,
            neutered: _neutered,
            ageLabel: _ageLabel,
            weightKg: weight,
            recordCount: 0,
            adoptedYear: DateTime.now().year,
            avatarSource: _selectedAvatar,
            avatarBg: 0xFFFFF1E6,
            healthBadge: _healthBadge,
            trackerStatus: CatTrackerStatus.noCollar,
            trackerLabel: 'ยังไม่มีปลอกคอ',
            photos: [
              CatPhotoItem(
                id: 'new-p1',
                imageSource: _selectedAvatar,
                caption:
                    'ยินดีต้อนรับ ${_nameCtrl.text.trim()} เข้าสู่บ้านแมว.live',
                relativeTime: 'เมื่อสักครู่',
              ),
            ],
            careTasks: const [],
            healthReminderTitle: '',
            healthReminderSubtitle: '',
            healthHighlights: const [],
            caregivers: const [],
          );

    final ok = await widget.onSubmit(payload);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final choices = _avatarChoices;
    final isEn = widget.isEn;
    return Scaffold(
      backgroundColor: AppColors.card,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        leading: Semantics(
          button: true,
          label: isEn ? 'Close' : 'ปิด',
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(LucideIcons.x, size: 20),
          ),
        ),
        title: Text(
          _isEdit
              ? (isEn ? 'Edit cat profile' : 'แก้ไขโปรไฟล์แมว')
              : (isEn ? 'Add new cat' : 'เพิ่มแมวใหม่'),
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        centerTitle: true,
        actions: _isEdit
            ? [
                TextButton(
                  onPressed: _saving ? null : _submit,
                  child: Text(
                    isEn ? 'Save' : 'บันทึก',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _saving ? AppColors.muted : AppColors.ink,
                    ),
                  ),
                ),
              ]
            : null,
      ),
      body: SafeArea(
        top: false,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isEdit
                        ? (isEn
                              ? 'Profile photo (upload new or pick from ${MyCatL10n.catName(widget.existingCat!.name, true)}\'s photos)'
                              : 'รูปโปรไฟล์ (อัปโหลดใหม่หรือเลือกจากรูปของ${widget.existingCat!.name})')
                        : (isEn
                              ? 'Cat profile photo (upload or pick a sample)'
                              : 'รูปโปรไฟล์แมว (อัปโหลดรูปหรือเลือกรูปตัวอย่าง)'),
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 64,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: choices.length + 1,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (_, index) {
                        if (index == 0) {
                          return Semantics(
                            button: true,
                            label: isEn ? 'Upload cat photo' : 'อัปโหลดรูปแมว',
                            child: InkWell(
                              onTap: _pickAvatarFromGallery,
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                width: 62,
                                height: 62,
                                decoration: BoxDecoration(
                                  color: AppColors.page,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: AppColors.btnBorder,
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      LucideIcons.camera,
                                      size: 18,
                                      color: AppColors.ink,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isEn ? 'Upload' : 'อัปโหลด',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                        final src = choices[index - 1];
                        final selected = src == _selectedAvatar;
                        return Semantics(
                          button: true,
                          selected: selected,
                          label: isEn
                              ? 'Use as profile photo'
                              : 'ใช้รูปนี้เป็นรูปโปรไฟล์',
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedAvatar = src),
                            child: Container(
                              width: 62,
                              height: 62,
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: selected
                                      ? AppColors.btnBorder
                                      : AppColors.line,
                                  width: selected ? 2.5 : 1,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: AppImage(source: src, cacheWidth: 160),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  _LabeledField(
                    label: isEn ? 'Cat name *' : 'ชื่อแมว *',
                    controller: _nameCtrl,
                    hint: isEn
                        ? 'e.g. Mali, Tua Khiew'
                        : 'เช่น มะลิ, ถั่วเขียว',
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      final text = v?.trim() ?? '';
                      if (text.isEmpty) {
                        return isEn
                            ? 'Please enter cat name'
                            : 'กรุณาระบุชื่อแมว';
                      }
                      if (text.length > 30) {
                        return isEn
                            ? 'Cat name up to 30 characters'
                            : 'ชื่อแมวยาวได้ไม่เกิน 30 ตัวอักษร';
                      }
                      if (widget.existingCatNames.contains(
                        text.toLowerCase(),
                      )) {
                        return isEn
                            ? 'A cat named "$text" already exists'
                            : 'มีแมวชื่อ "$text" อยู่ในบัญชีแล้ว';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _LabeledField(
                    label: isEn ? 'Breed' : 'สายพันธุ์',
                    controller: _breedCtrl,
                    hint: isEn
                        ? 'e.g. Siamese, Thai orange'
                        : 'เช่น วิเชียรมาศ, ไทยสีส้ม',
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      final text = v?.trim() ?? '';
                      if (text.length > 30) {
                        return isEn
                            ? 'Breed up to 30 characters'
                            : 'สายพันธุ์ยาวได้ไม่เกิน 30 ตัวอักษร';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEn ? 'Age' : 'อายุ',
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Semantics(
                              button: true,
                              label: isEn
                                  ? 'Select cat age, current ${MyCatL10n.age(_ageLabel, true)}'
                                  : 'เลือกอายุแมว ปัจจุบัน $_ageLabel',
                              child: InkWell(
                                onTap: _pickAge,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  height: 48,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.page,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.line2),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          MyCatL10n.age(_ageLabel, isEn),
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            color: AppColors.text,
                                          ),
                                        ),
                                      ),
                                      const Icon(
                                        LucideIcons.chevronDown,
                                        size: 16,
                                        color: AppColors.muted,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _LabeledField(
                          label: isEn ? 'Weight (kg) *' : 'น้ำหนัก (กก.) *',
                          controller: _weightCtrl,
                          hint: isEn ? 'e.g. 4.1' : 'เช่น 4.1',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}'),
                            ),
                          ],
                          validator: (v) {
                            final raw = v?.trim() ?? '';
                            if (raw.isEmpty) {
                              return isEn
                                  ? 'Please enter weight'
                                  : 'กรุณาระบุน้ำหนัก';
                            }
                            final numVal = double.tryParse(raw);
                            if (numVal == null || numVal < 0.1 || numVal > 25) {
                              return isEn
                                  ? 'Enter 0.1–25 kg'
                                  : 'ระบุ 0.1–25 กก.';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    isEn ? 'Gender' : 'เพศ',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SegmentedChoiceRow<CatGender>(
                    options: [
                      (
                        value: CatGender.female,
                        label: isEn ? 'Female' : 'เพศเมีย',
                      ),
                      (value: CatGender.male, label: isEn ? 'Male' : 'เพศผู้'),
                    ],
                    selected: _gender,
                    onChanged: (v) => setState(() => _gender = v),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    isEn ? 'Spayed / Neutered' : 'ทำหมัน',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SegmentedChoiceRow<bool>(
                    options: [
                      (
                        value: true,
                        label: isEn ? 'Spayed / Neutered' : 'ทำหมันแล้ว',
                      ),
                      (value: false, label: isEn ? 'Intact' : 'ยังไม่ทำหมัน'),
                    ],
                    selected: _neutered,
                    onChanged: (v) => setState(() => _neutered = v),
                  ),
                  if (_isEdit) ...[
                    const SizedBox(height: 14),
                    Text(
                      isEn ? 'Health status on Cat ID' : 'สุขภาพบนบัตร Cat ID',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SegmentedChoiceRow<CatHealthBadge>(
                      options: [
                        (
                          value: CatHealthBadge.good,
                          label: isEn ? 'Good' : 'ดี',
                        ),
                        (
                          value: CatHealthBadge.watch,
                          label: isEn ? 'Watch' : 'เฝ้าระวัง',
                        ),
                        (
                          value: CatHealthBadge.poor,
                          label: isEn ? 'Poor' : 'ไม่ดี',
                        ),
                      ],
                      selected: _healthBadge,
                      onChanged: (v) => setState(() => _healthBadge = v),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isEn
                          ? 'Suggested from health book: ${switch (widget.existingCat!.healthBadge) {
                              CatHealthBadge.good => 'Good',
                              CatHealthBadge.watch => 'Watch',
                              CatHealthBadge.poor => 'Poor',
                            }}'
                          : 'แนะนำจากสมุดสุขภาพ: ${widget.existingCat!.healthBadge.label}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isEn
                          ? 'Cat ID ${widget.existingCat!.publicId} cannot be changed · edit health details in Health book'
                          : 'Cat ID ${widget.existingCat!.publicId} เปลี่ยนไม่ได้ · ข้อมูลสุขภาพแก้ได้ที่สมุดสุขภาพ',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 22),
                    FilledButton(
                      onPressed: _saving ? null : _submit,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        backgroundColor: AppColors.btn,
                        foregroundColor: AppColors.ink,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(
                            color: AppColors.btnBorder,
                            width: 1.5,
                          ),
                        ),
                      ),
                      child: Text(
                        isEn ? 'Create cat profile' : 'สร้างโปรไฟล์แมว',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AgeChipGroup extends StatelessWidget {
  const _AgeChipGroup({
    required this.options,
    required this.selected,
    required this.onSelect,
    this.isEn = false,
  });

  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;
  final bool isEn;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final opt in options)
          ChoiceChip(
            label: Text(MyCatL10n.age(opt, isEn)),
            selected: opt == selected,
            showCheckmark: false,
            selectedColor: AppColors.btn,
            backgroundColor: AppColors.page,
            side: BorderSide(
              color: opt == selected ? AppColors.btnBorder : AppColors.line2,
              width: opt == selected ? 1.5 : 1,
            ),
            labelStyle: TextStyle(
              fontSize: 13.5,
              fontWeight: opt == selected ? FontWeight.w700 : FontWeight.w500,
              color: opt == selected ? AppColors.ink : AppColors.text,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (_) => onSelect(opt),
          ),
      ],
    );
  }
}

InputDecoration _fieldDecoration({String? hint}) => InputDecoration(
  hintText: hint,
  filled: true,
  fillColor: AppColors.page,
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: AppColors.line2),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: AppColors.line2),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: AppColors.btnBorder, width: 1.5),
  ),
);

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    required this.hint,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          inputFormatters: inputFormatters,
          autocorrect: false,
          enableSuggestions: false,
          smartDashesType: SmartDashesType.disabled,
          smartQuotesType: SmartQuotesType.disabled,
          decoration: _fieldDecoration(hint: hint),
        ),
      ],
    );
  }
}

/// ชีตแชร์โปรไฟล์ — การ์ดรูปใหญ่ 4:3 + 4 วงกลมแชร์โซเชียล + กล่องคัดลอกลิงก์ตรงตามเว็บ
Future<void> showShareProfileSheet(
  BuildContext context, {
  required String sheetTitle,
  required String primaryLine,
  required String secondaryLine,
  required String url,
  required String avatarSource,
  required int avatarBg,
  bool isEn = false,
  bool showPrivacyNote = true,
  required ValueChanged<String> onNotify,
  required VoidCallback onSendInApp,
}) {
  return showMyCatSheet<void>(
    context,
    builder: (ctx) => Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      sheetTitle,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: isEn ? 'Close' : 'ปิด',
                    child: InkWell(
                      onTap: () => Navigator.of(ctx).pop(),
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.soft,
                        ),
                        child: const Icon(
                          LucideIcons.x,
                          size: 18,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // การ์ดรูปโปรไฟล์ใหญ่ 4:3
              Container(
                decoration: BoxDecoration(
                  color: AppColors.page,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.line),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: 4 / 3,
                      child: AppImage(source: avatarSource),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            primaryLine,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            secondaryLine,
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: AppColors.text2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _SocialCircleButton(
                    label: 'LINE',
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.brandLine,
                    ),
                    icon: const LineLogoIcon(size: 32),
                    onTap: () async {
                      final encoded = Uri.encodeComponent(url);
                      await _tryLaunchUrl(
                        Uri.parse(
                          'https://social-plugins.line.me/lineit/share?url=$encoded',
                        ),
                        onFallback: () => copyLinkAndNotify(url, onNotify),
                      );
                    },
                  ),
                  _SocialCircleButton(
                    label: 'Facebook',
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.brandFacebook,
                    ),
                    icon: const FacebookLogoIcon(size: 28),
                    onTap: () async {
                      final encoded = Uri.encodeComponent(url);
                      await _tryLaunchUrl(
                        Uri.parse(
                          'https://www.facebook.com/sharer/sharer.php?u=$encoded',
                        ),
                        onFallback: () => copyLinkAndNotify(url, onNotify),
                      );
                    },
                  ),
                  _SocialCircleButton(
                    label: 'Instagram',
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: Alignment(-0.4, 2.1),
                        radius: 2.2,
                        colors: [
                          Color(0xFFFDF497),
                          Color(0xFFFD5949),
                          Color(0xFFD6249F),
                          Color(0xFF285AEB),
                        ],
                        stops: [0, 0.45, 0.6, 0.9],
                      ),
                    ),
                    icon: const InstagramLogoIcon(size: 26),
                    onTap: () => copyLinkAndNotify(
                      url,
                      onNotify,
                      message: isEn
                          ? 'Link copied · paste in Instagram'
                          : 'คัดลอกลิงก์แล้ว · วางใน Instagram ได้เลย',
                    ),
                  ),
                  _SocialCircleButton(
                    label: isEn ? 'Send in app' : 'ส่งในแอป',
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.btn,
                      border: Border.all(
                        color: AppColors.btnBorder,
                        width: 1.5,
                      ),
                    ),
                    icon: const Icon(
                      LucideIcons.send,
                      size: 22,
                      color: AppColors.ink,
                    ),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      onSendInApp();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _CopyUrlBar(
                url: url,
                isEn: isEn,
                onAfterCopy: () =>
                    onNotify(isEn ? 'Link copied' : 'คัดลอกลิงก์แล้ว'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => systemShareText(url, sheetTitle, onNotify),
                icon: const Icon(LucideIcons.share2, size: 18),
                label: Text(
                  isEn ? 'Share via another app' : 'แชร์ผ่านแอปอื่น',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: AppColors.card,
                  foregroundColor: AppColors.text,
                  side: const BorderSide(color: AppColors.line),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              if (showPrivacyNote) ...[
                const SizedBox(height: 10),
                Text(
                  isEn
                      ? 'People who open the link see the public profile · no real address or phone shown'
                      : 'คนที่เปิดลิงก์จะเห็นหน้าโปรไฟล์สาธารณะ · ไม่แสดงที่อยู่หรือเบอร์โทรจริง',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

class _SocialCircleButton extends StatelessWidget {
  const _SocialCircleButton({
    required this.label,
    required this.decoration,
    required this.icon,
    required this.onTap,
    this.circleSize = 56,
  });

  final String label;
  final BoxDecoration decoration;
  final Widget icon;
  final VoidCallback onTap;
  final double circleSize;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        label: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                Container(
                  width: circleSize,
                  height: circleSize,
                  decoration: decoration,
                  child: Center(child: icon),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.text,
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

class _CopyUrlBar extends StatefulWidget {
  const _CopyUrlBar({required this.url, required this.isEn, this.onAfterCopy});

  final String url;
  final bool isEn;
  final VoidCallback? onAfterCopy;

  @override
  State<_CopyUrlBar> createState() => _CopyUrlBarState();
}

class _CopyUrlBarState extends State<_CopyUrlBar> {
  bool _copied = false;
  Timer? _timer;

  @override
  void didUpdateWidget(covariant _CopyUrlBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _timer?.cancel();
      _copied = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _handleCopy() {
    Clipboard.setData(ClipboardData(text: widget.url)).ignore();
    _timer?.cancel();
    setState(() => _copied = true);
    widget.onAfterCopy?.call();
    _timer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line2),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.link2, size: 17, color: AppColors.muted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.url,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: AppColors.text2),
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            button: true,
            label: _copied
                ? (widget.isEn ? 'Copied' : 'คัดลอกแล้ว')
                : (widget.isEn ? 'Copy' : 'คัดลอก'),
            child: Material(
              color: AppColors.btn,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.btnBorder, width: 1.5),
              ),
              child: InkWell(
                onTap: _handleCopy,
                borderRadius: BorderRadius.circular(16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 92,
                    minHeight: 40,
                  ),
                  child: SizedBox(
                    height: 40,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _copied ? LucideIcons.check : LucideIcons.copy,
                            size: 16,
                            color: AppColors.ink,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _copied
                                ? (widget.isEn ? 'Copied' : 'คัดลอกแล้ว')
                                : (widget.isEn ? 'Copy' : 'คัดลอก'),
                            maxLines: 1,
                            softWrap: false,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ชีต "ชวนผู้ดูแลเพิ่ม" — เลือกสิทธิ์ 3 ระดับ + การ์ดตัวอย่างคำเชิญ + แชร์ 3 วงกลม + กล่องคัดลอกตรงตามเว็บ
Future<void> showInviteCaregiverSheet(
  BuildContext context, {
  required String ownerName,
  required CatProfile cat,
  bool isEn = false,
  required ValueChanged<String> onNotify,
  required VoidCallback onSendInApp,
}) {
  return showMyCatSheet<void>(
    context,
    builder: (ctx) => _InviteCaregiverBody(
      ownerName: ownerName,
      cat: cat,
      isEn: isEn,
      onNotify: onNotify,
      onSendInApp: () {
        Navigator.of(ctx).pop();
        onSendInApp();
      },
    ),
  );
}

class _InviteCaregiverBody extends StatefulWidget {
  const _InviteCaregiverBody({
    required this.ownerName,
    required this.cat,
    this.isEn = false,
    required this.onNotify,
    required this.onSendInApp,
  });

  final String ownerName;
  final CatProfile cat;
  final bool isEn;
  final ValueChanged<String> onNotify;
  final VoidCallback onSendInApp;

  @override
  State<_InviteCaregiverBody> createState() => _InviteCaregiverBodyState();
}

class _InviteCaregiverBodyState extends State<_InviteCaregiverBody> {
  CaregiverInviteRole _role = CaregiverInviteRole.caregiver;

  @override
  Widget build(BuildContext context) {
    final isEn = widget.isEn;
    final inviteUrl = AppConfig.caregiverInviteUrl(
      widget.cat.publicId,
      slug: _role.slug,
    );
    final displayOwner = MyCatL10n.ownerName(widget.ownerName, isEn);
    final displayCat = MyCatL10n.catName(widget.cat.name, isEn);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.88,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.line2,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isEn ? 'Invite a caregiver' : 'ชวนผู้ดูแลเพิ่ม',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: isEn ? 'Close' : 'ปิด',
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.soft,
                          ),
                          child: const Icon(
                            LucideIcons.x,
                            size: 18,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  isEn ? 'Access level' : 'ให้สิทธิ์แบบไหน',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text2,
                  ),
                ),
                const SizedBox(height: 8),
                for (final role in CaregiverInviteRole.values) ...[
                  Semantics(
                    button: true,
                    selected: _role == role,
                    label: isEn
                        ? '${role.enLabel} ${role.enDescription}'
                        : '${role.label} ${role.description}',
                    child: InkWell(
                      onTap: () => setState(() => _role = role),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _role == role
                              ? AppColors.btn.withValues(alpha: 0.6)
                              : AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _role == role
                                ? AppColors.btnBorder
                                : AppColors.line,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _role == role
                                    ? AppColors.ink
                                    : Colors.transparent,
                                border: Border.all(
                                  color: _role == role
                                      ? AppColors.ink
                                      : AppColors.line2,
                                  width: 2,
                                ),
                              ),
                              child: _role == role
                                  ? const Icon(
                                      LucideIcons.check,
                                      size: 12,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isEn ? role.enLabel : role.label,
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.text,
                                    ),
                                  ),
                                  Text(
                                    isEn
                                        ? role.enDescription
                                        : role.description,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  isEn
                      ? "Invite preview as they'll see it"
                      : 'ตัวอย่างคำเชิญที่อีกฝ่ายเห็น',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text2,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.page,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.btn,
                        ),
                        child: const Icon(
                          LucideIcons.userPlus,
                          size: 22,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isEn
                            ? '$displayOwner invited you as ${_role.enLabel.toLowerCase()} for “$displayCat” on แมว.live'
                            : '$displayOwner ชวนคุณมาเป็น${_role.label}ของ “$displayCat” ในแมว.live',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isEn ? _role.enDescription : _role.description,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.text2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.btn,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.btnBorder),
                        ),
                        child: Text(
                          isEn ? 'Accept invite' : 'รับคำเชิญ',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isEn
                            ? 'Link expires in 7 days · cancel any time'
                            : 'ลิงก์หมดอายุใน 7 วัน · ยกเลิกได้ทุกเมื่อ',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _SocialCircleButton(
                      label: 'LINE',
                      circleSize: 52,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.brandLine,
                      ),
                      icon: const LineLogoIcon(size: 30),
                      onTap: () async {
                        final encoded = Uri.encodeComponent(inviteUrl);
                        await _tryLaunchUrl(
                          Uri.parse(
                            'https://social-plugins.line.me/lineit/share?url=$encoded',
                          ),
                          onFallback: () =>
                              Clipboard.setData(ClipboardData(text: inviteUrl))
                                  .ignore(),
                        );
                      },
                    ),
                    _SocialCircleButton(
                      label: isEn ? 'Send in app' : 'ส่งในแอป',
                      circleSize: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.btn,
                        border: Border.all(
                          color: AppColors.btnBorder,
                          width: 1.5,
                        ),
                      ),
                      icon: const Icon(
                        LucideIcons.send,
                        size: 20,
                        color: AppColors.ink,
                      ),
                      onTap: widget.onSendInApp,
                    ),
                    _SocialCircleButton(
                      label: 'QR',
                      circleSize: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.card,
                        border: Border.all(color: AppColors.line2, width: 1.5),
                      ),
                      icon: const Icon(
                        LucideIcons.qrCode,
                        size: 20,
                        color: AppColors.text,
                      ),
                      onTap: () => widget.onNotify(
                        isEn
                            ? 'QR invites will be ready when caregiver backend launches'
                            : 'สร้าง QR คำเชิญได้เมื่อเชื่อมระบบผู้ดูแลจริง',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _CopyUrlBar(url: inviteUrl, isEn: isEn),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _tryLaunchUrl(Uri uri, {required VoidCallback onFallback}) async {
  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) onFallback();
  } on Exception {
    onFallback();
  }
}

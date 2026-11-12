import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/help_data.dart';
import 'help_l10n.dart';
import 'help_post_card.dart';

/// ขั้นที่ 1: ชีตเลือกประเภทประกาศ (+ สร้างประกาศ) -> ขั้นที่ 2: หน้าเต็มจอ -> Preview
Future<void> showCreateHelpPostFlow({
  required BuildContext context,
  required bool isEn,
  required Future<HelpPost?> Function(CreateHelpPostInput input) onSubmit,
  required ValueChanged<String> onToast,
}) async {
  final chosen = await showModalBottomSheet<HelpCategory>(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.sheetBarrier,
    builder: (sheetCtx) => Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(sheetCtx).viewPadding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 16),
          Text(
            HelpL10n.choosePostTypeTitle(isEn),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C1810),
            ),
          ),
          const SizedBox(height: 14),
          _TypeOptionTile(
            icon: LucideIcons.search,
            iconBg: const Color(0xFFFEE2E2),
            iconColor: const Color(0xFF991B1B),
            title: HelpL10n.categoryFullLabel(HelpCategory.lost, isEn),
            subtitle: HelpL10n.lostSub(isEn),
            onTap: () => Navigator.pop(sheetCtx, HelpCategory.lost),
          ),
          const SizedBox(height: 10),
          _TypeOptionTile(
            icon: LucideIcons.cat,
            iconBg: const Color(0xFFDCFCE7),
            iconColor: const Color(0xFF166534),
            title: HelpL10n.categoryFullLabel(HelpCategory.found, isEn),
            subtitle: HelpL10n.foundSub(isEn),
            onTap: () => Navigator.pop(sheetCtx, HelpCategory.found),
          ),
          const SizedBox(height: 10),
          _TypeOptionTile(
            icon: LucideIcons.heartHandshake,
            iconBg: const Color(0xFFFEF3C7),
            iconColor: const Color(0xFF92400E),
            title: HelpL10n.categoryFullLabel(HelpCategory.helpRequest, isEn),
            subtitle: HelpL10n.helpRequestSub(isEn),
            onTap: () => Navigator.pop(sheetCtx, HelpCategory.helpRequest),
          ),
        ],
      ),
    ),
  );

  if (chosen == null || !context.mounted) return;

  final input = await Navigator.of(context, rootNavigator: true)
      .push<CreateHelpPostInput>(
    MaterialPageRoute<CreateHelpPostInput>(
      fullscreenDialog: true,
      builder: (_) => _CreatePostFullScreenPage(
        category: chosen,
        isEn: isEn,
      ),
    ),
  );

  if (input == null || !context.mounted) return;

  final confirmed = await _showPostPreviewSheet(
    context: context,
    input: input,
    isEn: isEn,
  );
  if (confirmed != true || !context.mounted) return;

  final created = await onSubmit(input);
  if (created != null) {
    onToast(HelpL10n.postCreatedToast(isEn));
  }
}

class _TypeOptionTile extends StatelessWidget {
  const _TypeOptionTile({
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFCF9F6),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2C1810),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
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
    );
  }
}

class _MyCatPreset {
  const _MyCatPreset({
    required this.id,
    required this.nameTh,
    required this.nameEn,
    required this.avatar,
    required this.photo,
    required this.titleTh,
    required this.titleEn,
    required this.detailsTh,
    required this.detailsEn,
    required this.hasTag,
    this.tagLocationTh = '',
    this.tagLocationEn = '',
  });

  final String id;
  final String nameTh;
  final String nameEn;
  final String avatar;
  final String photo;
  final String titleTh;
  final String titleEn;
  final String detailsTh;
  final String detailsEn;
  final bool hasTag;
  final String tagLocationTh;
  final String tagLocationEn;
}

class _CreatePostFullScreenPage extends StatefulWidget {
  const _CreatePostFullScreenPage({
    required this.category,
    required this.isEn,
  });

  final HelpCategory category;
  final bool isEn;

  @override
  State<_CreatePostFullScreenPage> createState() =>
      _CreatePostFullScreenPageState();
}

class _CreatePostFullScreenPageState extends State<_CreatePostFullScreenPage> {
  static const _myCats = [
    _MyCatPreset(
      id: 'mali',
      nameTh: 'มะลิ',
      nameEn: 'Mali',
      avatar: 'assets/images/hero/mali.jpg',
      photo: 'assets/images/hero/mali.jpg',
      titleTh: 'ตามหา "มะลิ" วิเชียรมาศ',
      titleEn: 'Lost "Mali" Siamese cat',
      detailsTh: 'จุดสังเกต: ตาสีฟ้า ขนสีครีมแต้มน้ำตาลเข้ม',
      detailsEn: 'Marks: Blue eyes, cream coat with dark brown points',
      hasTag: true,
      tagLocationTh: 'แถวซ.อารีย์ 4 · รัศมีราว 500 ม.',
      tagLocationEn: 'Near Ari Soi 4 · ~500m radius',
    ),
    _MyCatPreset(
      id: 'somjeed',
      nameTh: 'ส้มจี๊ด',
      nameEn: 'Somjeed',
      avatar: 'assets/images/hero/somjeed.jpg',
      photo: 'assets/images/hero/somjeed.jpg',
      titleTh: 'ตามหา "ส้มจี๊ด" แมวส้ม',
      titleEn: 'Lost "Somjeed" ginger cat',
      detailsTh: 'จุดสังเกต: ขนส้มลายสลิด หางเป็นพวง',
      detailsEn: 'Marks: Ginger tabby coat, fluffy tail',
      hasTag: true,
      tagLocationTh: 'แถวอารีย์ ซอย 2 · รัศมีราว 300 ม.',
      tagLocationEn: 'Near Ari Soi 2 · ~300m radius',
    ),
    _MyCatPreset(
      id: 'thuadam',
      nameTh: 'ถั่วดำ',
      nameEn: 'Thuadam',
      avatar: 'assets/images/hero/thuadam.jpg',
      photo: 'assets/images/hero/thuadam.jpg',
      titleTh: 'ตามหา "ถั่วดำ" แมวดำล้วน',
      titleEn: 'Lost "Thuadam" black cat',
      detailsTh: 'จุดสังเกต: ขนดำเงา ตาสีเหลืองทอง',
      detailsEn: 'Marks: Glossy black coat, golden yellow eyes',
      hasTag: false,
    ),
  ];

  final ImagePicker _picker = ImagePicker();

  String? _selectedCatId;
  bool _selectedCatHasTag = false;
  bool _useTagLocation = true;
  String? _presetPhotoAsset;
  String? _pickedImagePath;
  bool _shareToFeed = true;
  bool _enableDonation = false;

  late final TextEditingController _titleCtrl;
  late final TextEditingController _catNameCtrl;
  late final TextEditingController _detailsCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _timeCtrl;
  late final TextEditingController _secretMarkCtrl;
  late final TextEditingController _targetBahtCtrl;
  late final TextEditingController _purposeCtrl;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final dd = now.day.toString().padLeft(2, '0');
    final mm = now.month.toString().padLeft(2, '0');
    final hh = now.hour.toString().padLeft(2, '0');
    final min = now.minute.toString().padLeft(2, '0');

    _titleCtrl = TextEditingController();
    _catNameCtrl = TextEditingController();
    _detailsCtrl = TextEditingController();
    _locationCtrl = TextEditingController(
      text: widget.isEn
          ? 'Near current location · Ari'
          : 'ใกล้ตำแหน่งปัจจุบัน · อารีย์',
    );
    _timeCtrl = TextEditingController(text: '$dd/$mm/${now.year} $hh:$min');
    _secretMarkCtrl = TextEditingController();
    _targetBahtCtrl = TextEditingController(text: '3000');
    _purposeCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _catNameCtrl.dispose();
    _detailsCtrl.dispose();
    _locationCtrl.dispose();
    _timeCtrl.dispose();
    _secretMarkCtrl.dispose();
    _targetBahtCtrl.dispose();
    _purposeCtrl.dispose();
    super.dispose();
  }

  bool get _hasPhoto => _pickedImagePath != null || _presetPhotoAsset != null;

  bool get _canPreview =>
      _titleCtrl.text.trim().isNotEmpty && _locationCtrl.text.trim().isNotEmpty;

  Future<void> _pickPhotoFromGallery() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (file == null || !mounted) return;
      setState(() {
        _pickedImagePath = file.path;
      });
    } catch (_) {
      // กรณี simulator ไม่มีสิทธิ์หรือยกเลิก ไม่ต้อง crash
    }
  }

  void _selectMyCat(_MyCatPreset cat) {
    final isEn = widget.isEn;
    setState(() {
      _selectedCatId = cat.id;
      _selectedCatHasTag = cat.hasTag;
      _useTagLocation = cat.hasTag;
      _pickedImagePath = null;
      _presetPhotoAsset = cat.photo;
      _titleCtrl.text = isEn ? cat.titleEn : cat.titleTh;
      _catNameCtrl.text = isEn ? cat.nameEn : cat.nameTh;
      _detailsCtrl.text = isEn ? cat.detailsEn : cat.detailsTh;
      _locationCtrl.text = cat.hasTag
          ? (isEn ? cat.tagLocationEn : cat.tagLocationTh)
          : (isEn
                ? 'Near current location · Ari'
                : 'ใกล้ตำแหน่งปัจจุบัน · อารีย์');
    });
  }

  void _selectOtherCat() {
    final isEn = widget.isEn;
    setState(() {
      _selectedCatId = 'other';
      _selectedCatHasTag = false;
      _useTagLocation = false;
      _pickedImagePath = null;
      _presetPhotoAsset = null;
      _titleCtrl.clear();
      _catNameCtrl.clear();
      _detailsCtrl.clear();
      _locationCtrl.text = isEn
          ? 'Near current location · Ari'
          : 'ใกล้ตำแหน่งปัจจุบัน · อารีย์';
    });
  }

  void _submitPreview() {
    if (!_canPreview) return;
    final target = int.tryParse(_targetBahtCtrl.text.trim()) ?? 0;
    Navigator.pop(
      context,
      CreateHelpPostInput(
        category: widget.category,
        title: _titleCtrl.text.trim(),
        catName: _catNameCtrl.text.trim(),
        summary: _detailsCtrl.text.trim().isNotEmpty
            ? _detailsCtrl.text.trim()
            : _titleCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        timeLabel: widget.category == HelpCategory.lost
            ? _timeCtrl.text.trim()
            : null,
        secretMark: _secretMarkCtrl.text.trim(),
        imageAsset: _presetPhotoAsset ?? 'assets/images/help/mochi.jpg',
        imageFilePath: _pickedImagePath,
        allowsChatClues: true,
        shareToFeed: _shareToFeed,
        enableDonation:
            widget.category == HelpCategory.helpRequest && _enableDonation,
        targetBaht: target,
        donationPurpose: _purposeCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEn = widget.isEn;
    final isLost = widget.category == HelpCategory.lost;
    final isFound = widget.category == HelpCategory.found;
    final isHelpReq = widget.category == HelpCategory.helpRequest;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(LucideIcons.x, size: 22, color: Color(0xFF2C1810)),
        ),
        centerTitle: true,
        title: Text(
          HelpL10n.createFormTitle(widget.category, isEn),
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2C1810),
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.line),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isLost) ...[
                    Text(
                      HelpL10n.whichMyCatLost(isEn),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2C1810),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final cat in _myCats) ...[
                            _CatCirclePicker(
                              label: isEn ? cat.nameEn : cat.nameTh,
                              avatarAsset: cat.avatar,
                              selected: _selectedCatId == cat.id,
                              onTap: () => _selectMyCat(cat),
                            ),
                            const SizedBox(width: 14),
                          ],
                          _CatCirclePicker(
                            label: HelpL10n.otherCat(isEn),
                            avatarAsset: null,
                            selected: _selectedCatId == 'other',
                            onTap: _selectOtherCat,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                  Text(
                    HelpL10n.catPhotoLabel(isEn),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2C1810),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // กล่องเลือกรูปจากเครื่องจริง (Gallery) — แสดงเต็มสัดส่วน 4:3 ชัดเจน
                  InkWell(
                    onTap: _pickPhotoFromGallery,
                    borderRadius: BorderRadius.circular(18),
                    child: _hasPhoto
                        ? AspectRatio(
                            aspectRatio: 4 / 3,
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5EFE8),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: const Color(0xFF7A3224),
                                  width: 1.5,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    if (_pickedImagePath != null)
                                      Image.file(
                                        File(_pickedImagePath!),
                                        fit: BoxFit.cover,
                                      )
                                    else
                                      Image.asset(
                                        _presetPhotoAsset!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => Image.asset(
                                          'assets/images/help/mochi.jpg',
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    Positioned(
                                      right: 10,
                                      bottom: 10,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.card,
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.12,
                                              ),
                                              blurRadius: 6,
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              LucideIcons.imagePlus,
                                              size: 14,
                                              color: Color(0xFF3D2314),
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              isEn
                                                  ? 'Change photo'
                                                  : 'เปลี่ยนรูป',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF3D2314),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : Container(
                            width: double.infinity,
                            height: 156,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5EFE8),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: AppColors.line2,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  LucideIcons.imagePlus,
                                  size: 32,
                                  color: AppColors.muted,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  HelpL10n.pickFromGallery(isEn),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF3D2314),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  HelpL10n.pickPhotoHint(isEn),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                  if (isFound) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.sparkles,
                          size: 14,
                          color: Color(0xFF5E4636),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            isEn
                                ? 'AI will automatically match with lost cat posts near you'
                                : 'AI จะเทียบรูปกับประกาศแมวหายใกล้คุณให้อัตโนมัติ',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  _StackedFieldInput(
                    controller: _titleCtrl,
                    label: switch (widget.category) {
                      HelpCategory.lost =>
                        isEn ? 'Cat name & appearance' : 'ชื่อแมวและลักษณะ',
                      HelpCategory.found =>
                        isEn ? 'Appearance of found cat' : 'ลักษณะแมวที่พบ',
                      HelpCategory.helpRequest =>
                        isEn ? 'What happened' : 'เกิดอะไรขึ้น',
                      _ => HelpL10n.titleAndTraitsLabel(isEn),
                    },
                    hintText: switch (widget.category) {
                      HelpCategory.lost =>
                        isEn
                            ? 'e.g. "Khao Tang" ginger cat, red collar'
                            : 'เช่น "ข้าวตัง" แมวส้ม ปลอกคอสีแดง',
                      HelpCategory.found =>
                        isEn
                            ? 'e.g. Grey-white cat, tame, wearing collar'
                            : 'เช่น แมวขาวเทา เชื่อง มีปลอกคอ',
                      HelpCategory.helpRequest =>
                        isEn
                            ? 'e.g. Kitten stuck under car, needs help'
                            : 'เช่น ลูกแมวติดอยู่ใต้รถ ต้องการคนช่วย',
                      _ => '',
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 14),
                  _StackedFieldInput(
                    controller: _catNameCtrl,
                    label: isEn ? 'Cat name' : 'ชื่อแมว',
                    labelNote: isEn
                        ? ' (optional · shown on post & helper list)'
                        : ' (ถ้ามี · แสดงบนประกาศและรายชื่อผู้ช่วย)',
                    hintText: isEn ? 'e.g. Mommaem' : 'เช่น มอมแมม',
                  ),
                  const SizedBox(height: 14),
                  _StackedFieldInput(
                    controller: _detailsCtrl,
                    label: HelpL10n.detailsLabel(isEn),
                    hintText: isEn
                        ? 'Personality, landmarks, contact (optional)'
                        : 'นิสัย จุดสังเกต เบอร์ติดต่อ (ไม่บังคับ)',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    switch (widget.category) {
                      HelpCategory.lost =>
                        isEn ? 'Lost location' : 'บริเวณที่หาย',
                      HelpCategory.found =>
                        isEn ? 'Found location' : 'บริเวณที่พบ',
                      HelpCategory.helpRequest =>
                        isEn ? 'Incident location' : 'บริเวณที่เกิดเหตุ',
                      _ => isEn ? 'Location' : 'บริเวณ',
                    },
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2C1810),
                    ),
                  ),
                  if (isLost && _selectedCatHasTag) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _TagModeChip(
                          label: isEn
                              ? 'Latest location from Tag'
                              : 'ตำแหน่งล่าสุดจาก Tag',
                          selected: _useTagLocation,
                          onTap: () {
                            final cat = _myCats.firstWhere(
                              (c) => c.id == _selectedCatId,
                            );
                            setState(() {
                              _useTagLocation = true;
                              _locationCtrl.text = isEn
                                  ? cat.tagLocationEn
                                  : cat.tagLocationTh;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _TagModeChip(
                          label: isEn ? 'Enter manually' : 'กรอกเอง',
                          selected: !_useTagLocation,
                          onTap: () {
                            setState(() {
                              _useTagLocation = false;
                              _locationCtrl.text = isEn
                                  ? 'Near current location · Ari'
                                  : 'ใกล้ตำแหน่งปัจจุบัน · อารีย์';
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  _StackedFieldInput(
                    controller: _locationCtrl,
                    label: '',
                    showLabel: false,
                    prefixIcon: const Icon(
                      LucideIcons.mapPin,
                      size: 16,
                      color: AppColors.muted,
                    ),
                    helperText: isLost
                        ? (_selectedCatHasTag && _useTagLocation
                              ? (isEn
                                    ? 'Post shows area only. Exact Tag GPS is shared only with verified contacts.'
                                    : 'โพสต์แสดงแค่ย่าน · พิกัดจริงจาก Tag ส่งให้เฉพาะคนที่ติดต่อและยืนยันตัวได้ทางแชต')
                              : (isEn
                                    ? 'Only neighborhood is shown. Exact address is shared in private chat.'
                                    : 'โพสต์แสดงแค่ย่าน ที่อยู่จริงคุยกันในแชตส่วนตัว'))
                        : (isEn
                              ? 'Approximate location shown for safety'
                              : 'แสดงตำแหน่งแบบประมาณเพื่อความปลอดภัย'),
                    onChanged: (_) => setState(() {}),
                  ),
                  if (isLost) ...[
                    const SizedBox(height: 14),
                    _StackedFieldInput(
                      controller: _timeCtrl,
                      label: isEn ? 'Lost time' : 'หายเมื่อ',
                      suffixIcon: const Icon(
                        LucideIcons.calendar,
                        size: 16,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _StackedFieldInput(
                      controller: _secretMarkCtrl,
                      label: isEn ? 'Secret mark' : 'จุดสังเกตลับ',
                      labelPrefixIcon: const Icon(
                        LucideIcons.lock,
                        size: 14,
                        color: Color(0xFF2C1810),
                      ),
                      labelNote: isEn
                          ? ' (not shown in post)'
                          : ' (ไม่แสดงในโพสต์)',
                      hintText: isEn
                          ? 'e.g. Black mole on belly, kinked tail tip'
                          : 'เช่น ปานดำใต้ท้อง หางงอปลาย',
                      helperText: isEn
                          ? 'Ask finders to verify they actually found your cat'
                          : 'ใช้ถามคนที่บอกว่าเจอน้อง เพื่อยืนยันว่าเจอจริง',
                    ),
                    const SizedBox(height: 14),
                    // การ์ด "เพิ่มลงฟีด / ให้ทั้งแอปช่วยแชร์" ตรงเว็บจริง
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDE6DF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              LucideIcons.megaphone,
                              size: 18,
                              color: Color(0xFF991B1B),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEn ? 'Add to Feed' : 'เพิ่มลงฟีด',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2C1810),
                                  ),
                                ),
                                Text(
                                  isEn
                                      ? 'Let the whole community help share'
                                      : 'ให้ทั้งแอปช่วยแชร์',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: _shareToFeed,
                            activeTrackColor: const Color(0xFF7A3224),
                            onChanged: (v) => setState(() => _shareToFeed = v),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (isHelpReq) ...[
                    const SizedBox(height: 16),
                    // การ์ดเปิดรับบริจาคสีเหลืองครีมอ่อนตรงเว็บจริง (รวมช่องกรอกไว้ในกล่องเดียวกัน)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF9E7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF5E6B3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () => setState(
                              () => _enableDonation = !_enableDonation,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        HelpL10n.enableDonationLabel(isEn),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF2C1810),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isEn
                                            ? 'Set a target and close once reached'
                                            : 'ตั้งเป้าหมาย แล้วปิดรับได้เมื่อครบ',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Checkbox(
                                  value: _enableDonation,
                                  activeColor: const Color(0xFFD99B1C),
                                  side: const BorderSide(
                                    color: Color(0xFFD99B1C),
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  onChanged: (v) => setState(
                                    () => _enableDonation = v ?? false,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_enableDonation) ...[
                            const SizedBox(height: 10),
                            TextField(
                              controller: _targetBahtCtrl,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.text,
                              ),
                              decoration: InputDecoration(
                                prefixText: '${HelpL10n.targetBahtLabel(isEn)}  ',
                                prefixStyle: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.muted,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFF0DFB0),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFF0DFB0),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _purposeCtrl,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.text,
                              ),
                              decoration: InputDecoration(
                                hintText: HelpL10n.donationPurposeLabel(isEn),
                                hintStyle: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.muted,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFF0DFB0),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFF0DFB0),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _canPreview ? _submitPreview : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.btn,
                    disabledBackgroundColor: const Color(0xFFFAF5F0),
                    foregroundColor: const Color(0xFF3D2314),
                    disabledForegroundColor: const Color(0xFFB5A598),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: _canPreview
                            ? AppColors.btnBorder
                            : const Color(0xFFEEE4DA),
                      ),
                    ),
                  ),
                  child: Text(
                    HelpL10n.previewBeforePost(isEn),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
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

class _TagModeChip extends StatelessWidget {
  const _TagModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFDE6DF) : AppColors.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? const Color(0xFFF3C7BA) : AppColors.line2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? const Color(0xFF7A3224) : AppColors.text,
          ),
        ),
      ),
    );
  }
}

class _CatCirclePicker extends StatelessWidget {
  const _CatCirclePicker({
    required this.label,
    required this.avatarAsset,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String? avatarAsset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? const Color(0xFF7A3224) : AppColors.line2,
                width: selected ? 2.5 : 1.5,
              ),
            ),
            child: avatarAsset != null
                ? CircleAvatar(backgroundImage: AssetImage(avatarAsset!))
                : const CircleAvatar(
                    backgroundColor: AppColors.soft,
                    child: Icon(
                      LucideIcons.plus,
                      size: 20,
                      color: Color(0xFF3D2314),
                    ),
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? const Color(0xFF7A3224) : AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

Future<bool?> _showPostPreviewSheet({
  required BuildContext context,
  required CreateHelpPostInput input,
  required bool isEn,
}) {
  final previewTitle =
      (input.catName != null && input.catName!.trim().isNotEmpty)
          ? '${input.catName!.trim()} · ${input.title}'
          : input.title;
  final previewPost = HelpPost(
    id: 'preview',
    titleTh: previewTitle,
    titleEn: previewTitle,
    category: input.category,
    imageAsset: input.imageAsset,
    imageFilePath: input.imageFilePath,
    locationTh: input.location,
    locationEn: input.location,
    distanceKm: 0.3,
    timeAgoTh: input.timeLabel ?? 'เมื่อสักครู่',
    timeAgoEn: input.timeLabel ?? 'Just now',
    summaryTh: input.summary,
    summaryEn: input.summary,
    detailTraitsTh: input.summary,
    detailTraitsEn: input.summary,
    secretMarkTh: input.secretMark,
    secretMarkEn: input.secretMark,
    contactInfoTh: HelpL10n.allowChatCluesLabel(false),
    contactInfoEn: HelpL10n.allowChatCluesLabel(true),
    donation: input.enableDonation && input.targetBaht > 0
        ? DonationInfo(
            raisedBaht: 0,
            targetBaht: input.targetBaht,
            purposeTh: input.donationPurpose?.isNotEmpty == true
                ? input.donationPurpose!
                : 'ค่ารักษาและดูแลแมว',
            purposeEn: input.donationPurpose?.isNotEmpty == true
                ? input.donationPurpose!
                : 'Treatment and cat care',
          )
        : null,
  );

  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.sheetBarrier,
    builder: (sheetCtx) => Container(
      decoration: const BoxDecoration(
        color: AppColors.page,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(sheetCtx).viewPadding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 14),
          Text(
            HelpL10n.previewTitle(isEn),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C1810),
            ),
          ),
          const SizedBox(height: 12),
          HelpPostCard(
            post: previewPost,
            isExpanded: false,
            isEn: isEn,
            onToggleExpand: () {},
            onSendClue: () {},
            onPrimaryAction: () {},
            onShare: () {},
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(sheetCtx, true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF3D2314),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                HelpL10n.confirmAndPost(isEn),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _StackedFieldInput extends StatelessWidget {
  const _StackedFieldInput({
    required this.controller,
    required this.label,
    this.showLabel = true,
    this.labelPrefixIcon,
    this.labelNote,
    this.hintText,
    this.helperText,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final bool showLabel;
  final Widget? labelPrefixIcon;
  final String? labelNote;
  final String? hintText;
  final String? helperText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel && label.isNotEmpty) ...[
          Row(
            children: [
              if (labelPrefixIcon != null) ...[
                labelPrefixIcon!,
                const SizedBox(width: 5),
              ],
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2C1810),
                    ),
                    children: [
                      if (labelNote != null)
                        TextSpan(
                          text: labelNote,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppColors.muted,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        TextField(
          controller: controller,
          maxLines: maxLines,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 14, color: AppColors.text),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(fontSize: 13, color: AppColors.muted),
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: const Color(0xFFFFFBF5),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFEBE0D6)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFEBE0D6)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF3D2314),
                width: 1.5,
              ),
            ),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 5),
          Text(
            helperText!,
            style: const TextStyle(fontSize: 11, color: AppColors.muted),
          ),
        ],
      ],
    );
  }
}
